import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/registro_obra.dart';
import '../models/image_comparison.dart';
import '../models/project.dart';
import '../services/ai_comparison_service.dart';
import '../services/registro_obra_service.dart';
import '../services/image_service.dart';
import '../services/project_service.dart';
import '../services/firebase_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_detail_screen.dart';
import '../widgets/comparison_result_widget.dart';
import '../widgets/safe_image.dart';
import '../utils/app_theme.dart';

class ImageComparisonScreen extends StatefulWidget {
  final String? pontoObra;
  final String? projectId;

  const ImageComparisonScreen({
    super.key,
    this.pontoObra,
    this.projectId,
  });

  @override
  State<ImageComparisonScreen> createState() => _ImageComparisonScreenState();
}

class _ImageComparisonScreenState extends State<ImageComparisonScreen> {
  // Imagens selecionadas do computador
  File? _baseImageFile;
  File? _comparedImageFile;
  Uint8List? _baseImageBytes; // Para web
  Uint8List? _comparedImageBytes; // Para web
  
  // URLs após upload
  String? _baseImageUrl;
  String? _comparedImageUrl;
  
  // Dados do registro
  String _pontoObra = '';
  String _etapaObra = '';
  final TextEditingController _pontoController = TextEditingController();
  final TextEditingController _etapaController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isComparing = false;
  String? _comparisonId;
  ImageComparison? _currentComparison;
  
  // IDs dos registros criados
  String? _baseRegistroId;
  String? _comparedRegistroId;

  @override
  void initState() {
    super.initState();
    _pontoObra = widget.pontoObra ?? '';
    _etapaObra = '';
    _pontoController.text = _pontoObra;
  }

  @override
  void dispose() {
    _pontoController.dispose();
    _etapaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isBase) async {
    try {
      File? imageFile;
      Uint8List? imageBytes;

      // Usar file_picker para abrir explorador de arquivos (funciona em web e desktop)
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        if (kIsWeb) {
          // Web: usar bytes diretamente
          if (result.files.single.bytes != null) {
            imageBytes = result.files.single.bytes;
          } else if (result.files.single.path != null) {
            // Fallback: se tiver path, tentar ler
            final XFile xFile = XFile(result.files.single.path!);
            imageBytes = await xFile.readAsBytes();
          }
        } else {
          // Mobile/Desktop: usar File
          if (result.files.single.path != null) {
            imageFile = File(result.files.single.path!);
          }
        }
      }

      if (mounted) {
        setState(() {
          if (isBase) {
            _baseImageFile = imageFile;
            _baseImageBytes = imageBytes;
            _baseImageUrl = null; // Reset URL ao selecionar nova imagem
          } else {
            _comparedImageFile = imageFile;
            _comparedImageBytes = imageBytes;
            _comparedImageUrl = null; // Reset URL ao selecionar nova imagem
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _removeImage(bool isBase) async {
    if (mounted) {
      setState(() {
        if (isBase) {
          _baseImageFile = null;
          _baseImageBytes = null;
          _baseImageUrl = null;
          _baseRegistroId = null;
        } else {
          _comparedImageFile = null;
          _comparedImageBytes = null;
          _comparedImageUrl = null;
          _comparedRegistroId = null;
        }
      });
    }
  }

  Future<void> _uploadAndCompare() async {
    // Validar campos
    if (_pontoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o ponto da obra')),
      );
      return;
    }

    if (_etapaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a etapa da obra')),
      );
      return;
    }

    if ((_baseImageFile == null && _baseImageBytes == null) ||
        (_comparedImageFile == null && _comparedImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione duas imagens para comparar')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isComparing = false;
      _pontoObra = _pontoController.text.trim();
      _etapaObra = _etapaController.text.trim();
    });

    try {
      // Upload das imagens
      String? baseUrl;
      String? comparedUrl;

      // Upload imagem base
      if (kIsWeb && _baseImageBytes != null) {
        baseUrl = await FirebaseStorageService.uploadRegistroImageBytes(
          bytes: _baseImageBytes!,
          userId: user.uid,
        );
      } else if (_baseImageFile != null) {
        baseUrl = await FirebaseStorageService.uploadRegistroImage(
          imageFile: _baseImageFile!,
          userId: user.uid,
        );
      }

      // Upload imagem comparada
      if (kIsWeb && _comparedImageBytes != null) {
        comparedUrl = await FirebaseStorageService.uploadRegistroImageBytes(
          bytes: _comparedImageBytes!,
          userId: user.uid,
        );
      } else if (_comparedImageFile != null) {
        comparedUrl = await FirebaseStorageService.uploadRegistroImage(
          imageFile: _comparedImageFile!,
          userId: user.uid,
        );
      }

      if (baseUrl == null || comparedUrl == null) {
        throw Exception('Erro ao fazer upload das imagens');
      }

      setState(() {
        _baseImageUrl = baseUrl;
        _comparedImageUrl = comparedUrl;
      });

      // Criar registros das obras
      final baseRegistro = RegistroObraService.createRegistro(
        userId: user.uid,
        imageUrl: baseUrl,
        pontoObra: _pontoObra,
        etapaObra: _etapaObra,
        projectId: widget.projectId,
        timestamp: DateTime.now().subtract(const Duration(days: 1)), // Imagem antiga
      );

      final comparedRegistro = RegistroObraService.createRegistro(
        userId: user.uid,
        imageUrl: comparedUrl,
        pontoObra: _pontoObra,
        etapaObra: _etapaObra,
        projectId: widget.projectId,
        timestamp: DateTime.now(), // Imagem nova
      );

      // Salvar registros no Firestore
      await RegistroObraService.saveRegistro(baseRegistro);
      await RegistroObraService.saveRegistro(comparedRegistro);

      setState(() {
        _baseRegistroId = baseRegistro.id;
        _comparedRegistroId = comparedRegistro.id;
        _isUploading = false;
        _isComparing = true;
      });

      // Comparar imagens
      final comparisonId = await AIComparisonService.compareImages(
        baseRegistroId: baseRegistro.id,
        comparedRegistroId: comparedRegistro.id,
      );

      setState(() {
        _comparisonId = comparisonId;
      });

      // Escutar atualizações da comparação
      _listenToComparison(comparisonId);

    } catch (e) {
      setState(() {
        _isUploading = false;
        _isComparing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _listenToComparison(String comparisonId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    AIComparisonService.getComparisonsStream(user.uid).listen((comparisons) {
      final comparison = comparisons.firstWhere(
        (c) => c.id == comparisonId,
        orElse: () => comparisons.isNotEmpty ? comparisons.first : ImageComparison(
          id: comparisonId,
          userId: user.uid,
          pontoObra: _pontoObra,
          etapaObra: _etapaObra,
          baseImageUrl: _baseImageUrl ?? '',
          comparedImageUrl: _comparedImageUrl ?? '',
          baseRegistroId: _baseRegistroId ?? '',
          comparedRegistroId: _comparedRegistroId ?? '',
          status: ComparisonStatus.pending,
          timestamp: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _currentComparison = comparison.id == comparisonId ? comparison : null;
          // Atualizar URLs das imagens para exibição
          if (_currentComparison != null) {
            _baseImageUrl = _currentComparison!.baseImageUrl;
            _comparedImageUrl = _currentComparison!.comparedImageUrl;
          }
          if (comparison.status == ComparisonStatus.completed ||
              comparison.status == ComparisonStatus.error) {
            _isComparing = false;
            
            // Mostrar mensagem de sucesso
            if (comparison.status == ComparisonStatus.completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Comparação concluída! Evolução: ${comparison.evolutionPercentage?.toStringAsFixed(1) ?? 0}%'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                ),
              );
            } else if (comparison.status == ComparisonStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro na comparação: ${comparison.errorMessage ?? "Erro desconhecido"}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        });
      }
    });
  }

  Future<void> _saveComparisonToProject(ImageComparison comparison) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      Project? project;
      
      // Se tem projectId, buscar o projeto existente
      if (widget.projectId != null) {
        project = await ProjectService.getProject(widget.projectId!);
      }

      // Se não existe projeto, criar um novo baseado na comparação
      if (project == null) {
        project = ProjectService.createProject(
          userId: user.uid,
          name: 'Obra - ${comparison.pontoObra}',
          description: 'Obra criada a partir de comparação de imagens',
          location: comparison.pontoObra,
          startDate: comparison.timestamp,
          status: ProjectStatus.inProgress,
          imageUrls: [comparison.baseImageUrl, comparison.comparedImageUrl],
          baseImageUrl: comparison.baseImageUrl,
          baseImageRegistroId: comparison.baseRegistroId,
        );
        
        await ProjectService.saveProject(project);
        print('✅ Nova obra criada: ${project.id}');
      } else {
        // Se já existe, atualizar com imagem base se necessário
        if (project.baseImageUrl == null || project.baseImageRegistroId == null) {
          final updatedProject = project.copyWith(
            baseImageUrl: comparison.baseImageUrl,
            baseImageRegistroId: comparison.baseRegistroId,
            imageUrls: [
              ...project.imageUrls,
              comparison.baseImageUrl,
              comparison.comparedImageUrl,
            ],
          );
          await ProjectService.updateProject(updatedProject);
          project = updatedProject;
        }
      }

      // Atualizar a comparação com o projectId se não tiver
      if (comparison.projectId != project.id) {
        await FirebaseFirestore.instance
            .collection('image_comparisons')
            .doc(comparison.id)
            .update({'projectId': project.id});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comparação salva na obra "${project.name}" com sucesso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Ver Obra',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(project: project!),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Erro ao salvar comparação no projeto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comparação de Imagens',
          style: TextStyle(
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campos de informação
            _buildInfoFields(),
            const SizedBox(height: 24),

            // Seleção de imagens
            _buildImageSelection(),
            const SizedBox(height: 24),

            // Botão de comparar
            ElevatedButton(
              onPressed: (_isUploading || _isComparing) ? null : _uploadAndCompare,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.lightTheme.primaryColor,
              ),
              child: _isUploading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Fazendo upload...'),
                      ],
                    )
                  : _isComparing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processando...'),
                          ],
                        )
                      : const Text(
                          'Comparar Imagens',
                          style: TextStyle(fontSize: 16),
                        ),
            ),
            const SizedBox(height: 24),

                // Resultados
                if (_currentComparison != null)
                  ComparisonResultWidget(
                    comparison: _currentComparison!,
                    showSaveButton: _currentComparison!.status == ComparisonStatus.completed,
                    onSaveToProject: () => _saveComparisonToProject(_currentComparison!),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações da Obra',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pontoController,
          decoration: const InputDecoration(
            labelText: 'Ponto da Obra',
            hintText: 'Ex: Torre A, Bloco 1',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          enabled: widget.pontoObra == null, // Desabilitar se já veio preenchido
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _etapaController,
          decoration: const InputDecoration(
            labelText: 'Etapa da Obra',
            hintText: 'Ex: Fundação, Acabamento',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.construction),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione as imagens para comparar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildImageSelector(
                title: 'Imagem Base (Antiga)',
                imageFile: _baseImageFile,
                imageBytes: _baseImageBytes,
                imageUrl: _baseImageUrl,
                onPick: () => _pickImage(true),
                onRemove: () => _removeImage(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImageSelector(
                title: 'Imagem Comparada (Nova)',
                imageFile: _comparedImageFile,
                imageBytes: _comparedImageBytes,
                imageUrl: _comparedImageUrl,
                onPick: () => _pickImage(false),
                onRemove: () => _removeImage(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageSelector({
    required String title,
    required File? imageFile,
    required Uint8List? imageBytes,
    required String? imageUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final hasImage = imageFile != null || imageBytes != null || imageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: !hasImage
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Nenhuma imagem selecionada'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Escolher Arquivo'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: // Priorizar arquivo/bytes locais sobre URL do Storage (evita CORS)
                          kIsWeb && imageBytes != null
                              ? Image.memory(
                                  imageBytes!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : imageFile != null
                                  ? Image.file(
                                      imageFile!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : imageUrl != null
                                      ? SafeImage(
                                          imageUrl: imageUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(8),
                                        )
                                      : const SizedBox(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: onRemove,
                          tooltip: 'Remover imagem',
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
