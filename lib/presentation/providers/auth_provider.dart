import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/mock/mock_auth_repository.dart';
import '../../data/repositories/supabase/supabase_auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false; // Começa como false — só fica true durante operações
  String? _errorMessage;
  StreamSubscription<UserModel?>? _authSubscription;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Escolhe o repositório baseado na configuração do Supabase
    if (AppConfig.useSupabase && AppConfig.isSupabaseConfigured) {
      _authRepository = SupabaseAuthRepository();
    } else {
      _authRepository = MockAuthRepository();
    }

    // Verifica sessão existente na inicialização (sem bloquear a UI)
    _initializeFromCurrentSession();

    // Ouve mudanças de estado (login/logout futuros)
    _authSubscription = _authRepository.onAuthStateChanged.listen(
      (user) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> _initializeFromCurrentSession() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (_) {
      // Silencioso — se falhar, usuário simplesmente fica deslogado
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initializeUser() async {
    // Apenas restaura sessão existente sem alterar isLoading,
    // pois o _initializeFromCurrentSession() já faz isso no construtor.
    // Este método é mantido para compatibilidade com a SplashScreen.
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null && _currentUser == null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      // Trata mensagem de erro limpa
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        city: city,
        state: state,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UserModel user, {dynamic newProfileImage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _authRepository.updateProfile(
        user,
        newProfileImage: newProfileImage,
      );
      _currentUser = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
