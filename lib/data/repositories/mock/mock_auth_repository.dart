import 'dart:async';
import '../../models/user_model.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  // Simula atraso de rede
  final Duration _delay = const Duration(milliseconds: 800);

  // Banco de dados em memória de usuários cadastrados
  static final List<UserModel> _usersDb = [
    UserModel(
      id: 'mock_user_1',
      name: 'Maria Souza (ONG Patinhas Felizes)',
      email: 'ong@patinhas.com',
      phone: '11999998888',
      city: 'São Paulo',
      state: 'SP',
      profilePictureUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isActive: true,
      isEmailVerified: true,
    ),
    UserModel(
      id: 'mock_user_2',
      name: 'João Silva',
      email: 'joao@adotei.com',
      phone: '21988887777',
      city: 'Rio de Janeiro',
      state: 'RJ',
      profilePictureUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      isActive: true,
      isEmailVerified: true,
    ),
  ];

  UserModel? _currentUser;
  final StreamController<UserModel?> _authStreamController =
      StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    // Inicia sem usuário logado
    _currentUser = null;
    _authStreamController.add(null);
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(_delay);

    // Procura na nossa "tabela"
    final userIndex = _usersDb.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (userIndex != -1) {
      _currentUser = _usersDb[userIndex];
      _authStreamController.add(_currentUser);
      return _currentUser;
    } else {
      // Se não achar, cria um de teste rápido com a senha
      if (email.contains('@') && password.length >= 6) {
        final newUser = UserModel(
          id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@')[0].toUpperCase(),
          email: email,
          phone: '11977776666',
          city: 'São Paulo',
          state: 'SP',
          createdAt: DateTime.now(),
        );
        _usersDb.add(newUser);
        _currentUser = newUser;
        _authStreamController.add(_currentUser);
        return _currentUser;
      }
      throw Exception('E-mail ou senha incorretos.');
    }
  }

  @override
  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String password,
  }) async {
    await Future.delayed(_delay);

    final exists = _usersDb.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      throw Exception('Este e-mail já está cadastrado.');
    }

    final newUser = UserModel(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      city: city,
      state: state,
      createdAt: DateTime.now(),
      isActive: true,
      isEmailVerified: false,
    );

    _usersDb.add(newUser);
    _currentUser = newUser;
    _authStreamController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStreamController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(_delay);
    final exists = _usersDb.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (!exists) {
      throw Exception('E-mail não encontrado no sistema.');
    }
    // Sucesso fictício
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<UserModel?> updateProfile(
    UserModel user, {
    dynamic newProfileImage,
  }) async {
    await Future.delayed(_delay);

    final index = _usersDb.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      throw Exception('Usuário não encontrado.');
    }

    String? picUrl = user.profilePictureUrl;
    if (newProfileImage != null) {
      // Simula upload gerando uma URL temporária local/Unsplash
      picUrl =
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400';
    }

    final updated = user.copyWith(profilePictureUrl: picUrl);
    _usersDb[index] = updated;
    _currentUser = updated;
    _authStreamController.add(updated);

    return updated;
  }

  @override
  Stream<UserModel?> get onAuthStateChanged => _authStreamController.stream;

  // Método auxiliar para buscar protetor por ID (necessário nas telas de detalhes)
  static UserModel? getProtectorById(String id) {
    try {
      return _usersDb.firstWhere((u) => u.id == id);
    } catch (_) {
      // Retorna um fictício se não encontrar
      return UserModel(
        id: id,
        name: 'Protetor Independente',
        email: 'contato@protetor.com',
        phone: '11999999999',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.now(),
      );
    }
  }
}
