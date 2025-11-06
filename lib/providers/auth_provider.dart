import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userDisplayName => _user?.displayName;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Escutar mudanças no estado de autenticação
    AuthService.authStateChanges.listen((User? user) {
      _user = user;
      if (user?.uid != null) {
        _loadUserRole(user!.uid);
      } else {
        _isAdmin = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserRole(String userId) async {
    try {
      final role = await UserService.getUserRole(userId);
      _isAdmin = role == 'admin';
    } catch (_) {
      _isAdmin = false;
    } finally {
      notifyListeners();
    }
  }

  // Login anônimo
  Future<bool> signInAnonymously() async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await AuthService.signInAnonymously();
      if (result != null) {
        _user = result.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login com email e senha
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result != null) {
        _user = result.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cadastro com email e senha
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final result = await AuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result != null) {
        _user = result.user;
        
        // Criar documento do usuário na coleção 'users' automaticamente
        if (_user?.uid != null) {
          try {
            await UserService.createUserDocument(
              uid: _user!.uid,
              email: email,
              displayName: _user!.displayName,
              role: 'user', // Todos os cadastros são 'user' por padrão
            );
            print('Documento do usuário criado automaticamente no Firestore');
          } catch (e) {
            print('Aviso: Erro ao criar documento do usuário (não crítico): $e');
            // Não falhar o cadastro se o documento não for criado
            // O usuário pode ser criado manualmente depois se necessário
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await AuthService.signOut();
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset de senha
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar perfil
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await AuthService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Atualizar dados locais
      _user = AuthService.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deletar conta
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();
      
      await AuthService.deleteAccount();
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enviar email de verificação
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();
      
      await AuthService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verificar se email está verificado
  bool get isEmailVerified => AuthService.isEmailVerified;

  // Métodos auxiliares
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Recarregar dados do usuário
  Future<void> reloadUser() async {
    try {
      await _user?.reload();
      _user = AuthService.currentUser;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao recarregar dados do usuário');
    }
  }
}
