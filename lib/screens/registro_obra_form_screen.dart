import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../services/registro_obra_service.dart';
import '../services/firebase_storage_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class RegistroObraFormScreen extends StatefulWidget {
  final File? imageFile; // mobile/desktop
  final Uint8List? imageBytes; // web
  final String? imageFileName; // used for web upload content type/extension
  final String? projectId; // opcional, quando veio de uma obra específica

  const RegistroObraFormScreen({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.imageFileName,
    this.projectId,
  });

  @override
  State<RegistroObraFormScreen> createState() => _RegistroObraFormScreenState();
}

class _RegistroObraFormScreenState extends State<RegistroObraFormScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _pontoController = TextEditingController();
  final _etapaController = TextEditingController();

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  double? _accuracyMeters;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _initLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pontoController.dispose();
    _etapaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Registro'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.subtleBackgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 16 : 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildFormCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 24 : 36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 36),
              _buildImagePreview(),
              const SizedBox(height: 28),
              _buildFormFields(),
              const SizedBox(height: 36),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.organicGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.floatingShadow,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registro de Obra',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Preencha os detalhes da obra',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor,
            Colors.white.withOpacity(0.5),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: kIsWeb
            ? (widget.imageBytes != null
                ? Image.memory(
                    widget.imageBytes!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.05),
                          AppTheme.secondaryColor.withOpacity(0.03),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ))
            : (widget.imageFile != null
                ? Image.file(
                    widget.imageFile!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.05),
                          AppTheme.secondaryColor.withOpacity(0.03),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  )),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildPontoField(),
        const SizedBox(height: 20),
        _buildEtapaField(),
        const SizedBox(height: 12),
        _buildSuggestionChips(),
        const SizedBox(height: 20),
        _buildDateField(),
        const SizedBox(height: 20),
        _buildLocationInfo(),
      ],
    );
  }

  Widget _buildPontoField() {
    return TextFormField(
      controller: _pontoController,
      decoration: InputDecoration(
        labelText: 'Ponto da Obra',
        hintText: 'Ex: Ponto 1, Torre A, Bloco B...',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ponto da obra é obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildSuggestionChips() {
    final etapaSuggestions = ['Fundação', 'Estrutura', 'Alvenaria', 'Instalações', 'Acabamento'];
    final pontoSuggestions = ['Ponto 1', 'Ponto 2', 'Torre A', 'Bloco B'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sugestões',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...etapaSuggestions.map((e) => ChoiceChip(
                  label: Text(e),
                  selected: _etapaController.text.trim() == e,
                  onSelected: (_) => setState(() => _etapaController.text = e),
                )),
            const SizedBox(width: 12),
            ...pontoSuggestions.map((p) => InputChip(
                  label: Text(p),
                  onPressed: () => setState(() => _pontoController.text = p),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildEtapaField() {
    return TextFormField(
      controller: _etapaController,
      decoration: InputDecoration(
        labelText: 'Etapa da Obra',
        hintText: 'Ex: Fundação, Estrutura, Acabamento...',
        prefixIcon: const Icon(Icons.engineering_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Etapa da obra é obrigatória';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data e Hora do Registro',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.organicGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.floatingShadow,
              ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Salvar Registro',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId == null) {
      _showErrorSnackBar('Usuário não autenticado');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload da imagem para Firebase Storage
      String imageUrl;
      if (kIsWeb) {
        if (widget.imageBytes == null) {
          _showErrorSnackBar('Nenhuma imagem disponível para upload');
          return;
        }
        imageUrl = await FirebaseStorageService.uploadRegistroImageBytes(
          bytes: widget.imageBytes!,
          userId: authProvider.userId!,
          fileName: widget.imageFileName,
        );
      } else {
        if (widget.imageFile == null) {
          _showErrorSnackBar('Nenhuma imagem disponível para upload');
          return;
        }
        imageUrl = await FirebaseStorageService.uploadRegistroImage(
          imageFile: widget.imageFile!,
          userId: authProvider.userId!,
        );
      }

      // 2. Criar registro
      final registro = RegistroObraService.createRegistro(
        userId: authProvider.userId!,
        imageUrl: imageUrl,
        pontoObra: _pontoController.text.trim(),
        etapaObra: _etapaController.text.trim(),
        projectId: widget.projectId,
        createdByName: authProvider.userDisplayName,
        timestamp: _selectedDate,
        latitude: _latitude,
        longitude: _longitude,
        locationAccuracyMeters: _accuracyMeters,
      );

      // 3. Salvar no Firestore
      final success = await RegistroObraService.saveRegistro(registro);

      if (success) {
        _showSuccessSnackBar('Registro salvo com sucesso!');
        Navigator.of(context).pop(); // Volta para o dashboard
      } else {
        _showErrorSnackBar('Erro ao salvar registro');
      }
    } catch (e) {
      print('Erro ao salvar registro: $e');
      _showErrorSnackBar('Erro ao salvar registro: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return; // usuário negou
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _accuracyMeters = position.accuracy;
        });
      }
    } catch (e) {
      // Silencioso: localização é opcional
    }
  }

  Widget _buildLocationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _latitude != null && _longitude != null
                  ? 'Localização capturada: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)} (±${_accuracyMeters?.toStringAsFixed(1)} m)'
                  : 'Capturando localização... (opcional)'
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
