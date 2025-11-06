import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ProjectUsersScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectUsersScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectUsersScreen> createState() => _ProjectUsersScreenState();
}

class _ProjectUsersScreenState extends State<ProjectUsersScreen> {
  final _searchController = TextEditingController();
  List<UserInfo> _searchResults = [];
  List<UserInfo> _assignedUsers = [];
  Project? _project;
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadProjectAndUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectAndUsers() async {
    setState(() => _isLoading = true);
    try {
      final project = await ProjectService.getProject(widget.projectId);
      if (project != null) {
        setState(() => _project = project);
        if (project.assignedUsers.isNotEmpty) {
          final users = await UserService.getUsersByUids(project.assignedUsers);
          setState(() => _assignedUsers = users);
        }
      }
    } catch (e) {
      print('Erro ao carregar projeto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar projeto: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final users = await UserService.searchUsers(query.trim());
      // Filtrar usuários que já estão atribuídos
      final assignedUids = _project?.assignedUsers ?? [];
      final filteredUsers = users.where((u) => !assignedUids.contains(u.uid)).toList();
      
      setState(() {
        _searchResults = filteredUsers;
        _isSearching = false;
      });
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar usuários: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _addUser(UserInfo user) async {
    if (_project == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await ProjectService.addUserToProject(widget.projectId, user.uid);
      if (success) {
        // Atualizar lista local
        setState(() {
          _assignedUsers.add(user);
          _searchResults.removeWhere((u) => u.uid == user.uid);
          _searchController.clear();
        });

        // Recarregar projeto
        await _loadProjectAndUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário adicionado ao projeto com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao adicionar usuário ao projeto'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao adicionar usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar usuário: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeUser(UserInfo user) async {
    if (_project == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Usuário'),
        content: Text('Deseja remover ${user.email ?? user.uid} deste projeto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await ProjectService.removeUserFromProject(widget.projectId, user.uid);
      if (success) {
        setState(() {
          _assignedUsers.removeWhere((u) => u.uid == user.uid);
        });

        // Recarregar projeto
        await _loadProjectAndUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário removido do projeto com sucesso!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover usuário do projeto'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao remover usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover usuário: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuários: ${widget.projectName}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _project == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Campo de busca
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar usuários por email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchUsers('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      _searchUsers(value);
                    },
                  ),
                ),

                // Resultados da busca
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else if (_searchResults.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Resultados da busca (${_searchResults.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor,
                                    child: Text(
                                      user.email?.substring(0, 1).toUpperCase() ?? 'U',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user.email ?? 'Sem email'),
                                  subtitle: user.displayName != null
                                      ? Text(user.displayName!)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add, color: AppTheme.successColor),
                                    onPressed: () => _addUser(user),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Usuários atribuídos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Usuários atribuídos (${_assignedUsers.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Expanded(
                        child: _assignedUsers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhum usuário atribuído',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _assignedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _assignedUsers[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor,
                                        child: Text(
                                          user.email?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(user.email ?? 'Sem email'),
                                      subtitle: user.displayName != null
                                          ? Text(user.displayName!)
                                          : null,
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: AppTheme.errorColor,
                                        ),
                                        onPressed: () => _removeUser(user),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

