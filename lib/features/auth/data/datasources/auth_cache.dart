import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../models/app_user_model.dart';

/// كاش بسيط لبيانات المستخدم على الجهاز.
///
/// الهدف: فتح التطبيق فورًا للمستخدم اللي مسجل دخول من غير انتظار طلب
/// بروفايل من الشبكة كل مرة. بنتحقق الأول من وجود جلسة محلية، وبعد كده
/// بنعرض الكاش ونحدّثه في الخلفية.
class AuthCache {
  AuthCache(this._preferences);

  static const String _key = 'auth_cached_user_v1';

  final SharedPreferences _preferences;

  AppUser? read() {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppUserModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AppUser user) {
    final model = user is AppUserModel ? user : AppUserModel.fromEntity(user);
    return _preferences.setString(_key, jsonEncode(model.toJson()));
  }

  Future<void> clear() => _preferences.remove(_key);
}
