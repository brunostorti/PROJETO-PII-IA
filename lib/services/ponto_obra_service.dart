import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ponto_obra.dart';
import 'firebase_storage_service.dart';

class PontoObraService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _pontosCollection(String projectId) {
    return _firestore.collection('projects').doc(projectId).collection('pontos');
    }

  static Future<PontoObra> createPonto({
    required String projectId,
    required String name,
  }) async {
    final now = DateTime.now();
    final docRef = _pontosCollection(projectId).doc();
    final ponto = PontoObra(
      id: docRef.id,
      projectId: projectId,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(ponto.toFirestore());
    return ponto;
  }

  static Future<bool> updatePonto(PontoObra ponto) async {
    try {
      await _pontosCollection(ponto.projectId).doc(ponto.id).update(
        ponto.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deletePonto({
    required String projectId,
    required String pontoId,
  }) async {
    try {
      await _pontosCollection(projectId).doc(pontoId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<PontoObra?> getPonto({
    required String projectId,
    required String pontoId,
  }) async {
    try {
      final doc = await _pontosCollection(projectId).doc(pontoId).get();
      if (!doc.exists) return null;
      return PontoObra.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  static Stream<List<PontoObra>> getPontosStream(String projectId) {
    return _pontosCollection(projectId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PontoObra.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  static Future<String> uploadIdealImageFile({
    required String projectId,
    required String pontoId,
    required File imageFile,
  }) async {
    return FirebaseStorageService.uploadIdealImage(
      imageFile: imageFile,
      projectId: projectId,
      pontoId: pontoId,
    );
  }

  static Future<String> uploadIdealImageBytes({
    required String projectId,
    required String pontoId,
    required Uint8List bytes,
    String? fileName,
  }) async {
    return FirebaseStorageService.uploadIdealImageBytes(
      bytes: bytes,
      projectId: projectId,
      pontoId: pontoId,
      fileName: fileName,
    );
  }
}



