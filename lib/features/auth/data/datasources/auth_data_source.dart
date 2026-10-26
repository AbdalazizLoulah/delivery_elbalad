import '../../domain/entities/app_user.dart';

/// عقد مصدر بيانات المصادقة (بيانات صفوف خام زي ما بتجي من قاعدة البيانات).
abstract interface class AuthDataSource {
  /// هل فيه جلسة محفوظة على الجهاز؟ (بدون طلب شبكة)
  Future<bool> hasSession();

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  });

  Future<void> signOut();

  Future<Map<String, dynamic>?> currentProfile();

  Stream<Map<String, dynamic>?> profileChanges();
}
