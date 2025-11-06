import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import '../models/project.dart';
import '../services/project_service.dart';
import '../services/image_service.dart';
import '../services/firebase_storage_service.dart';

class ProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  bool _isLoading = false;
  String? _currentUserId;
  StreamSubscription<List<Project>>? _projectsSubscription;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  // Inicializar provider com userId
  void initialize(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _listenToProjects();
    }
  }

  // Escutar mudanças nos projetos em tempo real
  void _listenToProjects() {
    if (_currentUserId == null) return;

    _projectsSubscription?.cancel();
    _projectsSubscription = ProjectService.getProjectsStream(_currentUserId!)
        .listen(
      (projects) {
        _projects = projects;
        notifyListeners();
      },
      onError: (error) {
        print('Erro ao escutar projetos: $error');
        _projects = [];
        notifyListeners();
      },
    );
  }

  // Carregar projetos uma vez (método legado)
  Future<void> loadProjects() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _projects = await ProjectService.getProjects(_currentUserId!);
    } catch (e) {
      print('Erro ao carregar projetos: $e');
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar projeto com upload de imagens
  Future<bool> addProject({
    required String name,
    required String description,
    required String location,
    required DateTime startDate,
    ProjectStatus status = ProjectStatus.planning,
    List<File>? imageFiles,
  }) async {
    if (_currentUserId == null) {
      print('Erro: userId é null ao criar projeto');
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      print('Criando projeto para userId: $_currentUserId');

      // Upload de imagens se fornecidas
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('Fazendo upload de ${imageFiles.length} imagens...');
        imageUrls = await ImageService.uploadMultipleImagesToFirebase(
          images: imageFiles,
          userId: _currentUserId!,
          projectId: ProjectService.generateProjectId(),
        );
        print('Upload concluído. ${imageUrls.length} URLs obtidas');
      }

      // Criar projeto
      final project = ProjectService.createProject(
        userId: _currentUserId!,
        name: name,
        description: description,
        location: location,
        startDate: startDate,
        status: status,
        imageUrls: imageUrls,
      );

      print('Projeto criado localmente. ID: ${project.id}');
      print('Dados do projeto: ${project.toFirestore()}');

      // Salvar no Firestore
      print('Salvando projeto no Firestore...');
      final success = await ProjectService.saveProject(project);
      
      if (success) {
        print('Projeto salvo com sucesso!');
      } else {
        print('Erro: Falha ao salvar projeto no Firestore');
      }
      
      return success;
    } catch (e, stackTrace) {
      print('Erro ao adicionar projeto: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualizar projeto
  Future<bool> updateProject(Project project) async {
    try {
      final success = await ProjectService.updateProject(project);
      return success;
    } catch (e) {
      print('Erro ao atualizar projeto: $e');
      return false;
    }
  }

  // Deletar projeto e suas imagens
  Future<bool> deleteProject(String id) async {
    try {
      // Encontrar o projeto para obter as URLs das imagens
      final project = _projects.where((p) => p.id == id).firstOrNull;
      
      if (project != null && _currentUserId != null) {
        // Deletar imagens do Firebase Storage
        if (project.imageUrls.isNotEmpty) {
          await FirebaseStorageService.deleteMultipleImages(project.imageUrls);
        }
      }

      // Deletar projeto do Firestore
      final success = await ProjectService.deleteProject(id);
      return success;
    } catch (e) {
      print('Erro ao deletar projeto: $e');
      return false;
    }
  }

  Project? getProjectById(String id) {
    return _projects.where((project) => project.id == id).firstOrNull;
  }

  List<Project> getProjectsByStatus(ProjectStatus status) {
    return _projects.where((project) => project.status == status).toList();
  }

  int getProjectCountByStatus(ProjectStatus status) {
    return _projects.where((project) => project.status == status).length;
  }

  int get totalProjects => _projects.length;
  int get activeProjects => getProjectCountByStatus(ProjectStatus.inProgress);
  int get completedProjects => getProjectCountByStatus(ProjectStatus.completed);
  int get planningProjects => getProjectCountByStatus(ProjectStatus.planning);

  // Adicionar imagens a um projeto existente
  Future<bool> addImagesToProject(String projectId, List<File> imageFiles) async {
    if (_currentUserId == null) return false;

    try {
      final project = getProjectById(projectId);
      if (project == null) return false;

      _isLoading = true;
      notifyListeners();

      // Upload das novas imagens
      final newImageUrls = await ImageService.uploadMultipleImagesToFirebase(
        images: imageFiles,
        userId: _currentUserId!,
        projectId: projectId,
      );

      // Atualizar projeto com novas URLs
      final updatedProject = project.copyWith(
        imageUrls: [...project.imageUrls, ...newImageUrls],
        updatedAt: DateTime.now(),
      );

      final success = await ProjectService.updateProject(updatedProject);
      return success;
    } catch (e) {
      print('Erro ao adicionar imagens ao projeto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remover imagem de um projeto
  Future<bool> removeImageFromProject(String projectId, String imageUrl) async {
    try {
      final project = getProjectById(projectId);
      if (project == null) return false;

      // Deletar imagem do Firebase Storage
      await FirebaseStorageService.deleteImage(imageUrl);

      // Atualizar projeto removendo a URL
      final updatedImageUrls = project.imageUrls.where((url) => url != imageUrl).toList();
      final updatedProject = project.copyWith(
        imageUrls: updatedImageUrls,
        updatedAt: DateTime.now(),
      );

      final success = await ProjectService.updateProject(updatedProject);
      return success;
    } catch (e) {
      print('Erro ao remover imagem do projeto: $e');
      return false;
    }
  }

  // Limpar projetos (usado no logout)
  void clearProjects() {
    _projectsSubscription?.cancel();
    _projects = [];
    _currentUserId = null;
    _isLoading = false;
    notifyListeners();
  }

  // Limpar recursos
  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
