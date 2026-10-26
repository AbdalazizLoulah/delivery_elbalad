import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../error/exceptions.dart';
import '../error/failures.dart';
import '../result/result.dart';

/// تحويل أي استثناء لنوع فشل مفهوم للمستخدم (بمكان واحد - DRY).
AppFailure mapError(Object error, [StackTrace? stackTrace]) {
  if (error is AppFailure) return error;
  if (error is AppException) return error.toFailure();

  if (error is sb.AuthException) {
    return AuthFailure(_translateAuth(error.message, error.statusCode));
  }
  if (error is sb.PostgrestException) {
    return AppFailure(_translatePostgres(error.message), code: error.code);
  }
  if (error is sb.StorageException) {
    return AppFailure('مشكلة في رفع الملفات، حاول تاني.');
  }

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection closed') ||
      text.contains('TimeoutException')) {
    return AppFailure.network;
  }

  return AppFailure.unexpected;
}

String _translateAuth(String message, String? status) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login credentials')) return 'البريد الإلكتروني أو كلمة السر غير صحيحة.';
  if (lower.contains('email not confirmed')) return 'لازم تأكد بريدك الإلكتروني الأول.';
  if (lower.contains('user already registered')) return 'البريد الإلكتروني مسجل بالفعل، سجل دخول من فضلك.';
  if (lower.contains('password should be at least')) return 'كلمة السر ضعيفة، اختار كلمة سر أقوى.';
  if (lower.contains('email rate limit')) {
    return 'وصلنا للحد الأقصى لإرسال الإيميلات، استنى شوية أو اقفل تأكيد الإيميل من إعدادات Supabase.';
  }
  if (lower.contains('email address') && lower.contains('invalid')) {
    return 'البريد الإلكتروني اللي كتبته مش صحيح، راجعه أو اكتبه من جديد.';
  }
  if (lower.contains('rate limit')) return 'محاولات كتير، استنى شوية وحاول تاني.';
  return message.isEmpty ? 'فشل تسجيل الدخول، حاول تاني.' : message;
}

String _translatePostgres(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('duplicate key')) return 'البيانات مسجلة بالفعل.';
  if (lower.contains('row-level security') || lower.contains('permission denied')) {
    return 'مش مسموحلك تعمل العملية دي.';
  }
  if (lower.contains('violates foreign key')) return 'فيه بيانات مرتبطة ناقصة.';
  return 'حصلت مشكلة في قاعدة البيانات، حاول تاني.';
}

/// تشغيل عملية آمنة وترجيع `Result` بدل الاستثناءات.
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    final value = await action();
    return Result<T>.success(value);
  } catch (error, stackTrace) {
    return Result<T>.failure(mapError(error, stackTrace));
  }
}
