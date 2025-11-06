import 'package:flutter/material.dart';
import '../models/image_comparison.dart';
import '../utils/app_theme.dart';

class ComparisonResultWidget extends StatelessWidget {
  final ImageComparison comparison;
  final VoidCallback? onSaveToProject;
  final bool showSaveButton;

  const ComparisonResultWidget({
    super.key,
    required this.comparison,
    this.onSaveToProject,
    this.showSaveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (comparison.status == ComparisonStatus.error) {
      return _buildErrorWidget();
    }

    if (comparison.status == ComparisonStatus.processing ||
        comparison.status == ComparisonStatus.pending) {
      return _buildProcessingWidget();
    }

    return _buildResultWidget();
  }

  Widget _buildErrorWidget() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Erro ao processar comparação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (comparison.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(comparison.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              comparison.status.displayName,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analisando imagens com IA...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Resultado da Comparação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Percentual de evolução
            if (comparison.evolutionPercentage != null) ...[
              _buildEvolutionCard(),
              const SizedBox(height: 16),
            ],

            // Similaridade
            if (comparison.similarityScore != null) ...[
              _buildSimilarityCard(),
              const SizedBox(height: 16),
            ],

            // Mudanças detectadas
            if (comparison.detectedChanges.isNotEmpty) ...[
              const Text(
                'Mudanças Detectadas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...comparison.detectedChanges.map((change) => _buildChangeCard(change)),
            ],

            // Informações adicionais
            const SizedBox(height: 16),
            _buildInfoCard(),

            // Botão Salvar no Projeto
            if (showSaveButton && onSaveToProject != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSaveToProject,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar no Projeto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionCard() {
    final percentage = comparison.evolutionPercentage!;
    final color = percentage > 50
        ? Colors.green
        : percentage > 25
            ? Colors.orange
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Evolução da Obra',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarityCard() {
    final similarity = comparison.similarityScore!;
    final percentage = (similarity * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Similaridade',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeCard(DetectedChange change) {
    IconData icon;
    Color color;

    switch (change.type) {
      case ChangeType.added:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case ChangeType.removed:
        icon = Icons.remove_circle;
        color = Colors.red;
        break;
      case ChangeType.modified:
        icon = Icons.edit;
        color = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(change.description),
        subtitle: Text(
          'Confiança: ${(change.confidence * 100).toStringAsFixed(1)}%',
        ),
        trailing: Text(
          change.type.displayName,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Ponto da Obra', comparison.pontoObra),
          const SizedBox(height: 4),
          _buildInfoRow('Etapa', comparison.etapaObra),
          const SizedBox(height: 4),
          _buildInfoRow(
            'Data',
            '${comparison.timestamp.day}/${comparison.timestamp.month}/${comparison.timestamp.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

