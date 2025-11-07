import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroObra {
  final String id;
  final String userId;
  final String? projectId;
  final String? pontoId;
  final String imageUrl;
  final String pontoObra;
  final String etapaObra;
  final String? createdByName;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  RegistroObra({
    required this.id,
    required this.userId,
    this.projectId,
    this.pontoId,
    required this.imageUrl,
    required this.pontoObra,
    required this.etapaObra,
    this.createdByName,
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  RegistroObra copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? pontoId,
    String? imageUrl,
    String? pontoObra,
    String? etapaObra,
    String? createdByName,
    double? latitude,
    double? longitude,
    double? locationAccuracyMeters,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RegistroObra(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      pontoId: pontoId ?? this.pontoId,
      imageUrl: imageUrl ?? this.imageUrl,
      pontoObra: pontoObra ?? this.pontoObra,
      etapaObra: etapaObra ?? this.etapaObra,
      createdByName: createdByName ?? this.createdByName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracyMeters: locationAccuracyMeters ?? this.locationAccuracyMeters,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'projectId': projectId,
      'pontoId': pontoId,
      'imageUrl': imageUrl,
      'pontoObra': pontoObra,
      'etapaObra': etapaObra,
      'createdByName': createdByName,
      'latitude': latitude,
      'longitude': longitude,
      'locationAccuracyMeters': locationAccuracyMeters,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RegistroObra.fromJson(Map<String, dynamic> json) {
    return RegistroObra(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String?,
      pontoId: json['pontoId'] as String?,
      imageUrl: json['imageUrl'] as String,
      pontoObra: json['pontoObra'] as String,
      etapaObra: json['etapaObra'] as String,
      createdByName: json['createdByName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracyMeters: (json['locationAccuracyMeters'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Métodos específicos para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (projectId != null) 'projectId': projectId,
      if (pontoId != null) 'pontoId': pontoId,
      'imageUrl': imageUrl,
      'pontoObra': pontoObra,
      'etapaObra': etapaObra,
      if (createdByName != null) 'createdByName': createdByName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAccuracyMeters != null) 'locationAccuracyMeters': locationAccuracyMeters,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RegistroObra.fromFirestore(Map<String, dynamic> data, String id) {
    return RegistroObra(
      id: id,
      userId: data['userId'] as String,
      projectId: data['projectId'] as String?,
      pontoId: data['pontoId'] as String?,
      imageUrl: data['imageUrl'] as String,
      pontoObra: data['pontoObra'] as String,
      etapaObra: data['etapaObra'] as String,
      createdByName: data['createdByName'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      locationAccuracyMeters: (data['locationAccuracyMeters'] as num?)?.toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegistroObra && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RegistroObra(id: $id, pontoObra: $pontoObra, etapaObra: $etapaObra, lat: $latitude, lng: $longitude)';
  }
}
