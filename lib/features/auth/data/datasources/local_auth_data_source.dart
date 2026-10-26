import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/demo/demo_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_user.dart';
import 'auth_data_source.dart';

/// مصادقة محلية (وضع تجريبي) بتشتغل بنفس سلوك الباك إند الحقيقي.
class LocalAuthDataSource implements AuthDataSource {
  LocalAuthDataSource(this._db, this._preferences);

  static const String _sessionKey = 'demo_current_user_id';

  final DemoDatabase _db;
  final SharedPreferences _preferences;
  final StreamController<Map<String, dynamic>?> _authChanges = StreamController.broadcast();

  @override
  Future<bool> hasSession() async =>
      _db.currentUserId != null && _preferences.getString(_sessionKey) == _db.currentUserId;

  @override
  Future<Map<String, dynamic>?> currentProfile() async {
    final userId = _db.currentUserId;
    if (userId == null) return null;
    return _db.row('profiles', userId);
  }

  @override
  Stream<Map<String, dynamic>?> profileChanges() async* {
    yield await currentProfile();
    yield* _authChanges.stream;
  }

  @override
  Future<Map<String, dynamic>> signIn({required String email, required String password}) async {
    final profile = _db.firstWhere('profiles', (row) => row['email'] == email.trim());
    if (profile == null) {
      throw const AuthException('مفيش حساب بالبريد الإلكتروني دا.');
    }
    final record = _db.row('passwords', profile['id'] as String);
    if ((record?['password'] as String?) != password) {
      throw const AuthException('كلمة السر غير صحيحة.');
    }
    _db.currentUserId = profile['id'] as String;
    await _preferences.setString(_sessionKey, profile['id'] as String);
    _authChanges.add(profile);
    return profile;
  }

  @override
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    final exists = _db.firstWhere('profiles', (row) => row['email'] == email.trim());
    if (exists != null) {
      throw const AuthException('البريد الإلكتروني مسجل بالفعل، سجل دخول من فضلك.');
    }

    final id = 'u-${role.name}-${DateTime.now().millisecondsSinceEpoch}';
    final profile = <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'email': email.trim(),
      'role': role.name,
      'phone': phone,
      'avatar_url': null,
      'rating': 0,
      'ratings_count': 0,
      'lat': null,
      'lng': null,
      'address_text': null,
      'is_available': role == UserRole.courier,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _db.upsert('profiles', profile);
    _db.upsert('passwords', {'id': id, 'password': password});
    _db.currentUserId = id;
    await _preferences.setString(_sessionKey, id);
    _authChanges.add(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    _db.currentUserId = null;
    await _preferences.remove(_sessionKey);
    _authChanges.add(null);
  }
}
