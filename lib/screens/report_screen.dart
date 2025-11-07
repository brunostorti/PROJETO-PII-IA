import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/image_comparison.dart';
import '../services/ai_comparison_service.dart';
import '../widgets/safe_image.dart';
import '../widgets/modern_card.dart';
import '../widgets/annotated_image_overlay.dart';
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
                        // Comparação Visual - Design Melhorado
                        ModernCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.compare_arrows, color: AppTheme.primaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Comparação Visual',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ideal vs. Real',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Imagens lado a lado com design melhorado
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildImageCard(
                                      context,
                                      'Ideal',
                                      _c!.baseImageUrl,
                                      AppTheme.primaryColor,
                                      Icons.photo_library,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildImageCard(
                                      context,
                                      'Real',
                                      _c!.comparedImageUrl,
                                      AppTheme.secondaryColor,
                                      Icons.camera_alt,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Progresso - Design Melhorado
                        _buildProgressCard(),
                        const SizedBox(height: 20),
                        // Sobreposição Visual com Anotações
                        if (_c!.metadata != null && 
                            _c!.metadata!['gemini'] != null &&
                            _hasFindings(_c!.metadata!['gemini'])) ...[
                          _buildAnnotatedImageCard(),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildImageCard(BuildContext context, String label, String imageUrl, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.05),
                  color.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final progress = _c!.metadata != null && 
                     _c!.metadata!['gemini'] != null && 
                     _c!.metadata!['gemini']['progress'] != null
        ? (_c!.metadata!['gemini']['progress']['overallPercentage'] ?? _c!.evolutionPercentage ?? 0)
        : (_c!.evolutionPercentage ?? 0);
    
    final progressColor = progress >= 75 
        ? AppTheme.successColor 
        : progress >= 50 
            ? AppTheme.secondaryColor 
            : AppTheme.warningColor;
    
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [progressColor.withOpacity(0.2), progressColor.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: progressColor, size: 24),
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
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progresso melhorada
          Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress / 100,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [progressColor, progressColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_c!.metadata != null && 
              _c!.metadata!['gemini'] != null && 
              _c!.metadata!['gemini']['progress'] != null &&
              _c!.metadata!['gemini']['progress']['rationale'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _c!.metadata!['gemini']['progress']['rationale'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        height: 1.6,
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

  Widget _buildAnnotatedImageCard() {
    final gemini = _c!.metadata!['gemini'] as Map<String, dynamic>?;
    if (gemini == null) return const SizedBox.shrink();

    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.withOpacity(0.2), Colors.red.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.visibility, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análise Visual Detalhada',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Problemas destacados na imagem real',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Imagem com sobreposição
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnnotatedImageOverlay(
                imageUrl: _c!.comparedImageUrl,
                geminiData: gemini,
                width: double.infinity,
                height: 300,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legenda
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda - Elementos Faltantes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildLegendItem('Telhado', Colors.blue.shade400),
              _buildLegendItem('Parede', Colors.orange.shade400),
              _buildLegendItem('Pilar', Colors.red.shade400),
              _buildLegendItem('Viga', Colors.purple.shade400),
              _buildLegendItem('Porta', Colors.green.shade400),
              _buildLegendItem('Janela', Colors.cyan.shade400),
              _buildLegendItem('Acabamento', Colors.amber.shade400),
              _buildLegendItem('Instalação', Colors.teal.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Os elementos destacados em cores mostram o que falta para concluir a obra conforme o projeto ideal.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  bool _hasFindings(Map<String, dynamic> gemini) {
    final safety = gemini['safetyFindings'] as List?;
    final materials = gemini['missingMaterials'] as List?;
    final discrepancies = gemini['discrepancies'] as List?;
    
    return (safety?.isNotEmpty ?? false) ||
           (materials?.isNotEmpty ?? false) ||
           (discrepancies?.isNotEmpty ?? false);
  }

  Widget _buildGeminiReport() {
    final gemini = _c!.metadata!['gemini'] as Map<String, dynamic>?;
    if (gemini == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryLight.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatório Detalhado da IA',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Análise completa de segurança, materiais e discrepâncias',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withOpacity(0.2), iconColor.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${items.length} ${items.length == 1 ? 'item encontrado' : 'itens encontrados'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.iconColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
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


