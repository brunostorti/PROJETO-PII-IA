import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfo {
  final String uid;
  final String? email;
  final String? displayName;
  final String? role;

  UserInfo({
    required this.uid,
    this.email,
    this.displayName,
    this.role,
  });
}

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'users';

  // Criar documento do usuário no Firestore (chamado automaticamente no cadastro)
  static Future<bool> createUserDocument({
    required String uid,
    required String email,
    String? displayName,
    String role = 'user', // Padrão é 'user', admin deve ser criado manualmente
  }) async {
    try {
      // Verificar se o documento já existe (evitar sobrescrever admin)
      final doc = await _firestore.collection(_collectionName).doc(uid).get();
      if (doc.exists) {
        print('Documento do usuário já existe, não será criado novamente');
        return true; // Já existe, considerar sucesso
      }

      await _firestore.collection(_collectionName).doc(uid).set({
        'role': role,
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Documento do usuário criado com sucesso: $uid');
      return true;
    } catch (e) {
      print('Erro ao criar documento do usuário: $e');
      return false;
    }
  }

  // Buscar role do usuário no Firestore
  static Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(userId).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Erro ao buscar role do usuário: $e');
      return null;
    }
  }

  // Buscar todos os usuários (para busca do admin)
  static Future<List<UserInfo>> searchUsers(String searchQuery) async {
    try {
      // Primeiro, buscar no Firestore (usuários com role)
      final firestoreUsers = await _firestore
          .collection(_collectionName)
          .where('role', isEqualTo: 'user')
          .get();

      List<UserInfo> users = [];
      
      // Processar usuários do Firestore
      for (var doc in firestoreUsers.docs) {
        final data = doc.data();
        final email = data['email'] as String?;
        final displayName = data['displayName'] as String?;
        
        // Filtrar por email ou displayName se houver busca
        if (searchQuery.isEmpty ||
            (email != null && email.toLowerCase().contains(searchQuery.toLowerCase())) ||
            (displayName != null && displayName.toLowerCase().contains(searchQuery.toLowerCase()))) {
          users.add(UserInfo(
            uid: doc.id,
            email: email,
            displayName: displayName,
            role: data['role'] as String?,
          ));
        }
      }

      // Também buscar usuários do Firebase Auth que não estão no Firestore
      // (para usuários que foram criados mas não têm documento ainda)
      // Nota: No Firebase Admin SDK seria mais fácil, mas no cliente vamos usar uma abordagem diferente
      // Vamos buscar por email no Firestore primeiro, e se não encontrar, tentar buscar no Auth
      // Mas como não temos acesso direto à lista de usuários no Auth pelo cliente, vamos focar nos que já estão no Firestore

      return users;
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      return [];
    }
  }

  // Buscar usuário por email
  static Future<UserInfo?> getUserByEmail(String email) async {
    try {
      // Buscar no Firestore primeiro
      final query = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        return UserInfo(
          uid: doc.id,
          email: data['email'] as String?,
          displayName: data['displayName'] as String?,
          role: data['role'] as String?,
        );
      }

      // Se não encontrar no Firestore, pode ser que o usuário exista no Auth mas não tenha documento
      // Nesse caso, vamos retornar null e o admin precisará criar o documento primeiro
      return null;
    } catch (e) {
      print('Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  // Buscar informações de múltiplos usuários por UIDs
  static Future<List<UserInfo>> getUsersByUids(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];

      // Buscar documentos em lotes (limite do Firestore é 10 por vez)
      List<UserInfo> users = [];
      for (int i = 0; i < uids.length; i += 10) {
        final batch = uids.skip(i).take(10).toList();
        final docs = await Future.wait(
          batch.map((uid) => _firestore.collection(_collectionName).doc(uid).get()),
        );

        for (var doc in docs) {
          if (doc.exists) {
            final data = doc.data()!;
            users.add(UserInfo(
              uid: doc.id,
              email: data['email'] as String?,
              displayName: data['displayName'] as String?,
              role: data['role'] as String?,
            ));
          } else {
            // Se não encontrar no Firestore, criar entrada básica com UID
            // (pode ser que o usuário exista no Auth mas não tenha documento)
            users.add(UserInfo(uid: doc.id));
          }
        }
      }

      return users;
    } catch (e) {
      print('Erro ao buscar usuários por UIDs: $e');
      return [];
    }
  }
}
