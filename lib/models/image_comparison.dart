import 'package:cloud_firestore/cloud_firestore.dart';

enum ComparisonStatus {
  pending,
  processing,
  completed,
  error,
}

extension ComparisonStatusExtension on ComparisonStatus {
  String get key {
    switch (this) {
      case ComparisonStatus.pending:
        return 'pending';
      case ComparisonStatus.processing:
        return 'processing';
      case ComparisonStatus.completed:
        return 'completed';
      case ComparisonStatus.error:
        return 'error';
    }
  }

  String get displayName {
    switch (this) {
      case ComparisonStatus.pending:
        return 'Pendente';
      case ComparisonStatus.processing:
        return 'Processando';
      case ComparisonStatus.completed:
        return 'Concluído';
      case ComparisonStatus.error:
        return 'Erro';
    }
  }
}

enum ChangeType {
  added,
  removed,
  modified,
}

extension ChangeTypeExtension on ChangeType {
  String get key {
    switch (this) {
      case ChangeType.added:
        return 'added';
      case ChangeType.removed:
        return 'removed';
      case ChangeType.modified:
        return 'modified';
    }
  }

  String get displayName {
    switch (this) {
      case ChangeType.added:
        return 'Adicionado';
      case ChangeType.removed:
        return 'Removido';
      case ChangeType.modified:
        return 'Modificado';
    }
  }
}

class DetectedChange {
  final ChangeType type;
  final String description;
  final double confidence; // 0.0 a 1.0
  final BoundingBox? boundingBox;

  DetectedChange({
    required this.type,
    required this.description,
    required this.confidence,
    this.boundingBox,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.key,
      'description': description,
      'confidence': confidence,
      if (boundingBox != null) 'boundingBox': boundingBox!.toJson(),
    };
  }

  factory DetectedChange.fromJson(Map<String, dynamic> json) {
    return DetectedChange(
      type: ChangeType.values.firstWhere(
        (e) => e.key == json['type'],
        orElse: () => ChangeType.modified,
      ),
      description: json['description'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: json['boundingBox'] != null
          ? BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}

class ImageComparison {
  final String id;
  final String userId;
  final String? projectId;
  final String pontoObra;
  final String etapaObra;

  // URLs das imagens comparadas
  final String baseImageUrl; // Imagem antiga
  final String comparedImageUrl; // Imagem nova

  // IDs dos registros
  final String baseRegistroId;
  final String comparedRegistroId;

  // Resultados da análise
  final double? evolutionPercentage; // % de evolução (0-100)
  final double? similarityScore; // Similaridade (0-1)

  // Mudanças detectadas
  final List<DetectedChange> detectedChanges;

  // Status do processamento
  final ComparisonStatus status;
  final String? errorMessage;

  // Metadados
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImageComparison({
    required this.id,
    required this.userId,
    this.projectId,
    required this.pontoObra,
    required this.etapaObra,
    required this.baseImageUrl,
    required this.comparedImageUrl,
    required this.baseRegistroId,
    required this.comparedRegistroId,
    this.evolutionPercentage,
    this.similarityScore,
    this.detectedChanges = const [],
    required this.status,
    this.errorMessage,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  ImageComparison copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? pontoObra,
    String? etapaObra,
    String? baseImageUrl,
    String? comparedImageUrl,
    String? baseRegistroId,
    String? comparedRegistroId,
    double? evolutionPercentage,
    double? similarityScore,
    List<DetectedChange>? detectedChanges,
    ComparisonStatus? status,
    String? errorMessage,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ImageComparison(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      pontoObra: pontoObra ?? this.pontoObra,
      etapaObra: etapaObra ?? this.etapaObra,
      baseImageUrl: baseImageUrl ?? this.baseImageUrl,
      comparedImageUrl: comparedImageUrl ?? this.comparedImageUrl,
      baseRegistroId: baseRegistroId ?? this.baseRegistroId,
      comparedRegistroId: comparedRegistroId ?? this.comparedRegistroId,
      evolutionPercentage: evolutionPercentage ?? this.evolutionPercentage,
      similarityScore: similarityScore ?? this.similarityScore,
      detectedChanges: detectedChanges ?? this.detectedChanges,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
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
      'pontoObra': pontoObra,
      'etapaObra': etapaObra,
      'baseImageUrl': baseImageUrl,
      'comparedImageUrl': comparedImageUrl,
      'baseRegistroId': baseRegistroId,
      'comparedRegistroId': comparedRegistroId,
      'evolutionPercentage': evolutionPercentage,
      'similarityScore': similarityScore,
      'detectedChanges': detectedChanges.map((e) => e.toJson()).toList(),
      'status': status.key,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ImageComparison.fromJson(Map<String, dynamic> json) {
    return ImageComparison(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String?,
      pontoObra: json['pontoObra'] as String,
      etapaObra: json['etapaObra'] as String,
      baseImageUrl: json['baseImageUrl'] as String,
      comparedImageUrl: json['comparedImageUrl'] as String,
      baseRegistroId: json['baseRegistroId'] as String,
      comparedRegistroId: json['comparedRegistroId'] as String,
      evolutionPercentage: (json['evolutionPercentage'] as num?)?.toDouble(),
      similarityScore: (json['similarityScore'] as num?)?.toDouble(),
      detectedChanges: (json['detectedChanges'] as List<dynamic>?)
              ?.map((e) => DetectedChange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: ComparisonStatus.values.firstWhere(
        (e) => e.key == json['status'] as String,
        orElse: () => ComparisonStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Métodos para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (projectId != null) 'projectId': projectId,
      'pontoObra': pontoObra,
      'etapaObra': etapaObra,
      'baseImageUrl': baseImageUrl,
      'comparedImageUrl': comparedImageUrl,
      'baseRegistroId': baseRegistroId,
      'comparedRegistroId': comparedRegistroId,
      if (evolutionPercentage != null) 'evolutionPercentage': evolutionPercentage,
      if (similarityScore != null) 'similarityScore': similarityScore,
      'detectedChanges': detectedChanges.map((e) => e.toJson()).toList(),
      'status': status.key,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'timestamp': timestamp,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ImageComparison.fromFirestore(Map<String, dynamic> data, String id) {
    return ImageComparison(
      id: id,
      userId: data['userId'] as String,
      projectId: data['projectId'] as String?,
      pontoObra: data['pontoObra'] as String,
      etapaObra: data['etapaObra'] as String,
      baseImageUrl: data['baseImageUrl'] as String,
      comparedImageUrl: data['comparedImageUrl'] as String,
      baseRegistroId: data['baseRegistroId'] as String,
      comparedRegistroId: data['comparedRegistroId'] as String,
      evolutionPercentage: (data['evolutionPercentage'] as num?)?.toDouble(),
      similarityScore: (data['similarityScore'] as num?)?.toDouble(),
      detectedChanges: (data['detectedChanges'] as List<dynamic>?)
              ?.map((e) => DetectedChange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: ComparisonStatus.values.firstWhere(
        (e) => e.key == data['status'] as String,
        orElse: () => ComparisonStatus.pending,
      ),
      errorMessage: data['errorMessage'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() {
    return 'ImageComparison(id: $id, pontoObra: $pontoObra, evolution: $evolutionPercentage%, status: ${status.displayName})';
  }
}

