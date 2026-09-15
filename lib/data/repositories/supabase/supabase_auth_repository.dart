import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null || session.user == null) {
        return null;
      }
      return await _getProfileFromSupabase(session.user.id);
    });
  }

  Future<UserModel?> _getProfileFromSupabase(String uid) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromMap(response);
      }

      // Se a conta auth existe mas a linha profiles ainda não,
      // usa informações da auth session como fallback
      final authUser = _supabase.auth.currentUser;
      if (authUser != null && authUser.id == uid) {
        final fallback = UserModel(
          id: authUser.id,
          name: authUser.userMetadata?['name']?.toString() ??
              authUser.email?.split('@')[0] ??
              'Usuário',
          email: authUser.email ?? '',
          phone: authUser.userMetadata?['phone']?.toString() ?? '',
          city: authUser.userMetadata?['city']?.toString() ?? '',
          state: authUser.userMetadata?['state']?.toString() ?? '',
          createdAt: DateTime.now(),
          isEmailVerified: authUser.emailConfirmedAt != null,
        );

        // Tenta salvar o profile inicial
        try {
          await _supabase.from('profiles').upsert(fallback.toSupabaseMap());
        } catch (_) {}

        return fallback;
      }

      return null;
    } catch (e) {
      print('Erro ao buscar perfil do Supabase: $e');
      return null;
    }
  }

  @override
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return null;

      final profile = await _getProfileFromSupabase(user.id);
      return profile;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e.message));
    } catch (e) {
      throw Exception('Erro ao realizar login: $e');
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
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'city': city,
          'state': state,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Não foi possível criar o usuário.');
      }

      final newUser = UserModel(
        id: user.id,
        name: name,
        email: email,
        phone: phone,
        city: city,
        state: state,
        createdAt: DateTime.now(),
        isActive: true,
        isEmailVerified: user.emailConfirmedAt != null,
      );

      // Salva ou atualiza a linha na tabela 'profiles'
      await _supabase.from('profiles').upsert(newUser.toSupabaseMap());

      return newUser;
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e.message));
    } catch (e) {
      throw Exception('Erro ao registrar usuário: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Erro no logout: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(_handleAuthError(e.message));
    } catch (e) {
      throw Exception('Erro ao solicitar redefinição de senha: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return await _getProfileFromSupabase(user.id);
  }

  @override
  Future<UserModel?> updateProfile(
    UserModel user, {
    dynamic newProfileImage,
  }) async {
    try {
      String? imageUrl = user.profilePictureUrl;

      // Se houver nova imagem em bytes, faz upload no bucket de storage
      if (newProfileImage != null && newProfileImage is Uint8List) {
        final path = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('profiles').uploadBinary(
              path,
              newProfileImage,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        imageUrl = _supabase.storage.from('profiles').getPublicUrl(path);
      }

      final updatedUser = user.copyWith(profilePictureUrl: imageUrl);

      // Atualiza no banco de dados
      await _supabase
          .from('profiles')
          .update(updatedUser.toSupabaseMap())
          .eq('id', user.id);

      return updatedUser;
    } catch (e) {
      throw Exception('Erro ao atualizar perfil no Supabase: $e');
    }
  }

  String _handleAuthError(String errorString) {
    final lower = errorString.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('wrong password')) {
      return 'E-mail ou senha incorretos.';
    } else if (lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'Este e-mail já está sendo utilizado por outra conta.';
    } else if (lower.contains('invalid email')) {
      return 'O formato do e-mail é inválido.';
    } else if (lower.contains('weak password') ||
        lower.contains('at least 6 characters')) {
      return 'A senha é muito fraca (mínimo de 6 caracteres).';
    } else if (lower.contains('network') || lower.contains('connection')) {
      return 'Falha na conexão de rede. Verifique seu acesso à internet.';
    }
    return errorString;
  }
}
