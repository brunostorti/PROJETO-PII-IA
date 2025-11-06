import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/registro_obra_service.dart';
import '../models/registro_obra.dart';
import '../utils/app_theme.dart';
import 'registro_obra_detail_screen.dart';
import '../services/image_service.dart';
import 'registro_obra_form_screen.dart';
import '../widgets/safe_image.dart';
import 'project_users_screen.dart';

class RegistrosTimelineScreen extends StatefulWidget {
  final String? projectId; // opcional: filtra por obra
  final String? projectName; // opcional: título contextual

  const RegistrosTimelineScreen({super.key, this.projectId, this.projectName});

  @override
  State<RegistrosTimelineScreen> createState() => _RegistrosTimelineScreenState();
}

class _RegistrosTimelineScreenState extends State<RegistrosTimelineScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _pontoController = TextEditingController();

  @override
  void dispose() {
    _pontoController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (range != null) {
      setState(() {
        _startDate = DateTime(range.start.year, range.start.month, range.start.day);
        _endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _pontoController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName == null ? 'Linha do Tempo' : 'Obra: ${widget.projectName}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Botão para gerenciar usuários (apenas admin e quando há projectId)
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (!authProvider.isAdmin || widget.projectId == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.people),
                tooltip: 'Gerenciar usuários do projeto',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectUsersScreen(
                        projectId: widget.projectId!,
                        projectName: widget.projectName ?? 'Projeto',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 0),
          Expanded(
            child: userId == null
                ? const Center(child: Text('Faça login para ver seus registros'))
                : Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final stream = (auth.isAdmin && widget.projectId != null)
                          ? RegistroObraService.getProjectRegistrosStreamFiltered(
                              widget.projectId!,
                              start: _startDate,
                              end: _endDate,
                              ponto: _pontoController.text.trim().isEmpty ? null : _pontoController.text.trim(),
                            )
                          : RegistroObraService.getRegistrosStreamFiltered(
                              userId,
                              start: _startDate,
                              end: _endDate,
                              ponto: _pontoController.text.trim().isEmpty ? null : _pontoController.text.trim(),
                              projectId: widget.projectId,
                            );

                      return StreamBuilder<List<RegistroObra>>(
                        stream: stream,
                        builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Erro ao carregar registros. Verifique sua conexão e permissões.'));
                      }
                      final registros = snapshot.data ?? [];
                      if (registros.isEmpty) {
                        return const Center(child: Text('Nenhum registro encontrado'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: registros.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = registros[index];
                          return _RegistroItem(
                            registro: r,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RegistroObraDetailScreen(registroId: r.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.projectId == null
          ? null
          : Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isLoggedIn) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () => _showImageSourceDialog(context),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Novo Registro'),
                  backgroundColor: AppTheme.primaryLight,
                );
              },
            ),
    );
  }

  Widget _buildFilters() {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pontoController,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por ponto',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                onSubmitted: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _startDate == null
                    ? 'Período'
                    : '${dateFmt.format(_startDate!)} - ${dateFmt.format(_endDate!)}',
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar filtros',
            ),
          ],
        ),
      ),
    );
  }
  
  void _showImageSourceDialog(BuildContext context) {
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
                _captureImage(context, ImageSource.camera);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Câmera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _captureImage(context, ImageSource.gallery);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_library, color: AppTheme.secondaryColor),
                  SizedBox(width: 8),
                  Text('Galeria'),
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

  Future<void> _captureImage(BuildContext context, ImageSource source) async {
    try {
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

      if (kIsWeb) {
        final picker = ImagePicker();
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          final bytes = await pickedFile.readAsBytes();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RegistroObraFormScreen(
                imageBytes: bytes,
                imageFileName: pickedFile.name,
                projectId: widget.projectId,
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegistroObraFormScreen(
              imageFile: imageFile!,
              projectId: widget.projectId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Erro ao capturar imagem (timeline): $e');
    }
  }
}

class _RegistroItem extends StatelessWidget {
  final RegistroObra registro;
  final VoidCallback onTap;
  const _RegistroItem({required this.registro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: registro.id,
              child: SafeImage(
                imageUrl: registro.imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      registro.pontoObra,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registro.etapaObra,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (registro.createdByName != null && registro.createdByName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              registro.createdByName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateFmt.format(registro.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


