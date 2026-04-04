import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class _AdminRequestAnalysisDialogState extends State<AdminRequestAnalysisDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _parecerCtrl = TextEditingController();
  final TextEditingController _newSpeciesNameCtrl = TextEditingController();
  final TextEditingController _newSpeciesNotesCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _saving = false;
  bool _creatingSpecies = false;
  bool _speciesLoaded = false;

  Map<String, dynamic>? _request;
  String _userName = '-';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _speciesDocs = [];
  String? _selectedSpeciesId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _parecerCtrl.dispose();
    _newSpeciesNameCtrl.dispose();
    _newSpeciesNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final requestDoc = await _firestore
          .collection('analysis_requests')
          .doc(widget.requestId)
          .get();

      if (!requestDoc.exists) {
        if (!mounted) return;
        setState(() => _request = null);
        return;
      }

      final request = <String, dynamic>{
        'id': requestDoc.id,
        ...requestDoc.data()!,
      };

      final userId = (request['user_id'] ?? '').toString();
      String userName = '-';
      if (userId.isNotEmpty) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};
          userName = (userData['name'] ?? userId).toString();
        } else {
          userName = userId;
        }
      }

      final speciesSnap = await _loadSpeciesSnapshot();

      if (!mounted) return;

      setState(() {
        _request = request;
        _userName = userName;
        _speciesDocs = speciesSnap.docs;
        _selectedSpeciesId = _existingSpeciesId(request);

        final existingParecer = (request['parecer'] ?? '').toString().trim();
        if (existingParecer.isNotEmpty) {
          _parecerCtrl.text = existingParecer;
        }

        if (_selectedSpeciesId == null && _speciesDocs.isNotEmpty && !_isCompleted) {
          _selectedSpeciesId = _speciesDocs.first.id;
        }
      });

      if (!_isCompleted && _selectedSpeciesId != null && _parecerCtrl.text.trim().isEmpty) {
        _applySpeciesNotes(_selectedSpeciesId!, force: false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar análise: $e')),
      );
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadSpeciesSnapshot() async {
    try {
      return await _firestore.collection('species').orderBy('name').get();
    } catch (_) {
      try {
        return await _firestore.collection('species').orderBy('nome').get();
      } catch (_) {
        return await _firestore.collection('species').get();
      }
    }
  }

  String? _existingSpeciesId(Map<String, dynamic> request) {
    final value = (request['species_id'] ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }

  bool get _isCompleted {
    final status = (_request?['status'] ?? '').toString().trim().toLowerCase();
    return status == 'completed' || status == 'finalizado';
  }

  String _fmtDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  String _speciesName(Map<String, dynamic> data, String fallback) {
    return (data['name'] ?? data['nome'] ?? fallback).toString();
  }

  String _speciesNotes(Map<String, dynamic> data) {
    return (data['description'] ??
        data['notes'] ??
        data['observations'] ??
        data['observacoes'] ??
        data['descricao'] ??
        '')
        .toString()
        .trim();
  }

  Future<void> _refreshSpecies({String? selectId}) async {
    final snap = await _loadSpeciesSnapshot();
    if (!mounted) return;

    setState(() {
      _speciesDocs = snap.docs;
      if (selectId != null) {
        _selectedSpeciesId = selectId;
      } else if (_selectedSpeciesId != null &&
          !_speciesDocs.any((doc) => doc.id == _selectedSpeciesId)) {
        _selectedSpeciesId = null;
      }
    });

    if (selectId != null && !_isCompleted) {
      _applySpeciesNotes(selectId, force: true);
    }
  }

  void _applySpeciesNotes(String speciesId, {required bool force}) {
    final speciesDoc = _speciesDocs.where((doc) => doc.id == speciesId).cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
          (doc) => doc != null,
          orElse: () => null,
        );
    if (speciesDoc == null) return;

    final notes = _speciesNotes(speciesDoc.data());
    if (notes.isEmpty) return;

    if (force || _parecerCtrl.text.trim().isEmpty || !_speciesLoaded) {
      _parecerCtrl.text = notes;
      _parecerCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _parecerCtrl.text.length),
      );
    }

    _speciesLoaded = true;
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
                final uid = _auth.currentUser?.uid;

                final docRef = await _firestore.collection('species').add({
                  'name': rawName,
                  'description': rawNotes,
                  'active': true,
                  'created_at': FieldValue.serverTimestamp(),
                  'created_by': uid,
                  'updated_at': FieldValue.serverTimestamp(),
                  'updated_by': uid,
                });

                if (!mounted) return;
                Navigator.of(context).pop();
                await _refreshSpecies(selectId: docRef.id);

                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Espécie cadastrada com sucesso.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Erro ao cadastrar espécie: $e')),
                );
              } finally {
                if (mounted) {
                  setLocalState(() => _creatingSpecies = false);
                }
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
                  onPressed: _creatingSpecies ? null : () => Navigator.of(context).pop(),
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

  Future<void> _finalize() async {
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

    final parecer = _parecerCtrl.text.trim();
    if (parecer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha as observações da análise.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _firestore.collection('analysis_requests').doc(widget.requestId).update({
        'status': 'completed',
        'species_id': _selectedSpeciesId,
        'parecer': parecer,
        'completed_at': FieldValue.serverTimestamp(),
      });

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

    final imageUrl = (req['image_url'] ?? req['photo_url'] ?? req['image'] ?? '').toString();

    return Column(
      children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise da solicitação ${req['id']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isCompleted ? 'Esta análise já foi finalizada.' : 'Revise os dados e conclua a identificação.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (_isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                  _infoItem('Nome', (req['name'] ?? '-').toString()),
                                  _infoItem('Usuário', _userName),
                                  _infoItem('Data', _fmtDate(req['created_at'])),
                                  _infoItem('Latitude', (req['latitude'] ?? '-').toString()),
                                  _infoItem('Longitude', (req['longitude'] ?? '-').toString()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Observações do usuário',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (req['notes'] ?? '-').toString(),
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
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSpeciesId,
                                      items: _speciesDocs.map((doc) {
                                        final data = doc.data();
                                        return DropdownMenuItem<String>(
                                          value: doc.id,
                                          child: Text(_speciesName(data, doc.id)),
                                        );
                                      }).toList(),
                                      onChanged: (_saving || _isCompleted)
                                          ? null
                                          : (value) {
                                              if (value == null) return;
                                              setState(() => _selectedSpeciesId = value);
                                              _applySpeciesNotes(value, force: true);
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
                                controller: _parecerCtrl,
                                maxLines: 10,
                                readOnly: _saving || _isCompleted,
                                decoration: InputDecoration(
                                  labelText: 'Observações / parecer final',
                                  border: const OutlineInputBorder(),
                                  helperText: _isCompleted
                                      ? 'Análise bloqueada após finalização.'
                                      : 'Ao selecionar uma espécie, as observações padrão são preenchidas automaticamente.',
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
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      Expanded(
                        child: _panel(
                          title: 'Imagem enviada',
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x14000000)),
                            ),
                            child: imageUrl.isEmpty
                                ? const Center(child: Text('Imagem não disponível'))
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) {
                                        return const Center(
                                          child: Text('Não foi possível carregar a imagem'),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x14000000))),
          ),
          child: Row(
            children: [
              Text(
                _isCompleted
                    ? 'Solicitação bloqueada para reanálise.'
                    : 'Depois de finalizar, a análise não poderá ser alterada.',
                style: const TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                child: const Text('Fechar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_saving || _isCompleted) ? null : _finalize,
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
          ),
        ),
      ],
    );
  }

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
