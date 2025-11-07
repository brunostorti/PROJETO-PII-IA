import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/image_comparison.dart';
import '../models/registro_obra.dart';
import 'registro_obra_service.dart';
import 'cloud_functions_service.dart';
import 'ponto_obra_service.dart';

class AIComparisonService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'image_comparisons';

  /// Compara duas imagens usando IA
  /// 
  /// [baseRegistroId] - ID do registro da imagem antiga
  /// [comparedRegistroId] - ID do registro da imagem nova
  /// 
  /// Retorna o ID da comparação criada
  static Future<String> compareImages({
    required String baseRegistroId,
    required String comparedRegistroId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar os registros
      final baseRegistro = await RegistroObraService.getRegistro(baseRegistroId);
      final comparedRegistro = await RegistroObraService.getRegistro(comparedRegistroId);

      if (baseRegistro == null || comparedRegistro == null) {
        throw Exception('Registros não encontrados');
      }

      // Verificar se são do mesmo ponto
      if (baseRegistro.pontoObra != comparedRegistro.pontoObra) {
        throw Exception('As imagens devem ser do mesmo ponto da obra');
      }

      // Criar documento de comparação no Firestore (status: pending)
      final comparisonId = _firestore.collection(_collectionName).doc().id;
      final now = DateTime.now();

      final comparison = ImageComparison(
        id: comparisonId,
        userId: user.uid,
        projectId: baseRegistro.projectId,
        pontoObra: baseRegistro.pontoObra,
        etapaObra: baseRegistro.etapaObra,
        baseImageUrl: baseRegistro.imageUrl,
        comparedImageUrl: comparedRegistro.imageUrl,
        baseRegistroId: baseRegistroId,
        comparedRegistroId: comparedRegistroId,
        status: ComparisonStatus.pending,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

      // Salvar no Firestore (já associado ao projeto via projectId)
      await _firestore
          .collection(_collectionName)
          .doc(comparisonId)
          .set(comparison.toFirestore());

      print('📝 Comparação criada no Firestore: $comparisonId');
      print('   - Projeto: ${baseRegistro.projectId ?? "N/A"}');
      print('   - Ponto: ${baseRegistro.pontoObra}');
      print('   - Etapa: ${baseRegistro.etapaObra}');

      // Chamar Cloud Function de forma assíncrona
      _processComparison(comparisonId, comparison);

      return comparisonId;
    } catch (e) {
      print('Erro ao comparar imagens: $e');
      rethrow;
    }
  }

  /// Compara um registro atual com a imagem ideal de um ponto
  /// Cria o documento de comparação e processa via Cloud Function
  static Future<String> compareWithIdeal({
    required String projectId,
    required String pontoId,
    required String registroId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final registro = await RegistroObraService.getRegistro(registroId);
      if (registro == null) {
        throw Exception('Registro não encontrado');
      }

      final ponto = await PontoObraService.getPonto(projectId: projectId, pontoId: pontoId);
      if (ponto == null || ponto.idealImageUrl == null) {
        throw Exception('Ponto não encontrado ou sem imagem ideal');
      }

      final comparisonId = _firestore.collection(_collectionName).doc().id;
      final now = DateTime.now();

      final comparison = ImageComparison(
        id: comparisonId,
        userId: user.uid,
        projectId: projectId,
        pontoId: pontoId,
        pontoObra: registro.pontoObra,
        etapaObra: registro.etapaObra,
        baseImageUrl: ponto.idealImageUrl!,
        comparedImageUrl: registro.imageUrl,
        baseRegistroId: 'ponto:$pontoId:ideal',
        comparedRegistroId: registroId,
        status: ComparisonStatus.pending,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection(_collectionName).doc(comparisonId).set(comparison.toFirestore());

      _processComparison(comparisonId, comparison, projectId: projectId, pontoId: pontoId);

      return comparisonId;
    } catch (e) {
      print('Erro ao comparar com ideal: $e');
      rethrow;
    }
  }

  /// Processa a comparação chamando a Cloud Function
  static Future<void> _processComparison(
    String comparisonId,
    ImageComparison comparison,
    {String? projectId, String? pontoId}
  ) async {
    try {
      // Atualizar status para processing
      await _firestore.collection(_collectionName).doc(comparisonId).update({
        'status': ComparisonStatus.processing.key,
        'updatedAt': DateTime.now(),
      });

      // Chamar Cloud Function
      final result = await CloudFunctionsService.compareImages(
        baseImageUrl: comparison.baseImageUrl,
        comparedImageUrl: comparison.comparedImageUrl,
        pontoObra: comparison.pontoObra,
        etapaObra: comparison.etapaObra,
        projectId: projectId,
        pontoId: pontoId,
      );

      // Processar resultados
      final evolutionPercentage = (result['evolutionPercentage'] as num?)?.toDouble();
      final similarityScore = (result['similarityScore'] as num?)?.toDouble();
      final detectedChanges = (result['detectedChanges'] as List<dynamic>?)
              ?.map((e) => DetectedChange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final Map<String, dynamic>? metadata =
          result['metadata'] != null ? Map<String, dynamic>.from(result['metadata'] as Map) : null;

      // Atualizar documento com resultados
      await _firestore.collection(_collectionName).doc(comparisonId).update({
        'evolutionPercentage': evolutionPercentage,
        'similarityScore': similarityScore,
        'detectedChanges': detectedChanges.map((e) => e.toJson()).toList(),
        if (metadata != null) 'metadata': metadata,
        'status': ComparisonStatus.completed.key,
        'updatedAt': DateTime.now(),
      });

      print('✅ Comparação concluída com sucesso!');
      print('   - Evolução: ${evolutionPercentage}%');
      print('   - Similaridade: ${similarityScore}');
      print('   - Mudanças detectadas: ${detectedChanges.length}');
    } catch (e) {
      print('Erro ao processar comparação: $e');
      // Atualizar status para error
      await _firestore.collection(_collectionName).doc(comparisonId).update({
        'status': ComparisonStatus.error.key,
        'errorMessage': e.toString(),
        'updatedAt': DateTime.now(),
      });
    }
  }

  /// Obtém uma comparação específica
  static Future<ImageComparison?> getComparison(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return ImageComparison.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar comparação: $e');
      return null;
    }
  }

  /// Stream de comparações de um usuário
  static Stream<List<ImageComparison>> getComparisonsStream(String userId) {
    // Buscar todas as comparações do usuário e ordenar no código
    // Isso evita precisar de índice composto
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final comparisons = snapshot.docs
          .map((doc) => ImageComparison.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Ordenar por timestamp
      comparisons.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return comparisons;
    });
  }

  /// Obtém comparações de um ponto específico
  static Future<List<ImageComparison>> getComparisonsByPonto(
    String userId,
    String pontoObra,
  ) async {
    try {
      // Buscar todas as comparações do usuário e filtrar por ponto no código
      // Isso evita precisar de índice composto
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final comparisons = snapshot.docs
          .map((doc) => ImageComparison.fromFirestore(doc.data(), doc.id))
          .where((comparison) => comparison.pontoObra == pontoObra)
          .toList();
      
      // Ordenar por timestamp
      comparisons.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return comparisons;
    } catch (e) {
      print('Erro ao buscar comparações por ponto: $e');
      return [];
    }
  }

  /// Obtém comparações de um projeto
  static Future<List<ImageComparison>> getComparisonsByProject(
    String userId,
    String projectId,
  ) async {
    try {
      // Buscar todas as comparações do usuário e filtrar por projeto no código
      // Isso evita precisar de índice composto
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final comparisons = snapshot.docs
          .map((doc) => ImageComparison.fromFirestore(doc.data(), doc.id))
          .where((comparison) => comparison.projectId == projectId)
          .toList();
      
      // Ordenar por timestamp
      comparisons.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return comparisons;
    } catch (e) {
      print('Erro ao buscar comparações por projeto: $e');
      return [];
    }
  }

  /// Stream de comparações filtradas por projeto e pontoId
  static Stream<List<ImageComparison>> getComparisonsByProjectAndPontoStream({
    required String userId,
    required String projectId,
    required String pontoId,
  }) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final comparisons = snapshot.docs
          .map((doc) => ImageComparison.fromFirestore(doc.data(), doc.id))
          .where((c) => c.projectId == projectId && c.pontoId == pontoId)
          .toList();
      comparisons.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return comparisons;
    });
  }

  /// Deleta uma comparação
  static Future<bool> deleteComparison(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar comparação: $e');
      return false;
    }
  }
}

