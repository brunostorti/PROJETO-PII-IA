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
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
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
          : Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.subtleBackgroundGradient,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção 1: Informações Principais do Projeto - Contexto inicial
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: _buildProjectInfoSection(context),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Seção 2: Pontos do Projeto - Estrutura da obra
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppTheme.primaryColor.withOpacity(0.15),
                                                    AppTheme.primaryLight.withOpacity(0.1),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Icon(Icons.place_rounded, color: AppTheme.primaryColor, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Pontos da Obra',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.organicGradient,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: AppTheme.floatingShadow,
                                          ),
                                          child: OutlinedButton.icon(
                                            onPressed: _openAddPonto,
                                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                                            label: const Text(
                                              'Adicionar Ponto',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    StreamBuilder<List<PontoObra>>(
                                      stream: PontoObraService.getPontosStream(widget.project.id),
                                      builder: (context, snapshot) {
                                        final pontos = snapshot.data ?? [];
                                        if (pontos.isEmpty) {
                                          return Container(
                                            padding: const EdgeInsets.all(32),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceColor,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.place_outlined, size: 48, color: AppTheme.textLightColor),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Nenhum ponto cadastrado ainda',
                                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      color: AppTheme.textSecondaryColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Adicione um ponto para começar',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppTheme.textLightColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
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
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                        PontoDetailScreen(
                                                          projectId: widget.project.id,
                                                          pontoId: p.id,
                                                        ),
                                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                      const begin = Offset(1.0, 0.0);
                                                      const end = Offset.zero;
                                                      const curve = Curves.easeInOutCubic;
                                                      var tween = Tween(begin: begin, end: end).chain(
                                                        CurveTween(curve: curve),
                                                      );
                                                      return SlideTransition(
                                                        position: animation.drive(tween),
                                                        child: FadeTransition(
                                                          opacity: animation,
                                                          child: child,
                                                        ),
                                                      );
                                                    },
                                                    transitionDuration: const Duration(milliseconds: 300),
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(18),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(
                                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                  boxShadow: AppTheme.subtleShadow,
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(18),
                                                        bottomLeft: Radius.circular(18),
                                                      ),
                                                      child: p.idealImageUrl != null
                                                          ? SafeImage(
                                                              imageUrl: p.idealImageUrl!,
                                                              width: 100,
                                                              height: 100,
                                                              fit: BoxFit.cover,
                                                              borderRadius: BorderRadius.circular(0),
                                                            )
                                                          : Container(
                                                              width: 100,
                                                              height: 100,
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    AppTheme.primaryColor.withOpacity(0.1),
                                                                    AppTheme.primaryLight.withOpacity(0.05),
                                                                  ],
                                                                ),
                                                              ),
                                                              child: Icon(Icons.image_outlined, color: AppTheme.textLightColor, size: 32),
                                                            ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            p.name,
                                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                              fontWeight: FontWeight.w700,
                                                              color: AppTheme.textPrimaryColor,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: p.idealImageUrl != null
                                                                  ? AppTheme.successColor.withOpacity(0.1)
                                                                  : AppTheme.warningColor.withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(12),
                                                              border: Border.all(
                                                                color: p.idealImageUrl != null
                                                                    ? AppTheme.successColor.withOpacity(0.3)
                                                                    : AppTheme.warningColor.withOpacity(0.3),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  p.idealImageUrl != null ? Icons.check_circle : Icons.pending,
                                                                  size: 14,
                                                                  color: p.idealImageUrl != null ? AppTheme.successColor : AppTheme.warningColor,
                                                                ),
                                                                const SizedBox(width: 6),
                                                                Text(
                                                                  p.idealImageUrl != null ? 'Ideal definido' : 'Ideal não definido',
                                                                  style: TextStyle(
                                                                    color: p.idealImageUrl != null ? AppTheme.successColor : AppTheme.warningColor,
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor),
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
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Seção 3: Evolução do Projeto - Análise visual
                    if (_comparisons.isNotEmpty) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: _buildEvolutionSection(context),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Seção 4: Histórico de Comparações - Detalhes temporais
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: _buildComparisonsSection(context),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Seção de informações principais do projeto
  Widget _buildProjectInfoSection(BuildContext context) {
    final project = _currentProject ?? widget.project;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (project.description.isNotEmpty)
                      Text(
                        project.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(project.status),
                      _getStatusColor(project.status).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(project.status).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      project.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Informações em Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.location_on_rounded,
                  label: 'Localização',
                  value: project.location,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Início',
                  value: _formatDate(project.startDate),
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          if (project.endDate != null) ...[
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.event_available_rounded,
              label: 'Data de Conclusão',
              value: _formatDate(project.endDate!),
              color: AppTheme.successColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppTheme.warningColor;
      case ProjectStatus.inProgress:
        return AppTheme.primaryColor;
      case ProjectStatus.completed:
        return AppTheme.successColor;
      case ProjectStatus.paused:
        return AppTheme.accentColor;
      case ProjectStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Seção de Evolução do Projeto
  Widget _buildEvolutionSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.15),
                      AppTheme.primaryLight.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.trending_up_rounded, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Evolução do Projeto',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: _buildEvolutionChart(),
          ),
        ],
      ),
    );
  }

  // Seção de Histórico de Comparações
  Widget _buildComparisonsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor.withOpacity(0.15),
                      AppTheme.secondaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.history_rounded, color: AppTheme.secondaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Histórico de Comparações',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_comparisons.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.timeline_rounded, size: 64, color: AppTheme.textLightColor),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma comparação ainda',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicione uma nova imagem para começar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._comparisons.asMap().entries.map((entry) {
              final index = entry.key;
              final comparison = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - value)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildComparisonCard(comparison),
                      ),
                    ),
                  );
                },
              );
            }),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: AppTheme.subtleShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.15),
                                AppTheme.primaryLight.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.place_rounded, color: AppTheme.primaryColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comparison.pontoObra,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.construction_rounded, size: 16, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 6),
                        Text(
                          comparison.etapaObra,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${comparison.evolutionPercentage?.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textLightColor),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(comparison.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLightColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mensagem destacada sobre a evolução
          if (comparison.evolutionPercentage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: comparison.evolutionPercentage! > 50
                      ? [
                          AppTheme.successColor.withOpacity(0.15),
                          AppTheme.successColor.withOpacity(0.08),
                        ]
                      : comparison.evolutionPercentage! > 25
                          ? [
                              AppTheme.warningColor.withOpacity(0.15),
                              AppTheme.warningColor.withOpacity(0.08),
                            ]
                          : [
                              AppTheme.primaryColor.withOpacity(0.15),
                              AppTheme.primaryColor.withOpacity(0.08),
                            ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: comparison.evolutionPercentage! > 50
                      ? AppTheme.successColor.withOpacity(0.3)
                      : comparison.evolutionPercentage! > 25
                          ? AppTheme.warningColor.withOpacity(0.3)
                          : AppTheme.primaryColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: comparison.evolutionPercentage! > 50
                          ? AppTheme.successColor.withOpacity(0.2)
                          : comparison.evolutionPercentage! > 25
                              ? AppTheme.warningColor.withOpacity(0.2)
                              : AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: comparison.evolutionPercentage! > 50
                          ? AppTheme.successColor
                          : comparison.evolutionPercentage! > 25
                              ? AppTheme.warningColor
                              : AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A obra evoluiu ${comparison.evolutionPercentage!.toStringAsFixed(1)}% desde a imagem base!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: comparison.evolutionPercentage! > 50
                            ? AppTheme.successColor
                            : comparison.evolutionPercentage! > 25
                                ? AppTheme.warningColor
                                : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Base',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SafeImage(
                          imageUrl: comparison.baseImageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Comparada',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SafeImage(
                          imageUrl: comparison.comparedImageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

