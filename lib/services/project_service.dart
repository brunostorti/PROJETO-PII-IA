import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';

class ProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'projects';

  // Obter todos os projetos de um usuário (como dono OU atribuído)
  static Future<List<Project>> getProjects(String userId) async {
    try {
      // Buscar projetos onde o usuário é dono
      final ownerSnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      // Buscar projetos onde o usuário está na lista assignedUsers
      final assignedSnapshot = await _firestore
          .collection(_collectionName)
          .where('assignedUsers', arrayContains: userId)
          .get();

      // Combinar e remover duplicatas
      final allDocs = <String, Project>{};
      
      for (var doc in ownerSnapshot.docs) {
        final project = Project.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        allDocs[project.id] = project;
      }
      
      for (var doc in assignedSnapshot.docs) {
        final project = Project.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        allDocs[project.id] = project;
      }

      final projects = allDocs.values.toList();
      // Ordenar por updatedAt
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return projects;
    } catch (e) {
      print('Erro ao carregar projetos: $e');
      return [];
    }
  }

  // Stream de projetos em tempo real (como dono OU atribuído)
  static Stream<List<Project>> getProjectsStream(String userId) {
    // Como não podemos fazer OR em streams diretamente, vamos combinar dois streams
    final ownerStream = _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots();

    final assignedStream = _firestore
        .collection(_collectionName)
        .where('assignedUsers', arrayContains: userId)
        .snapshots();

    // Combinar os dois streams usando StreamController
    final controller = StreamController<List<Project>>();
    final allProjects = <String, Project>{};
    
    void updateProjects() {
      final projects = allProjects.values.toList();
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      controller.add(projects);
    }

    StreamSubscription<QuerySnapshot>? ownerSub;
    StreamSubscription<QuerySnapshot>? assignedSub;

    ownerSub = ownerStream.listen((snapshot) {
      for (var doc in snapshot.docs) {
        final project = Project.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        allProjects[project.id] = project;
      }
      updateProjects();
    });

    assignedSub = assignedStream.listen((snapshot) {
      for (var doc in snapshot.docs) {
        final project = Project.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        allProjects[project.id] = project;
      }
      updateProjects();
    });

    controller.onCancel = () {
      ownerSub?.cancel();
      assignedSub?.cancel();
    };

    return controller.stream;
  }

  // Obter um projeto específico
  static Future<Project?> getProject(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return Project.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar projeto: $e');
      return null;
    }
  }

  // Salvar projeto no Firestore
  static Future<bool> saveProject(Project project) async {
    try {
      print('ProjectService.saveProject - Iniciando...');
      print('Collection: $_collectionName');
      print('Document ID: ${project.id}');
      print('Data: ${project.toFirestore()}');
      
      await _firestore
          .collection(_collectionName)
          .doc(project.id)
          .set(project.toFirestore());

      print('ProjectService.saveProject - Sucesso!');
      return true;
    } catch (e, stackTrace) {
      print('Erro ao salvar projeto: $e');
      print('Stack trace: $stackTrace');
      print('Tipo do erro: ${e.runtimeType}');
      return false;
    }
  }

  // Deletar projeto do Firestore
  static Future<bool> deleteProject(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Erro ao deletar projeto: $e');
      return false;
    }
  }

  // Gerar ID único para projeto
  static String generateProjectId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Criar novo projeto
  static Project createProject({
    required String userId,
    required String name,
    required String description,
    required String location,
    required DateTime startDate,
    ProjectStatus status = ProjectStatus.planning,
    List<String>? imageUrls,
  }) {
    final id = generateProjectId();
    final now = DateTime.now();

    return Project(
      id: id,
      userId: userId,
      name: name,
      description: description,
      location: location,
      startDate: startDate,
      status: status,
      imageUrls: imageUrls ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // Atualizar projeto existente
  static Future<bool> updateProject(Project project) async {
    try {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      return await saveProject(updatedProject);
    } catch (e) {
      print('Erro ao atualizar projeto: $e');
      return false;
    }
  }

  // Buscar projetos por status
  static Future<List<Project>> getProjectsByStatus(String userId, ProjectStatus status) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: status.key)
          .get();

      return snapshot.docs.map((doc) {
        return Project.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar projetos por status: $e');
      return [];
    }
  }

  // Contar projetos por status
  static Future<int> getProjectCountByStatus(String userId, ProjectStatus status) async {
    try {
      final projects = await getProjects(userId);
      return projects.where((p) => p.status == status).length;
    } catch (e) {
      print('Erro ao contar projetos por status: $e');
      return 0;
    }
  }

  // Adicionar usuário a um projeto
  static Future<bool> addUserToProject(String projectId, String userId) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return false;

      if (project.assignedUsers.contains(userId)) {
        // Usuário já está atribuído
        return true;
      }

      final updatedAssignedUsers = [...project.assignedUsers, userId];
      final updatedProject = project.copyWith(
        assignedUsers: updatedAssignedUsers,
        updatedAt: DateTime.now(),
      );

      return await saveProject(updatedProject);
    } catch (e) {
      print('Erro ao adicionar usuário ao projeto: $e');
      return false;
    }
  }

  // Remover usuário de um projeto
  static Future<bool> removeUserFromProject(String projectId, String userId) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return false;

      final updatedAssignedUsers = project.assignedUsers.where((uid) => uid != userId).toList();
      final updatedProject = project.copyWith(
        assignedUsers: updatedAssignedUsers,
        updatedAt: DateTime.now(),
      );

      return await saveProject(updatedProject);
    } catch (e) {
      print('Erro ao remover usuário do projeto: $e');
      return false;
    }
  }
}
