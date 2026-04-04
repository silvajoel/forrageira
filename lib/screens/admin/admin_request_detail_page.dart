import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_shell.dart';
import '../../services/navigation_service.dart';

class AdminRequestDetailPage extends StatefulWidget {
  const AdminRequestDetailPage({super.key});

  @override
  State<AdminRequestDetailPage> createState() => _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState extends State<AdminRequestDetailPage> {
  String? requestId;
  String? speciesName;
  final parecerCtrl = TextEditingController();
  final careCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    parecerCtrl.dispose();
    careCtrl.dispose();
    super.dispose();
  }

  bool _isLikelyHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    requestId ??= ModalRoute.of(context)?.settings.arguments as String?;
    if (requestId == null || requestId!.isEmpty) {
      return AdminShell(
        selectedMenu: 'pendentes',
        child: const Center(child: Text('Solicitação não encontrada.')),
      );
    }

    final forageService = context.read<IForageService>();

    return AdminShell(
      selectedMenu: 'pendentes',
      child: FutureBuilder<AnalysisRequest>(
        future: forageService.getById(requestId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Solicitação não encontrada.'));
          }

          final req = snapshot.data!;
          final imageUrls = req.imageUrls.where(_isLikelyHttpUrl).toList();
          speciesName ??= req.speciesName;
          if (parecerCtrl.text.isEmpty && req.adminNotes != null) {
            parecerCtrl.text = req.adminNotes!;
          }
          if (careCtrl.text.isEmpty && req.careInstructions != null) {
            careCtrl.text = req.careInstructions!;
          }

          return ListView(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 6),
                  Text('Análise ${req.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Dados enviados',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('Forrageira', req.name),
                    _kv('Usuário', req.userId),
                    _kv('Localização', '${req.latitude.toStringAsFixed(4)}, ${req.longitude.toStringAsFixed(4)}'),
                    const SizedBox(height: 8),
                    const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(req.notes, style: const TextStyle(color: Colors.black54)),
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text('Imagens enviadas:', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrls[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (req.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Os links das imagens não puderam ser exibidos (formato inválido).',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Resultado da análise',
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('species').orderBy('name').snapshots(),
                  builder: (context, speciesSnapshot) {
                    final docs = speciesSnapshot.data?.docs ?? [];
                    final names = docs
                        .map((d) => (d.data()['name'] ?? '').toString())
                        .where((n) => n.isNotEmpty)
                        .toList();
                    if (speciesName != null && speciesName!.isNotEmpty && !names.contains(speciesName)) {
                      names.insert(0, speciesName!);
                    }

                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: speciesName,
                          items: names
                              .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                              .toList(),
                          onChanged: (v) => setState(() => speciesName = v),
                          decoration: const InputDecoration(
                            labelText: 'Espécie identificada',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: careCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Cuidados recomendados',
                            hintText: 'Ex: Irrigar 2x por semana, solo argiloso...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: parecerCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Parecer / Observações do analista',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                  final selectedSpecies = speciesName;
                                  final care = careCtrl.text.trim();
                                  final notes = parecerCtrl.text.trim();
                                  if (selectedSpecies == null || selectedSpecies.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Selecione uma espécie.')),
                                    );
                                    return;
                                  }
                                  if (care.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Informe os cuidados recomendados.')),
                                    );
                                    return;
                                  }
                                  if (notes.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Informe um parecer.')),
                                    );
                                    return;
                                  }

                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Confirmar finalização'),
                                      content: const Text(
                                        'O usuário será notificado. Se a notificação falhar (permissões Firestore), a análise não será encerrada.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(dialogContext, true),
                                          child: const Text('Finalizar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;

                                  setState(() => _isSaving = true);
                                  try {
                                    await forageService.finalizeAnalysisRequest(
                                      requestId: req.id,
                                      speciesName: selectedSpecies,
                                      careInstructions: care,
                                      adminNotes: notes,
                                    );
                                    // Usa navigatorKey para navegar de forma confiável
                                    // independente do contexto (web rota raiz ou mobile)
                                    navigatorKey.currentState
                                        ?.pushReplacementNamed('/admin/requests');
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao finalizar. Verifique permissões (app_notifications) e tente de novo.\n$e',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isSaving = false);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F5B3F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                    : const Text('Finalizar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(width: 110, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}