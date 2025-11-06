import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_obra.dart';

class RegistroObraService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'registros_obras';

  // Obter todos os registros de um usuário
  static Future<List<RegistroObra>> getRegistros(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final registros = snapshot.docs.map((doc) {
        try {
          return RegistroObra.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print('Erro ao processar registro ${doc.id}: $e');
          return null;
        }
      }).whereType<RegistroObra>().toList();
      
      // Ordenar localmente por timestamp (mais recente primeiro)
      registros.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return registros;
    } catch (e) {
      print('Erro ao carregar registros: $e');
      return [];
    }
  }

  // Stream de registros em tempo real
  static Stream<List<RegistroObra>> getRegistrosStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        try {
          return RegistroObra.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          print('Erro ao processar registro ${doc.id}: $e');
          return null;
        }
      }).whereType<RegistroObra>().toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      print('Erro no stream de registros: $error');
      return <RegistroObra>[];
    });
  }

  // Obter um registro específico
  static Future<RegistroObra?> getRegistro(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return RegistroObra.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar registro: $e');
      return null;
    }
  }

  // Salvar registro no Firestore
  static Future<bool> saveRegistro(RegistroObra registro) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(registro.id)
          .set(registro.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao salvar registro: $e');
      return false;
    }
  }

  // Deletar registro do Firestore
  static Future<bool> deleteRegistro(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Erro ao deletar registro: $e');
      return false;
    }
  }

  // Gerar ID único para registro
  static String generateRegistroId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Criar novo registro
  static RegistroObra createRegistro({
    required String userId,
    required String imageUrl,
    required String pontoObra,
    required String etapaObra,
    String? projectId,
    String? createdByName,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? locationAccuracyMeters,
  }) {
    final id = generateRegistroId();
    final now = DateTime.now();

    return RegistroObra(
      id: id,
      userId: userId,
      projectId: projectId,
      imageUrl: imageUrl,
      pontoObra: pontoObra,
      etapaObra: etapaObra,
      createdByName: createdByName,
      latitude: latitude,
      longitude: longitude,
      locationAccuracyMeters: locationAccuracyMeters,
      timestamp: timestamp ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Atualizar registro existente
  static Future<bool> updateRegistro(RegistroObra registro) async {
    try {
      final updatedRegistro = registro.copyWith(updatedAt: DateTime.now());
      return await saveRegistro(updatedRegistro);
    } catch (e) {
      print('Erro ao atualizar registro: $e');
      return false;
    }
  }

  // Query auxiliar com filtros
  static Query<Map<String, dynamic>> _buildFilteredQuery(
    String? userId, {
    DateTime? start,
    DateTime? end,
    String? ponto,
    String? projectId,
    bool getAllRegistros = false, // Se true, não filtra por userId
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(_collectionName);
    
    // Só filtra por userId se não for para buscar todos os registros
    if (!getAllRegistros && userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (projectId != null && projectId.trim().isNotEmpty) {
      query = query.where('projectId', isEqualTo: projectId.trim());
    }
    if (ponto != null && ponto.trim().isNotEmpty) {
      query = query.where('pontoObra', isEqualTo: ponto.trim());
    }
    // Só adiciona range + orderBy se houver filtro de data (evita índice composto)
    if (start != null || end != null) {
      query = query.orderBy('timestamp', descending: true);
      if (start != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: start);
      }
      if (end != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: end);
      }
    } else if (!getAllRegistros) {
      // Se não houver filtro de data e não for buscar todos, ordena por timestamp
      query = query.orderBy('timestamp', descending: true);
    }
    return query;
  }

  // Stream com filtros (data e ponto)
  static Stream<List<RegistroObra>> getRegistrosStreamFiltered(
    String userId, {
    DateTime? start,
    DateTime? end,
    String? ponto,
    String? projectId,
    bool getAllRegistros = false, // Permite buscar todos os registros (se regras permitirem)
  }) {
    final query = _buildFilteredQuery(
      getAllRegistros ? null : userId,
      start: start,
      end: end,
      ponto: ponto,
      projectId: projectId,
      getAllRegistros: getAllRegistros,
    );
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        try {
          return RegistroObra.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          print('Erro ao processar registro ${doc.id}: $e');
          return null;
        }
      }).whereType<RegistroObra>().toList();
      // Ordenar localmente por timestamp desc para o caso sem orderBy
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      print('Erro no stream de registros: $error');
      return <RegistroObra>[];
    });
  }

  // Stream (admin): registros de um projeto (com filtros opcionais)
  static Stream<List<RegistroObra>> getProjectRegistrosStreamFiltered(
    String projectId, {
    DateTime? start,
    DateTime? end,
    String? ponto,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collectionName)
        .where('projectId', isEqualTo: projectId);

    if (ponto != null && ponto.trim().isNotEmpty) {
      query = query.where('pontoObra', isEqualTo: ponto.trim());
    }
    if (start != null || end != null) {
      query = query.orderBy('timestamp', descending: true);
      if (start != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: start);
      }
      if (end != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: end);
      }
    } else {
      // Sempre ordenar por timestamp se não houver filtro de data
      query = query.orderBy('timestamp', descending: true);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        try {
          return RegistroObra.fromFirestore(doc.data(), doc.id);
        } catch (e) {
          print('Erro ao processar registro ${doc.id}: $e');
          return null;
        }
      }).whereType<RegistroObra>().toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }).handleError((error) {
      print('Erro no stream de registros do projeto: $error');
      return <RegistroObra>[];
    });
  }

  // Buscar registros por data (dia específico)
  static Future<List<RegistroObra>> getRegistrosByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      final registros = snapshot.docs.map((doc) {
        return RegistroObra.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      registros.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return registros;
    } catch (e) {
      print('Erro ao buscar registros por data: $e');
      return [];
    }
  }

  // Buscar registros por ponto da obra
  static Future<List<RegistroObra>> getRegistrosByPonto(String userId, String pontoObra) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('pontoObra', isEqualTo: pontoObra)
          .get();

      final registros = snapshot.docs.map((doc) {
        return RegistroObra.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      
      registros.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return registros;
    } catch (e) {
      print('Erro ao buscar registros por ponto: $e');
      return [];
    }
  }

  // Contar registros de um usuário
  static Future<int> getRegistrosCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Erro ao contar registros: $e');
      return 0;
    }
  }

  // Buscar registros por obra específica
  static Future<List<RegistroObra>> getRegistrosByProject(String userId, String projectId) async {
    try {
      // Buscar todas as comparações do usuário e filtrar por projeto no código
      // Isso evita precisar de índice composto
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final registros = snapshot.docs
          .map((doc) => RegistroObra.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((registro) => registro.projectId == projectId)
          .toList();
      
      // Ordenar por timestamp
      registros.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return registros;
    } catch (e) {
      print('Erro ao buscar registros por projeto: $e');
      return [];
    }
  }
}
