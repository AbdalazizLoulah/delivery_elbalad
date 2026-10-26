import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:uuid/uuid.dart';

import '../error/exceptions.dart';
import 'supabase_provider.dart';

/// خدمة تخزين الملفات (صور المنتجات) على Supabase Storage.
abstract class StorageService {
  /// بترفع صورة منتج على السحابة وترجع الرابط العام بتاعها.
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    required String sellerId,
  });
}

/// تنفيذ Supabase: bucket اسمه `product-images` وكل بائع بيكتب في فولدره.
class SupabaseStorageService implements StorageService {
  SupabaseStorageService(this._supabase);

  final SupabaseProvider _supabase;
  static const String _bucket = 'product-images';

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    required String sellerId,
  }) async {
    final extension = _extensionOf(fileName);
    final path = 'products/$sellerId/'
        '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}$extension';

    final client = await _supabase.client;
    try {
      await client.storage.from(_bucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: _contentTypeOf(extension),
              upsert: false,
            ),
          );
      return client.storage.from(_bucket).getPublicUrl(path);
    } on StorageException catch (error) {
      throw AppException(_arabicStorageError(error.message));
    } catch (_) {
      throw const AppException('مش قادرين نرفع الصورة، حاول تاني.');
    }
  }

  /// تحويل أخطاء التخزين الشائعة لرسائل عربية مفهومة.
  static String _arabicStorageError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('bucket not found')) {
      return 'خدمة الصور لسه مش متظبطة على Supabase — شغّل ملف schema.sql من SQL Editor.';
    }
    if (lower.contains('row-level security') || lower.contains('permission denied')) {
      return 'مش مسموح برفع الصور للحساب دا — اتأكد إنك مسجل كتاجر وإن السكيما اتشغلت.';
    }
    if (lower.contains('mime')) {
      return 'نوع الصورة مش مدعوم، جرّب صورة JPG أو PNG.';
    }
    if (lower.contains('too large') || lower.contains('file size')) {
      return 'الصورة كبيرة أوي — الحد الأقصى 5 ميجا.';
    }
    if (lower.contains('duplicate') || lower.contains('already exists')) {
      return 'حصل تعارض في اسم الصورة، جرّب تاني.';
    }
    return 'مش قادرين نرفع الصورة، حاول تاني. ($message)';
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '.jpg';
    final extension = fileName.substring(dot).toLowerCase();
    return extension.length > 5 ? '.jpg' : extension;
  }

  static String _contentTypeOf(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }
}

/// نسخة الاحتياط في الوضع التجريبي (رفع الصور محتاج Supabase).
class UnsupportedStorageService implements StorageService {
  const UnsupportedStorageService();

  @override
  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    required String sellerId,
  }) async {
    throw const AppException('رفع الصور متاح لما التطبيق يكون متوصل بـ Supabase.');
  }
}
