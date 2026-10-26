import 'dart:async';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_cache.dart';
import '../datasources/auth_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._cache);

  final AuthDataSource _dataSource;
  final AuthCache _cache;

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) {
    return guard(() async {
      final row = await _dataSource.signIn(email: email, password: password);
      final user = AppUserModel.fromJson(row);
      await _cache.save(user);
      return user;
    });
  }

  @override
  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) {
    return guard(() async {
      final row = await _dataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      final user = AppUserModel.fromJson(row);
      await _cache.save(user);
      return user;
    });
  }

  @override
  Future<Result<void>> signOut() {
    return guard(() async {
      try {
        await _dataSource.signOut();
      } finally {
        // بنمسح الكاش المحلي حتى لو خروج السيرفر فشل (الجلسة المحلية اتلغت).
        await _cache.clear();
      }
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    try {
      // فحص محلي سريع للجلسة (من غير طلب بروفايل من الشبكة).
      final hasSession = await _dataSource.hasSession();
      if (!hasSession) {
        await _cache.clear();
        return null;
      }

      final cached = _cache.read();
      if (cached != null) {
        // بنفتح التطبيق فورًا بالمستخدم المحفوظ، وبنحدّث بياناته في الخلفية.
        unawaited(_refreshProfile());
        return cached;
      }

      return await _refreshProfile();
    } catch (_) {
      // لو الشبكة/التهيئة فشلت، بنرجع آخر مستخدم محفوظ لو موجود.
      return _cache.read();
    }
  }

  Future<AppUser?> _refreshProfile() async {
    try {
      final row = await _dataSource.currentProfile();
      if (row == null) {
        await _cache.clear();
        return null;
      }
      final user = AppUserModel.fromJson(row);
      await _cache.save(user);
      return user;
    } catch (_) {
      return _cache.read();
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _dataSource.profileChanges().asyncMap((row) async {
      if (row == null) {
        await _cache.clear();
        return null;
      }
      final user = AppUserModel.fromJson(row);
      await _cache.save(user);
      return user;
    });
  }
}
