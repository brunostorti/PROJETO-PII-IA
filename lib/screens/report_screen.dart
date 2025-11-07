import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/image_comparison.dart';
import '../services/ai_comparison_service.dart';
import '../widgets/safe_image.dart';
import '../widgets/modern_card.dart';
import '../utils/app_theme.dart';

class ReportScreen extends StatefulWidget {
  final String comparisonId;
  const ReportScreen({super.key, required this.comparisonId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ImageComparison? _c;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await AIComparisonService.getComparison(widget.comparisonId);
      if (mounted) setState(() => _c = c);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório da Comparação'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_c == null)
              ? const Center(child: Text('Comparação não encontrada'))
              : Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.surfaceGradient,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comparação Visual
                        ModernCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.compare_arrows, color: AppTheme.primaryColor, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Comparação Visual',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ModernBadge(
                                          label: 'Ideal',
                                          icon: Icons.photo,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: SafeImage(
                                            imageUrl: _c!.baseImageUrl,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ModernBadge(
                                          label: 'Real',
                                          icon: Icons.camera_alt,
                                          color: AppTheme.secondaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: SafeImage(
                                            imageUrl: _c!.comparedImageUrl,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progresso
                        _buildProgressCard(),
                        const SizedBox(height: 16),
                        // Relatório Gemini
                        if (_c!.metadata != null && _c!.metadata!['gemini'] != null) ...[
                          _buildGeminiReport(),
                        ] else ...[
                          ModernCard(
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Sem relatório do Gemini',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Verifique se a configuração Gemini está habilitada',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _c!.metadata != null && 
                     _c!.metadata!['gemini'] != null && 
                     _c!.metadata!['gemini']['progress'] != null
        ? (_c!.metadata!['gemini']['progress']['overallPercentage'] ?? _c!.evolutionPercentage ?? 0)
        : (_c!.evolutionPercentage ?? 0);
    
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progresso Geral',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.toStringAsFixed(1)}% Concluído',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 75 
                    ? AppTheme.successColor 
                    : progress >= 50 
                        ? AppTheme.secondaryColor 
                        : AppTheme.warningColor,
              ),
            ),
          ),
          if (_c!.metadata != null && 
              _c!.metadata!['gemini'] != null && 
              _c!.metadata!['gemini']['progress'] != null &&
              _c!.metadata!['gemini']['progress']['rationale'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _c!.metadata!['gemini']['progress']['rationale'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeminiReport() {
    final gemini = _c!.metadata!['gemini'] as Map<String, dynamic>?;
    if (gemini == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Relatório da IA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segurança
        if (gemini['safetyFindings'] != null && (gemini['safetyFindings'] as List).isNotEmpty)
          _buildSectionCard(
            title: 'Segurança do Trabalho',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            items: (gemini['safetyFindings'] as List).map((f) {
              final m = f as Map<String, dynamic>;
              return _ReportItem(
                title: m['description'] ?? '-',
                subtitle: '${_getSeverityLabel(m['severity'])} • Confiança: ${((m['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                icon: Icons.warning_amber_rounded,
                iconColor: _getSeverityColor(m['severity']),
              );
            }).toList(),
          ),
        // Materiais Faltantes
        if (gemini['missingMaterials'] != null && (gemini['missingMaterials'] as List).isNotEmpty)
          _buildSectionCard(
            title: 'Materiais Faltantes',
            icon: Icons.construction_outlined,
            iconColor: Colors.redAccent,
            items: (gemini['missingMaterials'] as List).map((f) {
              final m = f as Map<String, dynamic>;
              return _ReportItem(
                title: m['element'] ?? '-',
                subtitle: '${m['description'] ?? '-'} • Confiança: ${((m['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                icon: Icons.remove_circle_outline,
                iconColor: Colors.redAccent,
              );
            }).toList(),
          ),
        // Discrepâncias
        if (gemini['discrepancies'] != null && (gemini['discrepancies'] as List).isNotEmpty)
          _buildSectionCard(
            title: 'Discrepâncias',
            icon: Icons.rule_outlined,
            iconColor: Colors.blueGrey,
            items: (gemini['discrepancies'] as List).map((f) {
              final m = f as Map<String, dynamic>;
              return _ReportItem(
                title: '${m['element'] ?? '-'} - ${m['metric'] ?? '-'}',
                subtitle: 'Esperado: ${m['expected'] ?? '-'} • Medido: ${m['measured'] ?? '-'} • Δ: ${m['delta'] ?? '-'} • ${_getSeverityLabel(m['severity'])}',
                icon: Icons.rule_outlined,
                iconColor: _getSeverityColor(m['severity']),
              );
            }).toList(),
          ),
        // Ações Sugeridas
        if (gemini['suggestedActions'] != null && (gemini['suggestedActions'] as List).isNotEmpty)
          _buildSectionCard(
            title: 'Ações Sugeridas',
            icon: Icons.lightbulb_outline,
            iconColor: AppTheme.secondaryColor,
            items: (gemini['suggestedActions'] as List).map((f) {
              final m = f as Map<String, dynamic>;
              return _ReportItem(
                title: m['title'] ?? '-',
                subtitle: '${m['description'] ?? '-'} • Prioridade: ${_getPriorityLabel(m['priority'])}',
                icon: Icons.playlist_add_check_circle,
                iconColor: _getPriorityColor(m['priority']),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_ReportItem> items,
  }) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: item.iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _getSeverityLabel(String? severity) {
    switch (severity) {
      case 'critical': return 'Crítico';
      case 'high': return 'Alto';
      case 'medium': return 'Médio';
      case 'low': return 'Baixo';
      default: return severity ?? '-';
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case 'high': return 'Alta';
      case 'medium': return 'Média';
      case 'low': return 'Baixa';
      default: return priority ?? '-';
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return AppTheme.secondaryColor;
      default: return Colors.grey;
    }
  }
}

class _ReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  _ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}


