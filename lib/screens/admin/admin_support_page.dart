import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://capim.ufsj.edu.br/api/support/tickets'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tickets = data['data']['tickets'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Falha ao carregar chamados de suporte.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão com o servidor: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAQ / Suporte',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Central de ajuda e chamados do sistema.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1F5B3F)),
              tooltip: 'Atualizar chamados',
              onPressed: _fetchTickets,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // CARD DE CHAMADOS DE SUPORTE (NOVO)
        _card(
          title: 'Chamados Recebidos',
          icon: Icons.inbox_outlined,
          child: _buildTicketsSection(),
        ),

        const SizedBox(height: 16),

        // CARD DE FAQ EXISTENTE
        _card(
          title: 'Perguntas Frequentes (FAQ)',
          icon: Icons.help_outline,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FaqItem(
                question: 'Como funciona o processo de análise de forrageiras?',
                answer:
                    'O usuário envia a foto e a localização pelo aplicativo. A solicitação entra na aba "Solicitações", onde o especialista analisa a foto, vincula a espécie e finaliza a emissão do laudo.',
              ),
              Divider(),
              _FaqItem(
                question: 'Como faço para reabrir uma análise concluída?',
                answer:
                    'Apenas admins autorizados podem reabrir laudos. Ao abrir a solicitação em "Histórico de Laudos", o botão "Reabrir análise" estará disponível.',
              ),
              Divider(),
              _FaqItem(
                question: 'Como adicionar uma nova espécie ao banco?',
                answer:
                    'Acesse o menu "Banco de Espécies", clique em "Nova espécie", preencha o nome/descrição e clique em salvar.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_tickets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text(
          'Nenhum chamado pendente no momento.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tickets.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF1F5B3F)),
          title: Text(
            ticket['subject'] ?? 'Sem Assunto',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            'De: ${ticket['name']} (${ticket['email']}) • ${ticket['created_at'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((ticket['phone'] ?? '').toString().isNotEmpty) ...[
                      Text(
                        'Telefone: ${ticket['phone']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      'Mensagem:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket['description'] ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1F5B3F)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(color: Color(0xFF4B5563), height: 1.4),
          ),
        ],
      ),
    );
  }
}