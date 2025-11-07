import 'package:cloud_firestore/cloud_firestore.dart';

class IdealAnalysis {
  final List<String> labels;
  final List<String> objects;
  final List<int>? dominantColorRgb; // [r,g,b]

  const IdealAnalysis({
    this.labels = const [],
    this.objects = const [],
    this.dominantColorRgb,
  });

  Map<String, dynamic> toJson() {
    return {
      'labels': labels,
      'objects': objects,
      if (dominantColorRgb != null) 'dominantColorRgb': dominantColorRgb,
    };
  }

  factory IdealAnalysis.fromJson(Map<String, dynamic> json) {
    return IdealAnalysis(
      labels: (json['labels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      objects: (json['objects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      dominantColorRgb: (json['dominantColorRgb'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    );
  }
}

class PontoObra {
  final String id;
  final String projectId;
  final String name;
  final String? idealImageUrl;
  final IdealAnalysis? idealAnalysis;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PontoObra({
    required this.id,
    required this.projectId,
    required this.name,
    this.idealImageUrl,
    this.idealAnalysis,
    required this.createdAt,
    required this.updatedAt,
  });

  PontoObra copyWith({
    String? id,
    String? projectId,
    String? name,
    String? idealImageUrl,
    IdealAnalysis? idealAnalysis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PontoObra(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      idealImageUrl: idealImageUrl ?? this.idealImageUrl,
      idealAnalysis: idealAnalysis ?? this.idealAnalysis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'name': name,
      if (idealImageUrl != null) 'idealImageUrl': idealImageUrl,
      if (idealAnalysis != null) 'idealAnalysis': idealAnalysis!.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PontoObra.fromFirestore(Map<String, dynamic> data, String id) {
    return PontoObra(
      id: id,
      projectId: data['projectId'] as String,
      name: data['name'] as String,
      idealImageUrl: data['idealImageUrl'] as String?,
      idealAnalysis: data['idealAnalysis'] != null
          ? IdealAnalysis.fromJson(Map<String, dynamic>.from(data['idealAnalysis'] as Map))
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}



