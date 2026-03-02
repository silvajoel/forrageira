import 'package:flutter/material.dart';
import '../../data/admin_store.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminRequestDetailPage extends StatefulWidget {
  const AdminRequestDetailPage({super.key});

  @override
  State<AdminRequestDetailPage> createState() => _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState extends State<AdminRequestDetailPage> {
  final store = AdminStore.instance;

  String? requestId;
  String? especieId;
  final parecerCtrl = TextEditingController();

  @override
  void dispose() {
    parecerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    requestId ??= ModalRoute.of(context)?.settings.arguments as String?;
    final req = requestId == null ? null : store.getRequestById(requestId!);

    if (req == null) {
      return AdminShell(
        selectedMenu: 'pendentes',
        child: const Center(child: Text('Solicitação não encontrada.')),
      );
    }

    especieId ??= req.especieId ?? (store.species.isNotEmpty ? store.species.first.id : null);
    if (parecerCtrl.text.isEmpty && req.parecer != null) parecerCtrl.text = req.parecer!;

    return AdminShell(
      selectedMenu: 'pendentes',
      child: ListView(
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
                _kv('Cliente', req.cliente),
                _kv('Propriedade', req.propriedade),
                _kv('Localidade', req.localidade),
                const SizedBox(height: 8),
                const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(req.descricao, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 14),

                // Placeholder da imagem (quando integrar, trocar por Image.network)
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                  child: const Center(
                    child: Text('Imagem enviada (mock)'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _card(
            title: 'Resultado da análise',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: especieId,
                  items: store.species
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => especieId = v),
                  decoration: const InputDecoration(
                    labelText: 'Espécie (modelo)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: parecerCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Parecer / Observações',
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
                        onPressed: () {
                          final esp = especieId;
                          if (esp == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cadastre ou selecione uma espécie.')),
                            );
                            return;
                          }
                          if (parecerCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Informe um parecer.')),
                            );
                            return;
                          }

                          store.finalizeRequest(
                            requestId: req.id,
                            especieId: esp,
                            parecer: parecerCtrl.text.trim(),
                          );

                          Navigator.pushReplacementNamed(context, '/admin/requests');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F5B3F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Finalizar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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