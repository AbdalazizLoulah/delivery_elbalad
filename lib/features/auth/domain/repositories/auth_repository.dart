import '../../../../core/result/result.dart';
import '../entities/app_user.dart';

/// عقد المصادقة - أي تنفيذ (Supabase / محلي / أي API) لازم يحقق العقد دا.
abstract interface class AuthRepository {
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  });

  Future<Result<void>> signOut();

  Future<AppUser?> currentUser();

  Stream<AppUser?> authStateChanges();
}
