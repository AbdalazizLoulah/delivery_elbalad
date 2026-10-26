import '../../../../core/demo/demo_database.dart';
import '../../../../core/error/exceptions.dart';
import 'catalog_data_source.dart';

/// كتالوج محلي (الوضع التجريبي) - بيرجع نفس شكل صفوف Supabase بالـ joins.
class LocalCatalogDataSource implements CatalogDataSource {
  LocalCatalogDataSource(this._db);

  final DemoDatabase _db;

  @override
  Future<List<Map<String, dynamic>>> categories() async {
    final rows = _db.rows('categories')
      ..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    String? query,
    String? sellerId,
    bool onlyActive = true,
  }) async {
    final rows = _db.rows('products').where((row) {
      if (onlyActive && row['is_active'] == false) return false;
      if (categoryId != null && row['category_id'] != categoryId) return false;
      if (sellerId != null && row['seller_id'] != sellerId) return false;
      if (query != null && query.trim().isNotEmpty) {
        final title = (row['title'] as String).toLowerCase();
        if (!title.contains(query.trim().toLowerCase())) return false;
      }
      return true;
    }).toList();

    return rows.map(_enrich).toList();
  }

  @override
  Future<Map<String, dynamic>?> product(String id) async {
    final row = _db.row('products', id);
    return row == null ? null : _enrich(row);
  }

  @override
  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> row) async {
    if ((row['title'] as String?)?.trim().isEmpty ?? true) {
      throw const AppException('عنوان المنتج مطلوب.');
    }
    if (((row['price'] as num?)?.toDouble() ?? 0) <= 0) {
      throw const AppException('سعر المنتج لازم يكون أكبر من صفر.');
    }
    _db.upsert('products', row);
    return _enrich(_db.row('products', row['id'] as String)!);
  }

  @override
  Future<void> deleteProduct(String id) async {
    _db.remove('products', id);
  }

  /// إضافة بيانات المتجر والتصنيف جوه الصف (نفس نتيجة join في Supabase).
  Map<String, dynamic> _enrich(Map<String, dynamic> row) {
    final seller = _db.row('profiles', row['seller_id'] as String);
    final category = _db.row('categories', row['category_id'] as String? ?? 'other');
    return {
      ...row,
      'seller': seller == null
          ? null
          : {
              'id': seller['id'],
              'full_name': seller['full_name'],
              'lat': seller['lat'],
              'lng': seller['lng'],
              'rating': seller['rating'],
            },
      'category': category == null ? null : {'id': category['id'], 'name_ar': category['name_ar']},
    };
  }
}
