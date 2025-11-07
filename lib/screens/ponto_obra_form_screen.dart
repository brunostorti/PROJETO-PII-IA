import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/ponto_obra_service.dart';
import '../utils/app_theme.dart';

class PontoObraFormScreen extends StatefulWidget {
  final String projectId;

  const PontoObraFormScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<PontoObraFormScreen> createState() => _PontoObraFormScreenState();
}

class _PontoObraFormScreenState extends State<PontoObraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  File? _idealFile;
  Uint8List? _idealBytes;
  String? _idealFileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIdeal() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null) return;
    if (kIsWeb) {
      _idealBytes = result.files.single.bytes;
      _idealFileName = result.files.single.name;
    } else {
      if (result.files.single.path != null) {
        _idealFile = File(result.files.single.path!);
        _idealFileName = result.files.single.name;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idealFile == null && _idealBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a imagem ideal do ponto.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final ponto = await PontoObraService.createPonto(
        projectId: widget.projectId,
        name: _nameController.text.trim(),
      );

      String idealUrl;
      if (kIsWeb && _idealBytes != null) {
        idealUrl = await PontoObraService.uploadIdealImageBytes(
          projectId: widget.projectId,
          pontoId: ponto.id,
          bytes: _idealBytes!,
          fileName: _idealFileName,
        );
      } else if (_idealFile != null) {
        idealUrl = await PontoObraService.uploadIdealImageFile(
          projectId: widget.projectId,
          pontoId: ponto.id,
          imageFile: _idealFile!,
        );
      } else {
        throw Exception('Imagem ideal inválida');
      }

      await PontoObraService.updatePonto(
        ponto.copyWith(
          idealImageUrl: idealUrl,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar ponto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Ponto da Obra'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Ponto',
                  hintText: 'Ex: Torre A - Hall',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome do ponto' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Imagem Ideal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickIdeal,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: _buildIdealPreview(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Salvar Ponto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdealPreview() {
    if (kIsWeb && _idealBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _idealBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (_idealFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _idealFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Toque para selecionar a imagem ideal'),
        ],
      ),
    );
  }
}



