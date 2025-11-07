import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Widget que desenha sobreposições visuais sobre uma imagem baseado nos dados do Gemini
/// Destaca problemas de segurança, materiais faltantes e discrepâncias
class AnnotatedImageOverlay extends StatefulWidget {
  final String imageUrl;
  final Map<String, dynamic>? geminiData;
  final double width;
  final double height;

  const AnnotatedImageOverlay({
    super.key,
    required this.imageUrl,
    this.geminiData,
    required this.width,
    required this.height,
  });

  @override
  State<AnnotatedImageOverlay> createState() => _AnnotatedImageOverlayState();
}

class _AnnotatedImageOverlayState extends State<AnnotatedImageOverlay> {
  ui.Image? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final imageProvider = NetworkImage(widget.imageUrl);
      final completer = ImageStreamListener((ImageInfo info, bool _) {
        setState(() {
          _image = info.image;
          _loading = false;
        });
      });
      imageProvider.resolve(const ImageConfiguration()).addListener(completer);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Imagem de fundo
          Image.network(
            widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                _loadImage(); // Carregar imagem para o painter
                return child;
              }
              return Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.grey),
                ),
              );
            },
          ),
          // Sobreposição com anotações (se houver dados do Gemini)
          if (widget.geminiData != null && _image != null)
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _AnnotationPainter(
                image: _image!,
                geminiData: widget.geminiData!,
                imageUrl: widget.imageUrl,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final ui.Image image;
  final Map<String, dynamic> geminiData;
  final String imageUrl;

  _AnnotationPainter({
    required this.image,
    required this.geminiData,
    required this.imageUrl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Não desenhar a imagem aqui, ela já está no Stack
    // Apenas desenhar as sobreposições visuais dos elementos faltantes

    // Extrair dados do Gemini
    final missingMaterials = geminiData['missingMaterials'] as List<dynamic>? ?? [];

    if (missingMaterials.isEmpty) return;

    // Desenhar sobreposições dos elementos faltantes
    for (var material in missingMaterials) {
      final element = material['element'] as String? ?? 'Elemento';
      final type = material['type'] as String? ?? 'structural';
      final position = material['position'] as Map<String, dynamic>?;
      
      if (position != null) {
        // Desenhar elemento faltante na posição especificada
        _drawMissingElement(
          canvas: canvas,
          size: size,
          element: element,
          type: type,
          position: position,
        );
      }
    }
  }

  void _drawMissingElement({
    required Canvas canvas,
    required Size size,
    required String element,
    required String type,
    required Map<String, dynamic> position,
  }) {
    // Converter porcentagens para coordenadas reais
    final x = (position['x'] as num? ?? 0).toDouble() / 100 * size.width;
    final y = (position['y'] as num? ?? 0).toDouble() / 100 * size.height;
    final width = (position['width'] as num? ?? 20).toDouble() / 100 * size.width;
    final height = (position['height'] as num? ?? 20).toDouble() / 100 * size.height;

    // Cor baseada no tipo de elemento
    final color = _getElementColor(type);
    
    // Desenhar forma baseada no tipo
    switch (type) {
      case 'roof':
        _drawRoof(canvas, size, x, y, width, height, color, element);
        break;
      case 'wall':
        _drawWall(canvas, size, x, y, width, height, color, element);
        break;
      case 'column':
        _drawColumn(canvas, size, x, y, width, height, color, element);
        break;
      case 'beam':
        _drawBeam(canvas, size, x, y, width, height, color, element);
        break;
      case 'door':
        _drawDoor(canvas, size, x, y, width, height, color, element);
        break;
      case 'window':
        _drawWindow(canvas, size, x, y, width, height, color, element);
        break;
      default:
        _drawGenericElement(canvas, size, x, y, width, height, color, element);
    }
  }

  void _drawRoof(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar telhado como triângulo/polígono
    final path = Path();
    path.moveTo(x, y + height);
    path.lineTo(x + width / 2, y);
    path.lineTo(x + width, y + height);
    path.close();
    
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Padrão de telhas (linhas diagonais)
    final patternPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 5; i++) {
      final offset = (width / 5) * i;
      canvas.drawLine(
        Offset(x + offset, y + height),
        Offset(x + width / 2, y + (height / 5) * i),
        patternPaint,
      );
    }
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 20, label, color);
  }

  void _drawWall(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar parede como retângulo
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(4),
    );
    
    final paint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    // Padrão de tijolos (linhas horizontais)
    final patternPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 1; i < 4; i++) {
      final lineY = y + (height / 4) * i;
      canvas.drawLine(
        Offset(x, lineY),
        Offset(x + width, lineY),
        patternPaint,
      );
    }
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 15, label, color);
  }

  void _drawColumn(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar pilar como retângulo vertical
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(8),
    );
    
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 15, label, color);
  }

  void _drawBeam(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar viga como retângulo horizontal
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(4),
    );
    
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 15, label, color);
  }

  void _drawDoor(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar porta como retângulo com arco no topo
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(8),
    );
    
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    // Maçaneta
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x + width - 10, y + height / 2), 4, handlePaint);
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 15, label, color);
  }

  void _drawWindow(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar janela como retângulo com divisões
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(6),
    );
    
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    // Divisões (cruzeta)
    final divisionPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(x + width / 2, y),
      Offset(x + width / 2, y + height),
      divisionPaint,
    );
    canvas.drawLine(
      Offset(x, y + height / 2),
      Offset(x + width, y + height / 2),
      divisionPaint,
    );
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 15, label, color);
  }

  void _drawGenericElement(Canvas canvas, Size size, double x, double y, double width, double height, Color color, String label) {
    // Desenhar elemento genérico como retângulo
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(8),
    );
    
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rect, borderPaint);
    
    // Padrão diagonal
    final patternPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(x, y),
      Offset(x + width, y + height),
      patternPaint,
    );
    canvas.drawLine(
      Offset(x + width, y),
      Offset(x, y + height),
      patternPaint,
    );
    
    // Label
    _drawLabel(canvas, x + width / 2, y - 15, label, color);
  }

  void _drawLabel(Canvas canvas, double x, double y, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y),
    );
  }

  Color _getElementColor(String type) {
    switch (type) {
      case 'roof':
        return Colors.blue.shade400; // Azul para telhado
      case 'wall':
        return Colors.orange.shade400; // Laranja para parede
      case 'column':
        return Colors.red.shade400; // Vermelho para pilar
      case 'beam':
        return Colors.purple.shade400; // Roxo para viga
      case 'door':
        return Colors.green.shade400; // Verde para porta
      case 'window':
        return Colors.cyan.shade400; // Ciano para janela
      case 'finishing':
        return Colors.amber.shade400; // Amarelo para acabamento
      case 'installation':
        return Colors.teal.shade400; // Verde-azulado para instalação
      default:
        return Colors.grey.shade400; // Cinza para genérico
    }
  }


  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.amber.shade600;
      case 'low':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

