import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/screens/main_screen.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final AnalysisRequest analysis;

  const AnalysisDetailScreen({
    Key? key,
    required this.analysis,
  }) : super(key: key);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = analysis.status == 'completed';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final mainScreen =
            context.findAncestorStateOfType<MainScreenState>();
            mainScreen?.setIndex(0); // volta para Home
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Detalhe da Análise'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isCompleted),
              const SizedBox(height: 24),
              _buildInfoSection(context),
              const SizedBox(height: 24),
              if (analysis.imageUrls.isNotEmpty) ...[
                _buildImagesSection(context),
                const SizedBox(height: 24),
              ],
              if (isCompleted)
                _buildResultSection(context)
              else
                _buildPendingSection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.hourglass_empty,
            color: isCompleted ? Colors.green : Colors.orange,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted ? 'Análise finalizada' : 'Em análise',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do envio',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          Icons.calendar_today,
          'Enviado em',
          _formatDate(analysis.createdAt),
        ),
        if (analysis.notes.isNotEmpty)
          _buildInfoRow(
            Icons.note_alt_outlined,
            'Observações',
            analysis.notes,
          ),
        _buildInfoRow(
          Icons.location_on_outlined,
          'Localização',
          '${analysis.latitude.toStringAsFixed(4)}, '
              '${analysis.longitude.toStringAsFixed(4)}',
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagens enviadas',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: analysis.imageUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                analysis.imageUrls[index],
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
      ],
    );
  }

  Widget _buildResultSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultado da análise',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (analysis.speciesName != null)
          _buildResultCard(
            icon: Icons.grass,
            label: 'Espécie identificada',
            value: analysis.speciesName!,
            color: Colors.green,
          ),
        if (analysis.careInstructions != null) ...[
          const SizedBox(height: 10),
          _buildResultCard(
            icon: Icons.eco_outlined,
            label: 'Cuidados recomendados',
            value: analysis.careInstructions!,
            color: Colors.teal,
          ),
        ],
        if (analysis.adminNotes != null) ...[
          const SizedBox(height: 10),
          _buildResultCard(
            icon: Icons.comment_outlined,
            label: 'Observações do analista',
            value: analysis.adminNotes!,
            color: Colors.blue,
          ),
        ],
        if (analysis.reviewedAt != null) ...[
          const SizedBox(height: 12),
          Text(
            'Finalizado em ${_formatDate(analysis.reviewedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top,
              color: Colors.orange, size: 48),
          const SizedBox(height: 12),
          Text(
            'Análise em andamento',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua forrageira está sendo analisada por nossa equipe. '
                'Você será notificado quando o resultado estiver disponível.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}