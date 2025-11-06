import 'dart:html' as html show Blob, Url;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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
  String? _authenticatedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Inicializar como carregando - vamos obter URL autenticada
    _isLoading = true;
    _authenticatedUrl = null;
    
    // Carregar URL autenticada de forma assíncrona
    _loadAuthenticatedUrlAsync();
  }

  @override
  void didUpdateWidget(SafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a URL mudou, atualizar
    if (oldWidget.imageUrl != widget.imageUrl) {
      _authenticatedUrl = widget.imageUrl;
      _isLoading = false;
      _hasError = false;
      _loadAuthenticatedUrlAsync();
    }
  }

  // Método assíncrono que SEMPRE obtém URL autenticada para Firebase Storage
  void _loadAuthenticatedUrlAsync() {
    // Usar Future.microtask para garantir que não estamos no meio de um build
    Future.microtask(() async {
      if (!mounted) return;
      
      try {
        // Se a URL é do Firebase Storage, SEMPRE obter URL autenticada (com token)
        if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              // Obter referência do arquivo a partir da URL
              final ref = FirebaseStorage.instance.refFromURL(widget.imageUrl);
              
              // SEMPRE obter nova URL com token de autenticação (válido por 1 hora)
              // Isso garante que não há problema de CORS
              final authenticatedUrl = await ref.getDownloadURL().timeout(
                const Duration(seconds: 15),
              );
              
              print('✅ URL autenticada obtida: ${authenticatedUrl.substring(0, 50)}...');
              
              // Aguardar próximo frame antes de setState
              await Future.delayed(const Duration(milliseconds: 50));
              
              if (mounted) {
                setState(() {
                  _authenticatedUrl = authenticatedUrl;
                  _isLoading = false;
                });
              }
            } catch (e) {
              print('❌ Erro ao obter URL autenticada: $e');
              // Se falhar, tentar usar URL original mas marcar como erro
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            }
          } else {
            // Usuário não autenticado - manter URL original
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        } else {
          // URL não é do Firebase Storage - usar diretamente
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('❌ Erro ao processar URL da imagem: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se ainda está carregando (primeira vez), mostrar placeholder
    if (_isLoading && _authenticatedUrl == null) {
      return widget.placeholder ??
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
    }

    // Se há erro e não há URL, mostrar widget de erro
    if (_hasError && _authenticatedUrl == null) {
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
    }

    // Se for Firebase Storage, SEMPRE esperar URL autenticada antes de carregar
    if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
      // Se ainda está carregando ou não tem URL autenticada, mostrar placeholder
      if (_isLoading || _authenticatedUrl == null) {
        return widget.placeholder ??
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
      }
      
      // Se há erro, mostrar widget de erro
      if (_hasError) {
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
      }
    }
    
    // Usar URL autenticada se disponível, senão usar original
    final urlToUse = _authenticatedUrl ?? widget.imageUrl;

    // Para Firebase Storage, carregar via blob para evitar CORS
    Widget imageWidget;
    
    if (urlToUse.contains('firebasestorage.googleapis.com')) {
      // Usar widget customizado que carrega via blob
      imageWidget = _FirebaseStorageImage(
        url: urlToUse,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: widget.placeholder,
        errorWidget: widget.errorWidget,
      );
    } else {
      // Para outras URLs, usar Image.network normal
      imageWidget = Image.network(
        urlToUse,
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
        // NÃO chamar setState aqui - apenas retornar widget de erro
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
    }

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
class _FirebaseStorageImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _FirebaseStorageImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Obter token de autenticação
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final idToken = await user.getIdToken();

      // Fazer requisição com token
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Converter bytes para blob
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        if (mounted) {
          setState(() {
            _blobUrl = blobUrl;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar imagem como blob: $e');
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
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (_hasError || _blobUrl == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Icon(
              Icons.broken_image_outlined,
              size: (widget.height != null && widget.height! < 60) ? widget.height! * 0.4 : 40,
              color: Colors.grey[400],
            ),
          );
    }

    // Usar Image.network com blob URL (não precisa de CORS)
    return Image.network(
      _blobUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
