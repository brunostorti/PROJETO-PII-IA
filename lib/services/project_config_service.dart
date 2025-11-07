import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _weightsDoc(String projectId) {
    return _firestore.collection('projects').doc(projectId).collection('config').doc('weights');
  }

  static Future<void> ensureDefaultWeights(String projectId) async {
    final ref = _weightsDoc(projectId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'presence': 0.4,
        'objects': 0.3,
        'colors': 0.2,
        'extrasPenalty': 0.1,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    }
  }

  static Future<Map<String, double>> getWeights(String projectId) async {
    final ref = _weightsDoc(projectId);
    final snap = await ref.get();
    if (!snap.exists) {
      return {
        'presence': 0.4,
        'objects': 0.3,
        'colors': 0.2,
        'extrasPenalty': 0.1,
      };
    }
    final data = snap.data() ?? {};
    return {
      'presence': (data['presence'] as num?)?.toDouble() ?? 0.4,
      'objects': (data['objects'] as num?)?.toDouble() ?? 0.3,
      'colors': (data['colors'] as num?)?.toDouble() ?? 0.2,
      'extrasPenalty': (data['extrasPenalty'] as num?)?.toDouble() ?? 0.1,
    };
  }

  static Future<void> updateWeights(String projectId, Map<String, double> weights) async {
    await _weightsDoc(projectId).set(
      {
        ...weights,
        'updatedAt': DateTime.now(),
      },
      SetOptions(merge: true),
    );
  }
}



