import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../domain/entities/app_user.dart';
import 'auth_data_source.dart';

/// مصادقة Supabase: المصادقة + جدول profiles (اللي فيه الدور والبيانات الإضافية).
class SupabaseAuthDataSource implements AuthDataSource {
  SupabaseAuthDataSource(this._supabase);

  final SupabaseProvider _supabase;
  static const String _table = 'profiles';

  /// تنظيف الإيميل من المسافات والمحارف غير المرئية (زي اللي بتيجي مع اللصق
  /// أو الكيبورد العربي) قبل ما نبعته لـ Supabase.
  static String _cleanEmail(String email) =>
      email.replaceAll(RegExp(r'[\u00A0\u200B-\u200F\uFEFF]'), '').trim();

  @override
  Future<bool> hasSession() async {
    final client = await _supabase.client;
    return client.auth.currentUser != null;
  }

  @override
  Future<Map<String, dynamic>?> currentProfile() async {
    final client = await _supabase.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    return _profileOf(client, user);
  }

  @override
  Stream<Map<String, dynamic>?> profileChanges() async* {
    final client = await _supabase.client;
    yield* client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      return _profileOf(client, user);
    });
  }

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final client = await _supabase.client;
    final response = await client.auth.signInWithPassword(
      email: _cleanEmail(email),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('فشل تسجيل الدخول، حاول تاني.');
    }

    final profile = await _profileOf(client, user);
    if (profile == null) {
      throw const AuthException('الحساب موجود لكن الملف الشخصي غير متاح، حاول تاني.');
    }

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
    final client = await _supabase.client;
    final cleanEmail = _cleanEmail(email);
    final cleanName = fullName.trim();
    final cleanPhone = phone.trim();

    final response = await client.auth.signUp(
      email: cleanEmail,
      password: password,
      // الدور بيتخزن في بيانات الحساب (raw_user_meta_data)
      // والـ trigger في قاعدة البيانات بيقراه وينشئ صف profiles بالدور الصحيح.
      data: {
        'full_name': cleanName,
        'phone': cleanPhone,
        'role': role.name,
      },
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('مش قادرين ننشئ الحساب، حاول تاني.');
    }

    if (response.session == null) {
      // مشروع Supabase مفعّل فيه تأكيد البريد: الحساب اتعمل بس محتاج تأكيد.
      throw const AuthException(
        'اتعمل الحساب! افتح إيميلك وأكد الحساب، وبعدين سجّل دخول من شاشة الدخول.',
      );
    }

    // ضمان إضافي: لو الـ trigger لسه مش متظبط، بنكتب الملف الشخصي بنفسنا.
    final payload = {
      'id': user.id,
      'full_name': cleanName,
      'email': cleanEmail,
      'role': role.name,
      'phone': cleanPhone,
      'is_available': role == UserRole.courier,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      final profile = await client.from(_table).upsert(payload).select().maybeSingle();
      if (profile != null) return profile;
    } catch (_) {
      // لو الجداول لسه مش متظبطة، الحساب نفسه اتعمل والبيانات موجودة في metadata.
    }
    return payload;
  }

  @override
  Future<void> signOut() async {
    final client = await _supabase.client;
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> _profileOf(SupabaseClient client, User user) async {
    try {
      final row = await client.from(_table).select().eq('id', user.id).maybeSingle();
      if (row != null) return row;
    } catch (_) {
      // الجدول لسه مش متاح — بنكمل ببيانات الحساب.
    }

    // لو الـ trigger مش موجود، بننشئ الصف من بيانات الحساب (metadata).
    final metadata = user.userMetadata ?? const {};
    final payload = {
      'id': user.id,
      'full_name': (metadata['full_name'] ?? '') as String,
      'email': user.email ?? (metadata['email'] ?? '') as String,
      'role': (metadata['role'] ?? 'buyer') as String,
      'phone': (metadata['phone'] ?? '') as String,
    };
    try {
      final created = await client.from(_table).upsert(payload).select().maybeSingle();
      return created ?? payload;
    } catch (_) {
      return payload;
    }
  }
}
