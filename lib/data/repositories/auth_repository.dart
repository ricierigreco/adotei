import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String email, String password);

  Future<UserModel?> register({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String password,
  });

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserModel?> getCurrentUser();

  Future<UserModel?> updateProfile(UserModel user, {dynamic newProfileImage});

  Stream<UserModel?> get onAuthStateChanged;
}
