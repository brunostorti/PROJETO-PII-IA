import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/image_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../widgets/project_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import 'registro_obra_form_screen.dart';
import 'registros_timeline_screen.dart';
import 'project_form_screen.dart';
import 'auth_screen.dart';
import 'image_comparison_screen.dart';
import 'evolution_history_screen.dart';
import 'project_detail_screen.dart';
import '../models/project.dart';
import '../services/project_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final projectProvider = context.read<ProjectProvider>();
      
      if (authProvider.isLoggedIn && authProvider.userId != null) {
        projectProvider.initialize(authProvider.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.dashboardTitle),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAdmin) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Nova Obra',
                icon: const Icon(Icons.add_business_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectFormScreen(),
                    ),
                  );
                },
              );
            },
          ),
          // Botão de logout - visível para todos os usuários
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Menu do usuário',
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'user_info',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userEmail ?? 'Usuário',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (authProvider.isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Administrador',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Usuário',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppTheme.errorColor),
                        SizedBox(width: 12),
                        Text('Sair'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.surfaceGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              if (projectProvider.isLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (_, __) => const ProjectCardSkeleton(),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final hPad = constraints.maxWidth < 420 ? 12.0 : 16.0;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 0),
                        child: _DashboardHeader(projectProvider: projectProvider),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: projectProvider.projects.isEmpty
                            ? Center(
                                child: EmptyState(
                                  icon: Icons.construction,
                                  title: AppConstants.noProjectsMessage,
                                  message: AppConstants.addProjectMessage,
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(hPad),
                                itemCount: projectProvider.projects.length,
                                itemBuilder: (context, index) {
                                  final project = projectProvider.projects[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 300 + (index * 100)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Padding(
                                            padding: EdgeInsets.only(bottom: hPad),
                                            child: ProjectCard(
                                              project: project,
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                        ProjectDetailScreen(project: project),
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
                                              onDelete: () => _confirmDeleteProject(context, project),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn || !auth.isAdmin) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProjectFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_business),
            label: const Text('Nova Obra'),
            backgroundColor: AppTheme.primaryLight,
          );
        },
      ),
    );
  }

  

  Future<void> _confirmDeleteProject(BuildContext context, Project project) async {
    final authProvider = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();

    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para excluir uma obra.')),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir a obra "${project.name}"?\n\n'
            'Esta ação irá deletar:\n'
            '• A obra e todas as suas informações\n'
            '• Todas as comparações de imagens associadas\n'
            '• Todos os registros de obra\n'
            '• Todas as imagens armazenadas\n\n'
            'Esta ação é irreversível!',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excluindo obra "${project.name}"...'),
            duration: const Duration(seconds: 2),
          ),
        );

        final success = await ProjectService.deleteProject(project.id, authProvider.userId!);
        
        if (success) {
          // Recarregar lista de projetos
          projectProvider.initialize(authProvider.userId!);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Obra "${project.name}" excluída com sucesso!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('Falha ao excluir obra');
        }
      } catch (e) {
        print('Erro ao excluir obra: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir obra: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _selectProjectAndCapture(BuildContext context) async {
    final projectProvider = context.read<ProjectProvider>();
    final projects = projectProvider.projects;
    if (projects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma obra cadastrada'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = projects[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.surfaceColor,
                leading: const Icon(Icons.home_work_outlined, color: AppTheme.primaryColor),
                title: Text(p.name),
                subtitle: Text(p.location),
                onTap: () => Navigator.of(context).pop(p.id),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;

    // Após escolher a obra, abrir escolha de fonte e encaminhar projectId
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Capturar Imagem'),
          content: const Text('Escolha como capturar a imagem da obra'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _captureImageForProject(context, ImageSource.camera, selected);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Câmera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _captureImageForProject(context, ImageSource.gallery, selected);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  const Text('Galeria'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Mostrar diálogo de confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final projectProvider = context.read<ProjectProvider>();
      
      // Limpar dados do projeto
      projectProvider.clearProjects();
      
      // Fazer logout
      final success = await authProvider.signOut();
      
      if (success && mounted) {
        // Redirecionar para tela de login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      } else if (mounted) {
        // Mostrar erro se houver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Erro ao fazer logout',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _captureImageForProject(BuildContext context, ImageSource source, String projectId) async {
    try {
      if (kIsWeb) {
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          final authProvider = context.read<AuthProvider>();
          if (authProvider.userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuário não autenticado'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            return;
          }

          final bytes = await pickedFile.readAsBytes();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RegistroObraFormScreen(
                imageBytes: bytes,
                imageFileName: pickedFile.name,
                projectId: projectId,
              ),
            ),
          );
        }
        return;
      }

      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await ImageService.takePhotoWithCamera();
      } else {
        imageFile = await ImageService.pickImageFromGallery();
      }

      if (imageFile != null && mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário não autenticado'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RegistroObraFormScreen(
              imageFile: imageFile!,
              projectId: projectId,
            ),
          ),
        );
      }
    } catch (e) {
      // log silencioso
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  final ProjectProvider projectProvider;
  const _DashboardHeader({required this.projectProvider});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatInfo(label: 'Ativas', value: projectProvider.activeProjects.toString(), color: AppTheme.primaryColor, icon: Icons.work_outline),
      _StatInfo(label: 'Concluídas', value: projectProvider.completedProjects.toString(), color: AppTheme.successColor, icon: Icons.verified_outlined),
      _StatInfo(label: 'Total', value: projectProvider.totalProjects.toString(), color: AppTheme.secondaryColor, icon: Icons.all_inbox_outlined),
    ];

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
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 360;
          final children = stats.map((s) => Expanded(child: _StatCard(info: s))).toList();
          return isTight
              ? Column(
                  children: [
                    Row(children: [children[0], const SizedBox(width: 10), children[1]]),
                    const SizedBox(height: 10),
                    Row(children: [children[2]]),
                  ],
                )
              : Row(children: children);
        },
      ),
    );
  }
}

class _StatInfo {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  _StatInfo({required this.label, required this.value, required this.color, required this.icon});
}

class _StatCard extends StatelessWidget {
  final _StatInfo info;
  const _StatCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: info.color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  info.color.withOpacity(0.2),
                  info.color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: info.color.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(info.icon, color: info.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: info.color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

