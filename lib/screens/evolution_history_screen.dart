import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/image_comparison.dart';
import '../services/ai_comparison_service.dart';
import '../widgets/safe_image.dart';

class EvolutionHistoryScreen extends StatefulWidget {
  final String? pontoObra;
  final String? projectId;

  const EvolutionHistoryScreen({
    super.key,
    this.pontoObra,
    this.projectId,
  });

  @override
  State<EvolutionHistoryScreen> createState() => _EvolutionHistoryScreenState();
}

class _EvolutionHistoryScreenState extends State<EvolutionHistoryScreen> {
  List<ImageComparison> _comparisons = [];
  bool _isLoading = true;
  String? _selectedPonto;

  @override
  void initState() {
    super.initState();
    _selectedPonto = widget.pontoObra;
    _loadComparisons();
  }

  Future<void> _loadComparisons() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<ImageComparison> comparisons;
      
      if (_selectedPonto != null && _selectedPonto!.isNotEmpty) {
        comparisons = await AIComparisonService.getComparisonsByPonto(
          user.uid,
          _selectedPonto!,
        );
      } else if (widget.projectId != null) {
        comparisons = await AIComparisonService.getComparisonsByProject(
          user.uid,
          widget.projectId!,
        );
      } else {
        // Buscar todas as comparações do usuário
        final stream = AIComparisonService.getComparisonsStream(user.uid);
        comparisons = await stream.first;
      }

      // Filtrar apenas comparações concluídas com evolução
      comparisons = comparisons
          .where((c) => 
              c.status == ComparisonStatus.completed &&
              c.evolutionPercentage != null)
          .toList();

      setState(() {
        _comparisons = comparisons;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar histórico: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Evolução'),
        actions: [
          if (widget.pontoObra == null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comparisons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma comparação encontrada',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Gráfico de evolução
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(16),
                      child: _buildEvolutionChart(),
                    ),
                    const Divider(),
                    // Lista de comparações
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comparisons.length,
                        itemBuilder: (context, index) {
                          final comparison = _comparisons[index];
                          return _buildComparisonCard(comparison);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEvolutionChart() {
    if (_comparisons.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    // Ordenar por data
    final sortedComparisons = List<ImageComparison>.from(_comparisons)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Preparar dados do gráfico
    final spots = sortedComparisons
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final comparison = entry.value;
          return FlSpot(
            index.toDouble(),
            comparison.evolutionPercentage ?? 0.0,
          );
        })
        .toList();

    // Labels do eixo X (datas)
    final bottomTitles = sortedComparisons
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final date = entry.value.timestamp;
          return SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() == index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          );
        })
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedComparisons.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(sortedComparisons[index].timestamp),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Widget _buildComparisonCard(ImageComparison comparison) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ponto: ${comparison.pontoObra}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Etapa: ${comparison.etapaObra}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.2),
                        Colors.green.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${comparison.evolutionPercentage?.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Evolução',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mensagem destacada sobre a evolução
            if (comparison.evolutionPercentage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: comparison.evolutionPercentage! > 50
                      ? Colors.green.withOpacity(0.1)
                      : comparison.evolutionPercentage! > 25
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: comparison.evolutionPercentage! > 50
                        ? Colors.green
                        : comparison.evolutionPercentage! > 25
                            ? Colors.orange
                            : Colors.blue,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: comparison.evolutionPercentage! > 50
                          ? Colors.green
                          : comparison.evolutionPercentage! > 25
                              ? Colors.orange
                              : Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A obra evoluiu ${comparison.evolutionPercentage!.toStringAsFixed(1)}% desde a imagem base!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: comparison.evolutionPercentage! > 50
                              ? Colors.green.shade700
                              : comparison.evolutionPercentage! > 25
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Antes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SafeImage(
                          imageUrl: comparison.baseImageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Depois',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SafeImage(
                          imageUrl: comparison.comparedImageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(comparison.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            if (comparison.detectedChanges.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...comparison.detectedChanges.take(2).map((change) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          change.type == ChangeType.added
                              ? Icons.add_circle
                              : change.type == ChangeType.removed
                                  ? Icons.remove_circle
                                  : Icons.edit,
                          size: 16,
                          color: change.type == ChangeType.added
                              ? Colors.green
                              : change.type == ChangeType.removed
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            change.description,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final pontos = _comparisons
        .map((c) => c.pontoObra)
        .toSet()
        .toList()
      ..sort();

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Ponto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              onTap: () => Navigator.pop(context, null),
            ),
            ...pontos.map((ponto) => ListTile(
                  title: Text(ponto),
                  onTap: () => Navigator.pop(context, ponto),
                )),
          ],
        ),
      ),
    );

    if (selected != _selectedPonto) {
      setState(() => _selectedPonto = selected);
      _loadComparisons();
    }
  }
}

