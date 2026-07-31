import 'package:flutter/material.dart';

class AdminSupportPage extends StatelessWidget {
  const AdminSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'FAQ / Suporte',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Central de ajuda e suporte técnico do sistema.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 18),
        _card(
          title: 'Canais de Atendimento',
          icon: Icons.contact_support_outlined,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precisa de suporte com o aplicativo ou com o painel administrativo?',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.email_outlined, color: Color(0xFF1F5B3F)),
                title: Text('E-mail de Suporte'),
                subtitle: Text('acir@ufsj.edu.br'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.account_balance_outlined, color: Color(0xFF1F5B3F)),
                title: Text('Instituição'),
                subtitle: Text('Universidade Federal de São João del-Rei (UFSJ)'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Perguntas Frequentes (FAQ)',
          icon: Icons.help_outline,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FaqItem(
                question: 'Como funciona o processo de análise de forrageiras?',
                answer: 'O usuário envia a foto e a localização pelo aplicativo. A solicitação entra na aba "Solicitações", onde o especialista analisa a foto, vincula a espécie e finaliza a emissão do laudo.',
              ),
              Divider(),
              _FaqItem(
                question: 'Como faço para reabrir uma análise concluída?',
                answer: 'Apenas admins autorizados podem reabrir laudos. Ao abrir a solicitação em "Histórico de Laudos", o botão "Reabrir análise" estará disponível.',
              ),
              Divider(),
              _FaqItem(
                question: 'Como adicionar uma nova espécie ao banco?',
                answer: 'Acesse o menu "Banco de Espécies", clique em "Nova espécie", preencha o nome/descrição e clique em salvar.',
              ),
            ],
          ),
        ),
      ],
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