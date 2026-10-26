import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// تهيئة Supabase بشكل كسول (Lazy).
///
/// مش بنهيّئ الباك إند مع فتح التطبيق؛ أول طبقة بيانات تحتاج العميل
/// هي اللي بتشغّل التهيئة. لو فشلت (شبكة/إعدادات) الخطأ بيرجع للشاشة
/// اللي طلبته، وأول محاولة جديدة بتحاول تاني — من غير ما نقفل التطبيق
/// أو نعرض شاشة "إعادة المحاولة".
class SupabaseProvider {
  SupabaseProvider();

  Future<SupabaseClient>? _pending;

  Future<SupabaseClient> get client async {
    final current = _pending ??= _initialize();
    try {
      return await current;
    } catch (_) {
      if (identical(_pending, current)) _pending = null;
      rethrow;
    }
  }

  Future<SupabaseClient> _initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    return Supabase.instance.client;
  }
}
