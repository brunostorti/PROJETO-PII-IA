import 'dart:html' as html show Blob, Url;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafeImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<SafeImage> createState() => _SafeImageState();
}

class _SafeImageState extends State<SafeImage> {
  // Estado simplificado - não precisa mais de lógica complexa
  // Para Firebase Storage, sempre usar _FirebaseStorageImage que usa blob

  @override
  Widget build(BuildContext context) {
    // Para Firebase Storage, SEMPRE usar o widget de blob (solução que funcionou antes)
    if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
      return _FirebaseStorageImage(
        url: widget.imageUrl, // Usar URL original diretamente
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: widget.placeholder,
        errorWidget: widget.errorWidget,
        borderRadius: widget.borderRadius,
      );
    }
    
    // Para outras URLs, usar Image.network normal
    Widget imageWidget = Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: widget.borderRadius,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Erro ao carregar imagem: $error');
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: widget.borderRadius,
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: (widget.height != null && widget.height! < 60) ? widget.height! * 0.4 : 40,
                color: Colors.grey[400],
              ),
            );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

// Widget customizado para carregar imagens do Firebase Storage via blob (evita CORS)
// Esta é a solução que funcionou antes - sempre usar getData() e converter para blob
class _FirebaseStorageImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const _FirebaseStorageImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<_FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

class _FirebaseStorageImageState extends State<_FirebaseStorageImage> {
  String? _blobUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageAsBlob();
  }

  @override
  void didUpdateWidget(_FirebaseStorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a URL mudou, recarregar
    if (oldWidget.url != widget.url) {
      // Limpar blob URL antigo
      if (_blobUrl != null && kIsWeb) {
        html.Url.revokeObjectUrl(_blobUrl!);
      }
      // Resetar estado e recarregar
      setState(() {
        _blobUrl = null;
        _isLoading = true;
        _hasError = false;
      });
      _loadImageAsBlob();
    }
  }

  @override
  void dispose() {
    // Limpar blob URL para liberar memória
    if (_blobUrl != null && kIsWeb) {
      html.Url.revokeObjectUrl(_blobUrl!);
    }
    super.dispose();
  }

  Future<void> _loadImageAsBlob() async {
    if (!kIsWeb) {
      // Mobile/Desktop: usar Image.network normal
      if (mounted) {
        setState(() {
          _isLoading = false;
          _blobUrl = widget.url; // Usar URL diretamente
        });
      }
      return;
    }

    // Validar URL
    if (widget.url.isEmpty) {
      print('⚠️ URL vazia');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      return;
    }
    
    // Se não for Firebase Storage, usar URL diretamente
    if (!widget.url.contains('firebasestorage.googleapis.com')) {
      print('⚠️ URL não é do Firebase Storage, usando diretamente: ${widget.url.substring(0, 50)}...');
      if (mounted) {
        setState(() {
          _blobUrl = widget.url;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      print('📥 Iniciando carregamento de imagem: ${widget.url.substring(0, 60)}...');
      
      // Obter referência do arquivo a partir da URL
      final ref = FirebaseStorage.instance.refFromURL(widget.url);
      
      print('📥 Referência obtida, buscando dados...');
      
      // SEMPRE usar getData() do Firebase Storage SDK - contorna CORS completamente!
      // Esta é a solução que funcionou antes
      final bytes = await ref.getData().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Timeout ao carregar imagem');
          throw TimeoutException('Timeout ao carregar imagem', const Duration(seconds: 30));
        },
      );

      if (bytes != null && bytes.isNotEmpty) {
        print('✅ Bytes recebidos: ${bytes.length} bytes');
        
        // Converter bytes para blob
        final blob = html.Blob([bytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        print('✅ Blob URL criado com sucesso: ${blobUrl.substring(0, 30)}...');
        
        if (mounted) {
          setState(() {
            _blobUrl = blobUrl;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        throw Exception('Bytes vazios ou nulos');
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar imagem como blob: $e');
      print('❌ URL: ${widget.url}');
      print('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      Widget placeholder = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: widget.borderRadius,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
      
      if (widget.borderRadius != null) {
        return ClipRRect(
          borderRadius: widget.borderRadius!,
          child: placeholder,
        );
      }
      return placeholder;
    }

    if (_hasError || _blobUrl == null) {
      // Fallback: tentar exibir diretamente a URL (em alguns ambientes o download URL funciona sem CORS)
      try {
        Widget direct = Image.network(
          widget.url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            final errorWidget = widget.errorWidget ??
                Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: widget.borderRadius,
                  ),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: (widget.height != null && widget.height! < 60) ? widget.height! * 0.4 : 40,
                    color: Colors.grey[400],
                  ),
                );
            if (widget.borderRadius != null) {
              return ClipRRect(borderRadius: widget.borderRadius!, child: errorWidget);
            }
            return errorWidget;
          },
        );
        if (widget.borderRadius != null) {
          return ClipRRect(borderRadius: widget.borderRadius!, child: direct);
        }
        return direct;
      } catch (_) {
        Widget errorWidget = widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: widget.borderRadius,
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: (widget.height != null && widget.height! < 60) ? widget.height! * 0.4 : 40,
                color: Colors.grey[400],
              ),
            );
        if (widget.borderRadius != null) {
          return ClipRRect(borderRadius: widget.borderRadius!, child: errorWidget);
        }
        return errorWidget;
      }
    }

    // Usar Image.network com blob URL (não precisa de CORS)
    Widget image = Image.network(
      _blobUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Erro ao carregar blob URL: $error');
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: widget.borderRadius,
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: (widget.height != null && widget.height! < 60) ? widget.height! * 0.4 : 40,
                color: Colors.grey[400],
              ),
            );
      },
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }
    return image;
  }
}
