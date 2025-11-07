import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/image_comparison.dart';
import '../models/ponto_obra.dart';
import '../services/ai_comparison_service.dart';
import '../services/project_service.dart';
import '../services/registro_obra_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/ponto_obra_service.dart';
import '../widgets/safe_image.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'evolution_history_screen.dart';
import 'ponto_obra_form_screen.dart';
import 'ponto_detail_screen.dart';
import 'project_users_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<ImageComparison> _comparisons = [];
  bool _isLoading = true;
  Project? _currentProject;
  String? _selectedPontoId;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _loadData(); // Carregar tudo de uma vez
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Load latest project data
      final project = await ProjectService.getProject(widget.project.id);
      if (project == null) {
        throw Exception('Projeto não encontrado.');
      }

      // Load comparisons for this project
      final fetchedComparisons = await AIComparisonService.getComparisonsByProject(
        user.uid,
        widget.project.id,
      );
      
      // Filtrar apenas comparações concluídas e ordenar por data (mais recente primeiro)
      final completedComparisons = fetchedComparisons
          .where((c) => c.status == ComparisonStatus.completed && c.evolutionPercentage != null)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Mais recente primeiro
      
      if (mounted) {
        setState(() {
          _currentProject = project;
          _comparisons = completedComparisons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Erro ao carregar detalhes do projeto: $e');
    }
  }

  Future<void> _openAddPonto() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PontoObraFormScreen(projectId: widget.project.id),
      ),
    );
    if (created == true) {
      await _loadData();
    }
  }

  Future<void> _addNewImageAndCompare() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado')),
        );
        return;
      }

      // Exigir seleção de ponto para comparar com o ideal do ponto
      if (_selectedPontoId == null || _selectedPontoId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um ponto da obra para comparar')),
        );
        return;
      }

      // Selecionar nova imagem
      File? newImageFile;
      Uint8List? newImageBytes;

      if (kIsWeb) {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          newImageBytes = result.files.single.bytes;
        }
      } else {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          newImageFile = File(result.files.single.path!);
        }
      }

      if (newImageFile == null && newImageBytes == null) {
        setState(() { _isLoading = false; });
        return; // Usuário cancelou
      }

      // Ponto da Obra: obter nome do ponto selecionado (opcional para registro)
      String pontoObra = 'Ponto';
      try {
        final ponto = await PontoObraService.getPonto(projectId: widget.project.id, pontoId: _selectedPontoId!);
        if (ponto != null) pontoObra = ponto.name;
      } catch (_) {}

      // Apenas perguntar a etapa da obra (sem baseRegistro)
      final etapaObra = await _showInputDialog('Etapa da Obra', initialValue: null);
      if (etapaObra == null || etapaObra.isEmpty) {
        setState(() { _isLoading = false; });
        return;
      }

      // Upload da nova imagem
      String? newImageUrl;
      if (kIsWeb && newImageBytes != null) {
        newImageUrl = await FirebaseStorageService.uploadRegistroImageBytes(
          bytes: newImageBytes,
          userId: user.uid,
        );
      } else if (newImageFile != null) {
        newImageUrl = await FirebaseStorageService.uploadRegistroImage(
          imageFile: newImageFile,
          userId: user.uid,
        );
      }

      if (newImageUrl == null) {
        throw Exception('Erro ao fazer upload da imagem');
      }

      // Criar registro da nova imagem
      final newRegistro = RegistroObraService.createRegistro(
        userId: user.uid,
        imageUrl: newImageUrl,
        pontoObra: pontoObra,
        etapaObra: etapaObra,
        projectId: widget.project.id,
        timestamp: DateTime.now(),
      );

      await RegistroObraService.saveRegistro(newRegistro);

      // Comparar com a imagem ideal do ponto
      final comparisonId = await AIComparisonService.compareWithIdeal(
        projectId: widget.project.id,
        pontoId: _selectedPontoId!,
        registroId: newRegistro.id,
      );

      // Recarregar todos os dados (projeto e comparações)
      await _loadData();

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nova imagem adicionada e comparada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<String?> _showInputDialog(String title, {String? initialValue}) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Digite o $title',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentProject?.name ?? widget.project.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Histórico de Evolução',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EvolutionHistoryScreen(
                    projectId: widget.project.id,
                  ),
                ),
              );
            },
          ),
          // Botão para gerenciar usuários (apenas para admin/dono do projeto)
          Consumer<app_auth.AuthProvider>(
            builder: (context, authProvider, _) {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user != null && _currentProject?.userId == user.uid;
              final isAdmin = authProvider.isAdmin;
              
              if (!isOwner && !isAdmin) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: const Icon(Icons.people),
                tooltip: 'Gerenciar Usuários do Projeto',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectUsersScreen(
                        projectId: widget.project.id,
                        projectName: _currentProject?.name ?? widget.project.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pontos do Projeto
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.place, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Pontos da Obra',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed: _openAddPonto,
                                icon: const Icon(Icons.add),
                                label: const Text('Adicionar Ponto'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<PontoObra>>(
                            stream: PontoObraService.getPontosStream(widget.project.id),
                            builder: (context, snapshot) {
                              final pontos = snapshot.data ?? [];
                              if (pontos.isEmpty) {
                                return const Text('Nenhum ponto cadastrado ainda.');
                              }
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pontos.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final p = pontos[index];
                                  return InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PontoDetailScreen(
                                            projectId: widget.project.id,
                                            pontoId: p.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              bottomLeft: Radius.circular(12),
                                            ),
                                            child: p.idealImageUrl != null
                                                ? SafeImage(
                                                    imageUrl: p.idealImageUrl!,
                                                    width: 120,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    borderRadius: BorderRadius.circular(0),
                                                  )
                                                : Container(
                                                    width: 120,
                                                    height: 80,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image, color: Colors.grey),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  p.idealImageUrl != null ? 'Ideal definido' : 'Ideal não definido',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botão para adicionar nova imagem
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addNewImageAndCompare,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Adicionar Nova Imagem e Comparar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Gráfico de evolução
                  if (_comparisons.isNotEmpty) ...[
                    const Text(
                      'Evolução do Projeto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildEvolutionChart(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Histórico de comparações
                  const Text(
                    'Histórico de Comparações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_comparisons.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma comparação ainda',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Adicione uma nova imagem para começar',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._comparisons.map((comparison) => _buildComparisonCard(comparison)),
                ],
              ),
            ),
    );
  }

  Widget _buildEvolutionChart() {
    if (_comparisons.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    // Ordenar por data (mais antiga primeiro para o gráfico)
    final sortedComparisons = List<ImageComparison>.from(_comparisons)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Filtrar apenas comparações com evolutionPercentage válido
    final validComparisons = sortedComparisons
        .where((c) => c.evolutionPercentage != null && c.evolutionPercentage! >= 0)
        .toList();

    if (validComparisons.isEmpty) {
      return const Center(child: Text('Sem dados de evolução para exibir'));
    }

    final spots = validComparisons
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final comparison = entry.value;
          return FlSpot(
            index.toDouble(),
            comparison.evolutionPercentage!,
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
                if (index >= 0 && index < validComparisons.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(validComparisons[index].timestamp),
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
        minX: 0,
        maxX: validComparisons.length > 1 ? (validComparisons.length - 1).toDouble() : 1.0,
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
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${comparison.evolutionPercentage?.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                          'Base',
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
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                          ),
                          child: SafeImage(
                            imageUrl: comparison.baseImageUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          'Nova',
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
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                          ),
                          child: SafeImage(
                            imageUrl: comparison.comparedImageUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
          ],
        ),
      ),
    );
  }
}

