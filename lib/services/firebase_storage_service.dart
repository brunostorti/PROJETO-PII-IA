import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload de uma única imagem para registro de obra
  static Future<String> uploadRegistroImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');
      final fileName = '${now.millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      
      // Organizar por: obras/userId/ANO/MES/nome_da_imagem.jpg
      final storagePath = 'obras/$userId/$year/$month/$fileName';

      // Criar referência do arquivo
      final Reference ref = _storage.ref().child(storagePath);

      // Upload do arquivo
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Aguardar upload e obter URL com token de autenticação
      final TaskSnapshot snapshot = await uploadTask;
      // getDownloadURL() já retorna URL com token, válida por 1 hora
      // Isso evita problemas de CORS
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem de registro: $e');
      throw Exception('Erro ao fazer upload da imagem de registro: $e');
    }
  }

  // Upload (web) de bytes para registro de obra
  static Future<String> uploadRegistroImageBytes({
    required Uint8List bytes,
    required String userId,
    String? fileName,
  }) async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');
      final inferredName = fileName ?? 'captura_${now.millisecondsSinceEpoch}.jpg';
      final storagePath = 'obras/$userId/$year/$month/$inferredName';

      final Reference ref = _storage.ref().child(storagePath);

      // Tenta inferir contentType por extensão
      final ext = path.extension(inferredName).toLowerCase();
      String? contentType;
      switch (ext) {
        case '.png':
          contentType = 'image/png';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        default:
          contentType = 'image/jpeg';
      }

      final SettableMetadata metadata = SettableMetadata(contentType: contentType);
      final UploadTask uploadTask = ref.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload (bytes) da imagem de registro: $e');
      throw Exception('Erro ao fazer upload (bytes) da imagem de registro: $e');
    }
  }

  // Upload de uma única imagem (método original para projetos)
  static Future<String> uploadImage({
    required File imageFile,
    required String userId,
    required String projectId,
  }) async {
    try {
      // Gerar nome único para o arquivo
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = 'users/$userId/projects/$projectId/images/$fileName';

      // Criar referência do arquivo
      final Reference ref = _storage.ref().child(storagePath);

      // Upload do arquivo
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Aguardar upload e obter URL com token de autenticação
      final TaskSnapshot snapshot = await uploadTask;
      // getDownloadURL() já retorna URL com token, válida por 1 hora
      // Isso evita problemas de CORS
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      throw Exception('Erro ao fazer upload da imagem: $e');
    }
  }

  // Upload de múltiplas imagens
  static Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String userId,
    required String projectId,
  }) async {
    try {
      final List<String> downloadUrls = [];

      for (final imageFile in imageFiles) {
        final url = await uploadImage(
          imageFile: imageFile,
          userId: userId,
          projectId: projectId,
        );
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      print('Erro ao fazer upload de múltiplas imagens: $e');
      throw Exception('Erro ao fazer upload de múltiplas imagens: $e');
    }
  }

  // Deletar uma imagem
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extrair o path da URL
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Erro ao deletar imagem: $e');
      throw Exception('Erro ao deletar imagem: $e');
    }
  }

  // Deletar múltiplas imagens
  static Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      for (final imageUrl in imageUrls) {
        await deleteImage(imageUrl);
      }
    } catch (e) {
      print('Erro ao deletar múltiplas imagens: $e');
      throw Exception('Erro ao deletar múltiplas imagens: $e');
    }
  }

  // Deletar todas as imagens de um projeto
  static Future<void> deleteProjectImages({
    required String userId,
    required String projectId,
  }) async {
    try {
      final Reference projectRef = _storage.ref().child('users/$userId/projects/$projectId/images');
      final ListResult result = await projectRef.listAll();

      for (final Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      print('Erro ao deletar imagens do projeto: $e');
      throw Exception('Erro ao deletar imagens do projeto: $e');
    }
  }

  // Obter URL de download de uma imagem
  static Future<String> getImageUrl(String storagePath) async {
    try {
      final Reference ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erro ao obter URL da imagem: $e');
      throw Exception('Erro ao obter URL da imagem: $e');
    }
  }

  // Listar todas as imagens de um projeto
  static Future<List<String>> listProjectImages({
    required String userId,
    required String projectId,
  }) async {
    try {
      final Reference projectRef = _storage.ref().child('users/$userId/projects/$projectId/images');
      final ListResult result = await projectRef.listAll();

      final List<String> imageUrls = [];
      for (final Reference ref in result.items) {
        final String url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      return imageUrls;
    } catch (e) {
      print('Erro ao listar imagens do projeto: $e');
      throw Exception('Erro ao listar imagens do projeto: $e');
    }
  }

  // Verificar se uma imagem existe
  static Future<bool> imageExists(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obter metadados de uma imagem
  static Future<FullMetadata> getImageMetadata(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Erro ao obter metadados da imagem: $e');
      throw Exception('Erro ao obter metadados da imagem: $e');
    }
  }

  // Upload com progresso
  static Future<String> uploadImageWithProgress({
    required File imageFile,
    required String userId,
    required String projectId,
    required Function(double progress) onProgress,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final storagePath = 'users/$userId/projects/$projectId/images/$fileName';

      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(imageFile);

      // Escutar progresso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Erro ao fazer upload da imagem com progresso: $e');
      throw Exception('Erro ao fazer upload da imagem com progresso: $e');
    }
  }

  // Validar tipo de arquivo
  static bool isValidImageType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
  }

  // Validar tamanho do arquivo (em bytes)
  static bool isValidImageSize(int fileSizeInBytes) {
    const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    return fileSizeInBytes <= maxSizeInBytes;
  }

  // Gerar nome único para arquivo
  static String generateUniqueFileName(String originalFileName) {
    final extension = path.extension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${timestamp}_${path.basenameWithoutExtension(originalFileName)}$extension';
  }
}
