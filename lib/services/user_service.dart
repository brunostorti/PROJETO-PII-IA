import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // Retorna a role do usuário (admin|user). Default: user
  static Future<String> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        return 'user';
      }
      final data = doc.data();
      final role = data?['role'] as String?;
      return (role == 'admin') ? 'admin' : 'user';
    } catch (_) {
      return 'user';
    }
  }
}


