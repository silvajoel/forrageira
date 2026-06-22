import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:forrageira/services/species_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:forrageira/widgets/app_smart_image.dart';
import 'package:forrageira/widgets/image_viewer_dialog.dart';

class AdminRequestAnalysisDialog extends StatefulWidget {
  final String requestId;

  const AdminRequestAnalysisDialog({
    super.key,
    required this.requestId,
  });

  @override
  State<AdminRequestAnalysisDialog> createState() =>
      _AdminRequestAnalysisDialogState();
}

class _AdminRequestAnalysisDialogState
    extends State<AdminRequestAnalysisDialog> {
  final TextEditingController _careInstructionsCtrl = TextEditingController();
  final TextEditingController _obsManuseioCtrl = TextEditingController();
  final TextEditingController _newSpeciesNameCtrl = TextEditingController();
  final TextEditingController _newSpeciesNotesCtrl = TextEditingController();
  static const String _reopenAllowedAdminEmail = 'suporte9@innomax.com.br';

  final _auth = FirebaseAuth.instance;
  final _forage = ForageService();
  final _species = SpeciesService();
  final _users = UserService();

  bool _saving = false;
  bool _creatingSpecies = false;
  int _mainImageIndex = 0;
  bool _allImagesFailed = false;

  AnalysisRequest? _request;
  String _userName = '-';
  List<Map<String, dynamic>> _speciesList = [];
  String? _selectedSpeciesId;
  List<String> _resolvedImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _careInstructionsCtrl.dispose();
    _obsManuseioCtrl.dispose();
    _newSpeciesNameCtrl.dispose();
    _newSpeciesNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final request = await _forage.getById(widget.requestId);

      String userName = request.userId;
      try {
        final users = await _users.fetchUsers();
        final u = users.firstWhere(
          (e) => e['id'] == request.userId,
          orElse: () => const {},
        );
        final n = (u['name'] ?? '').toString().trim();
        if (n.isNotEmpty) userName = n;
      } catch (_) {}

      final species = await _species.fetchSpecies();

      if (!mounted) return;

      setState(() {
        _request = request;
        _userName = userName;
        _speciesList = species;

        final existingCare = (request.careInstructions ?? '').trim();
        if (existingCare.isNotEmpty) {
          _careInstructionsCtrl.text = existingCare;
        }
        final existingObs = (request.adminNotes ?? '').trim();
        if (existingObs.isNotEmpty) {
          _obsManuseioCtrl.text = existingObs;
        }

        // Pre-seleciona pela especie ja registrada (por nome) se finalizada.
        _selectedSpeciesId = _matchSpeciesIdByName(request.speciesName);
        if (_selectedSpeciesId == null && species.isNotEmpty && !_isCompleted) {
          _selectedSpeciesId = (species.first['id'] ?? '').toString();
        }

        _resolvedImageUrls = List<String>.from(request.imageUrls);
        _allImagesFailed = false;
      });

      if (!_isCompleted && _selectedSpeciesId != null) {
        final sp = _findSpecies(_selectedSpeciesId!);
        if (sp != null && _careInstructionsCtrl.text.trim().isEmpty) {
          final care = _speciesDescription(sp);
          if (care.isNotEmpty) _careInstructionsCtrl.text = care;
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar análise: $e')),
      );
    }
  }

  String? _matchSpeciesIdByName(String? speciesName) {
    final name = (speciesName ?? '').trim().toLowerCase();
    if (name.isEmpty) return null;
    final match = _speciesList.firstWhere(
      (s) => (s['name'] ?? '').toString().trim().toLowerCase() == name,
      orElse: () => const {},
    );
    final id = (match['id'] ?? '').toString();
    return id.isEmpty ? null : id;
  }

  bool get _isCompleted {
    final status = (_request?.status ?? '').trim().toLowerCase();
    return status == 'completed' || status == 'finalizado';
  }

  bool get _canCurrentAdminReopen {
    final email = (_auth.currentUser?.email ?? '').trim().toLowerCase();
    return _isCompleted && email == _reopenAllowedAdminEmail;
  }

  String _fmtDateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }

  String _speciesName(Map<String, dynamic> data, String fallback) {
    return (data['name'] ?? fallback).toString();
  }

  String _speciesDescription(Map<String, dynamic> data) {
    return (data['description'] ?? '').toString().trim();
  }

  Map<String, dynamic>? _findSpecies(String id) {
    for (final s in _speciesList) {
      if ((s['id'] ?? '').toString() == id) return s;
    }
    return null;
  }

  Future<void> _refreshSpecies({String? selectName}) async {
    final list = await _species.fetchSpecies();
    if (!mounted) return;
    setState(() {
      _speciesList = list;
      if (selectName != null) {
        _selectedSpeciesId = _matchSpeciesIdByName(selectName);
      } else if (_selectedSpeciesId != null &&
          !_speciesList.any((s) => (s['id'] ?? '') == _selectedSpeciesId)) {
        _selectedSpeciesId = null;
      }
    });
    if (selectName != null && _selectedSpeciesId != null && !_isCompleted) {
      final sp = _findSpecies(_selectedSpeciesId!);
      if (sp != null && _careInstructionsCtrl.text.trim().isEmpty) {
        final care = _speciesDescription(sp);
        if (care.isNotEmpty) _careInstructionsCtrl.text = care;
      }
    }
  }

  Future<void> _openCreateSpeciesDialog() async {
    _newSpeciesNameCtrl.clear();
    _newSpeciesNotesCtrl.clear();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_creatingSpecies,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submit() async {
              final rawName = _newSpeciesNameCtrl.text.trim();
              final rawNotes = _newSpeciesNotesCtrl.text.trim();
              if (rawName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe o nome da espécie.')),
                );
                return;
              }
              setLocalState(() => _creatingSpecies = true);
              try {
                await _species.create(name: rawName, description: rawNotes);
                if (!mounted) return;
                Navigator.of(this.context).pop();
                await _refreshSpecies(selectName: rawName);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                      content: Text('Espécie cadastrada com sucesso.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Erro ao cadastrar espécie: $e')),
                );
              } finally {
                if (mounted) setLocalState(() => _creatingSpecies = false);
              }
            }

            return AlertDialog(
              title: const Text('Cadastrar espécie'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _newSpeciesNameCtrl,
                      enabled: !_creatingSpecies,
                      decoration: const InputDecoration(
                        labelText: 'Nome da espécie',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newSpeciesNotesCtrl,
                      enabled: !_creatingSpecies,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observações padrão da espécie',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _creatingSpecies
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _creatingSpecies ? null : submit,
                  child: _creatingSpecies
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndFinalize() async {
    if (_isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa análise já foi finalizada.')),
      );
      return;
    }
    if (_selectedSpeciesId == null || _selectedSpeciesId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma espécie.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar finalização'),
        content: const Text(
          'Ao finalizar esta análise, uma notificação será enviada ao usuário '
              'informando que o resultado está disponível. Deseja continuar?',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5B3F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, finalizar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _finalize();
  }

  Future<void> _finalize() async {
    if (_isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa análise já foi finalizada.')),
      );
      return;
    }
    final speciesId = (_selectedSpeciesId ?? '').trim();
    if (speciesId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma espécie.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final careInstructions = _careInstructionsCtrl.text.trim();
      final obsManuseio = _obsManuseioCtrl.text.trim();
      String speciesLabel = '';
      final sp = _findSpecies(speciesId);
      if (sp != null) {
        speciesLabel = _speciesName(sp, 'Espécie');
      }

      // O backend grava o resultado, notifica o usuario e audita.
      await _forage.finalizeAnalysisRequest(
        requestId: widget.requestId,
        speciesName: speciesLabel,
        careInstructions: careInstructions,
        adminNotes: obsManuseio,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Análise finalizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar análise: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  Future<void> _confirmAndReopen() async {
    if (!_canCurrentAdminReopen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Somente o admin autorizado pode reabrir uma análise concluída.',
          ),
        ),
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reabrir análise'),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: reasonCtrl,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Motivo da reabertura',
              hintText: 'Ex.: fotos insuficientes, dados inconsistentes...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    final cleanReason = (reason ?? '').trim();
    if (cleanReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o motivo da reabertura.')),
      );
      return;
    }

    await _reopenAnalysis(cleanReason);
  }

  Future<void> _reopenAnalysis(String reason) async {
    if (!_canCurrentAdminReopen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Somente o admin autorizado pode reabrir uma análise concluída.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // O backend reabre, notifica o usuario e audita.
      await _forage.reopenAnalysisRequest(
        requestId: widget.requestId,
        reason: reason,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Análise reaberta e enviada novamente para pendentes.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reabrir análise: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openSelectedImagePreview() async {
    if (_resolvedImageUrls.isEmpty) return;

    final index = _mainImageIndex.clamp(0, _resolvedImageUrls.length - 1);
    await showImageViewerDialog(
      context: context,
      title: 'Imagem ${index + 1}',
      child: AppSmartImage(
        source: _resolvedImageUrls[index],
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image,
          color: Colors.white70,
          size: 48,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth >= 1400
        ? 1120.0
        : screenWidth >= 1100
        ? 980.0
        : screenWidth >= 900
        ? 860.0
        : screenWidth * 0.96;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: dialogWidth,
        height: 720,
        child: _request == null
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final req = _request;
    if (req == null) {
      return const Center(child: Text('Solicitação não encontrada.'));
    }

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            border: Border(bottom: BorderSide(color: Color(0x14000000))),
          ),
          child: Row(
            children: [
              const Icon(Icons.biotech_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Análise de Forrageira',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (_isCompleted)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Finalizada',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                _saving ? null : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // ── Body ────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Coluna esquerda: dados + análise ────────────
                Expanded(
                  flex: 11,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _panel(
                          title: 'Dados enviados',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                runSpacing: 12,
                                spacing: 24,
                                children: [
                                  _infoItem('Nome',
                                      req.name.isEmpty ? '-' : req.name),
                                  _infoItem('Usuário', _userName),
                                  _infoItem(
                                      'Data', _fmtDateTime(req.createdAt)),
                                  _infoItem(
                                      'Latitude', req.latitude.toString()),
                                  _infoItem(
                                      'Longitude', req.longitude.toString()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Observações do usuário',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                req.notes.isEmpty ? '-' : req.notes,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _panel(
                          title: 'Resultado da análise',
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _speciesList.isEmpty
                                        ? const TextField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Espécie identificada',
                                        hintText:
                                        'Nenhuma espécie cadastrada',
                                        border: OutlineInputBorder(),
                                      ),
                                    )
                                        : DropdownButtonFormField<String>(
                                      initialValue:
                                      _selectedSpeciesId != null &&
                                          _speciesList.any((s) =>
                                          (s['id'] ?? '') ==
                                              _selectedSpeciesId)
                                          ? _selectedSpeciesId
                                          : null,
                                      isExpanded: true,
                                      items: _speciesList.map((s) {
                                        final id =
                                        (s['id'] ?? '').toString();
                                        return DropdownMenuItem<String>(
                                          value: id,
                                          child: Text(
                                              _speciesName(s, id)),
                                        );
                                      }).toList(),
                                      onChanged: (_saving || _isCompleted)
                                          ? null
                                          : (value) {
                                        if (value == null) return;
                                        setState(() =>
                                        _selectedSpeciesId =
                                            value);
                                        final sp =
                                        _findSpecies(value);
                                        if (sp != null) {
                                          final care =
                                          _speciesDescription(
                                              sp);
                                          if (care.isNotEmpty) {
                                            _careInstructionsCtrl
                                                .text = care;
                                          } else {
                                            _careInstructionsCtrl
                                                .clear();
                                          }
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Espécie identificada',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      onPressed: (_saving || _isCompleted)
                                          ? null
                                          : _openCreateSpeciesDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Nova espécie'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _careInstructionsCtrl,
                                maxLines: 4,
                                readOnly: _saving || _isCompleted,
                                decoration: const InputDecoration(
                                  labelText: 'Cuidados recomendados',
                                  border: OutlineInputBorder(),
                                  helperText:
                                  'Descrição da espécie. Edite se necessário.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _obsManuseioCtrl,
                                maxLines: 4,
                                readOnly: _saving || _isCompleted,
                                decoration: const InputDecoration(
                                  labelText: 'Observações de manuseio',
                                  border: OutlineInputBorder(),
                                  hintText: 'Observações livres do analista...',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // ── Coluna direita: imagens ──────────────────────
                // FIX: não usar Expanded dentro de _panel (Column sem
                // altura definida). Em vez disso, calculamos a altura
                // disponível com LayoutBuilder e passamos para o
                // container de imagem diretamente.
                Expanded(
                  flex: 9,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Altura disponível para o painel de imagens.
                      // O LayoutBuilder recebe a altura do Expanded
                      // pai (corpo do dialog menos padding).
                      final panelHeight = constraints.maxHeight;
                      return _imagePanel(panelHeight);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Footer ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x14000000))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isCompleted
                      ? (_canCurrentAdminReopen
                      ? 'Esta análise já foi concluída. O admin autorizado pode reabri-la.'
                      : 'Esta análise já foi concluída e não pode ser reaberta por este usuário.')
                      : 'Depois de finalizar, a análise não poderá ser alterada.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed:
                _saving ? null : () => Navigator.of(context).pop(false),
                child: const Text('Fechar'),
              ),
              if (_canCurrentAdminReopen) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _confirmAndReopen,
                  icon: _saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.restart_alt),
                  label: const Text('Reabrir análise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              if (!_isCompleted) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _confirmAndFinalize,
                  icon: _saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Finalizar análise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5B3F),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Painel de imagens com altura explícita vinda do LayoutBuilder
  // ─────────────────────────────────────────────────────────────
  Widget _imagePanel(double totalHeight) {
    // Reserva espaço para: título (16px texto + 14px gap + 16px padding top/bottom)
    const double panelPaddingV = 16 * 2;
    const double titleAndGap = 16 + 14; // fontSize + SizedBox
    const double thumbnailRowH = 70 + 10; // thumbnails + gap
    const double innerPadding = 8; // folga

    final hasMultiple = _resolvedImageUrls.length > 1;
    final imageAreaHeight = totalHeight -
        panelPaddingV -
        titleAndGap -
        (hasMultiple ? thumbnailRowH : 0) -
        innerPadding;

    return Container(
      width: double.infinity,
      height: totalHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Imagens enviadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          // ── Área principal da imagem ─────────────────────────
          Container(
            width: double.infinity,
            height: imageAreaHeight.clamp(80.0, double.infinity),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: _resolvedImageUrls.isEmpty || _allImagesFailed
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Imagem não disponível',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
                : GestureDetector(
              onTap: _openSelectedImagePreview,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppSmartImage(
                  source: _resolvedImageUrls[_mainImageIndex.clamp(
                      0, _resolvedImageUrls.length - 1)],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image,
                              size: 40, color: Colors.grey),
                          SizedBox(height: 6),
                          Text('Erro ao carregar imagem',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Miniaturas ───────────────────────────────────────
          if (hasMultiple) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _resolvedImageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _mainImageIndex;
                  return GestureDetector(
                    onTap: () {
                      if (index != _mainImageIndex) {
                        setState(() => _mainImageIndex = index);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          AppSmartImage(
                            source: _resolvedImageUrls[index],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                          if (isSelected)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF1F5B3F),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
