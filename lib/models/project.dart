
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus {
  planning,
  inProgress,
  completed,
  paused,
  cancelled,
}

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'Planejamento';
      case ProjectStatus.inProgress:
        return 'Em Andamento';
      case ProjectStatus.completed:
        return 'Concluída';
      case ProjectStatus.paused:
        return 'Pausada';
      case ProjectStatus.cancelled:
        return 'Cancelada';
    }
  }

  String get key {
    switch (this) {
      case ProjectStatus.planning:
        return 'planning';
      case ProjectStatus.inProgress:
        return 'in_progress';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.paused:
        return 'paused';
      case ProjectStatus.cancelled:
        return 'cancelled';
    }
  }
}

class Project {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final ProjectStatus status;
  final List<String> imageUrls; // Changed from imagePaths to imageUrls for Firebase Storage
  final List<String> assignedUsers; // Usuários atribuídos ao projeto
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.imageUrls,
    this.assignedUsers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    List<String>? imageUrls,
    List<String>? assignedUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.key,
      'imageUrls': imageUrls,
      'assignedUsers': assignedUsers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      status: ProjectStatus.values.firstWhere(
        (e) => e.key == json['status'] as String,
        orElse: () => ProjectStatus.planning,
      ),
      imageUrls: List<String>.from(json['imageUrls'] as List<dynamic>? ?? []),
      assignedUsers: List<String>.from(json['assignedUsers'] as List<dynamic>? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Métodos específicos para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'status': status.key,
      'imageUrls': imageUrls,
      'assignedUsers': assignedUsers,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Project.fromFirestore(Map<String, dynamic> data, String id) {
    return Project(
      id: id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      location: data['location'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      status: ProjectStatus.values.firstWhere(
        (e) => e.key == data['status'] as String,
        orElse: () => ProjectStatus.planning,
      ),
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      assignedUsers: List<String>.from(data['assignedUsers'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, status: ${status.displayName})';
  }
}
