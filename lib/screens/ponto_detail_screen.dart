import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/ponto_obra.dart';
import '../models/image_comparison.dart';
import '../services/ponto_obra_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/registro_obra_service.dart';
import '../services/ai_comparison_service.dart';
import '../utils/app_theme.dart';
import '../widgets/safe_image.dart';
import '../widgets/modern_card.dart';
import '../widgets/skeleton_loader.dart';
import 'report_screen.dart';
import '../providers/auth_provider.dart';

class PontoDetailScreen extends StatefulWidget {
  final String projectId;
  final String pontoId;

  const PontoDetailScreen({
    super.key,
    required this.projectId,
    required this.pontoId,
  });

  @override
  State<PontoDetailScreen> createState() => _PontoDetailScreenState();
}

class _PontoDetailScreenState extends State<PontoDetailScreen> {
  PontoObra? _ponto;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await PontoObraService.getPonto(projectId: widget.projectId, pontoId: widget.pontoId);
      if (mounted) setState(() => _ponto = p);
    } catch (_) {
      // noop
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _insertRealPhotoAndAnalyze() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      File? imageFile;
      Uint8List? imageBytes;
      String? fileName;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null) {
        setState(() => _uploading = false);
        return;
      }
      if (kIsWeb) {
        imageBytes = result.files.single.bytes;
        fileName = result.files.single.name;
      } else {
        if (result.files.single.path != null) {
          imageFile = File(result.files.single.path!);
          fileName = result.files.single.name;
        }
      }

      // Upload real
      String realUrl;
      if (kIsWeb && imageBytes != null) {
        realUrl = await FirebaseStorageService.uploadRegistroImageBytes(
          bytes: imageBytes,
          userId: user.uid,
          fileName: fileName,
        );
      } else if (imageFile != null) {
        realUrl = await FirebaseStorageService.uploadRegistroImage(
          imageFile: imageFile,
          userId: user.uid,
        );
      } else {
        throw Exception('Imagem inválida');
      }

      // Criar registro
      final registro = RegistroObraService.createRegistro(
        userId: user.uid,
        imageUrl: realUrl,
        pontoObra: _ponto?.name ?? 'Ponto',
        etapaObra: 'Execução',
        projectId: widget.projectId,
        timestamp: DateTime.now(),
      );
      await RegistroObraService.saveRegistro(registro);

      // Comparar com ideal
      await AIComparisonService.compareWithIdeal(
        projectId: widget.projectId,
        pontoId: widget.pontoId,
        registroId: registro.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Local'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _insertRealPhotoAndAnalyze,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Icon(Icons.add_a_photo),
        label: const Text('Inserir Foto Real'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _loading
          ? Container(
              decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
              child: const Center(child: CircularProgressIndicator()),
            )
          : (_ponto == null)
              ? Container(
                  decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
                  child: const Center(child: Text('Ponto não encontrado')),
                )
              : Container(
                  decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Ideal - Modernizado
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ModernCard(
                          padding: EdgeInsets.zero,
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
                                    child: Icon(Icons.location_on, color: AppTheme.primaryColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _ponto!.name,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: (_ponto!.idealImageUrl != null && _ponto!.idealImageUrl!.isNotEmpty)
                                    ? SafeImage(
                                        imageUrl: _ponto!.idealImageUrl!,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(16),
                                      )
                                    : Container(
                                        height: 220,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Sem imagem ideal',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo, size: 16, color: AppTheme.secondaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Foto Ideal (Fim da Obra)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.history, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Últimas Comparações',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<List<ImageComparison>>(
                          stream: AIComparisonService.getComparisonsByProjectAndPontoStream(
                            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                            projectId: widget.projectId,
                            pontoId: widget.pontoId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: 3,
                                itemBuilder: (_, __) => const ComparisonCardSkeleton(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Erro ao carregar comparações',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final items = snapshot.data ?? [];
                            if (items.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.compare_arrows, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhuma comparação ainda',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Adicione uma foto real para começar a análise',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final c = items[index];
                                return _buildComparisonCard(c);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildComparisonCard(ImageComparison comparison) {
    final isCompleted = comparison.status == ComparisonStatus.completed;
    final isProcessing = comparison.status == ComparisonStatus.processing;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (comparison.status) {
      case ComparisonStatus.completed:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'Concluída';
        break;
      case ComparisonStatus.processing:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Analisando...';
        break;
      case ComparisonStatus.pending:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        statusText = 'Pendente';
        break;
      case ComparisonStatus.error:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        statusText = 'Erro';
        break;
    }

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: isCompleted
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportScreen(comparisonId: comparison.id),
                ),
              );
            }
          : null,
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: comparison.comparedImageUrl.isNotEmpty
                ? SafeImage(
                    imageUrl: comparison.comparedImageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey[400]),
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isProcessing)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            )
                          else
                            Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (comparison.evolutionPercentage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${comparison.evolutionPercentage!.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comparison.etapaObra,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(comparison.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}


