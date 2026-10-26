import '../../../../core/services/supabase_provider.dart';
import 'catalog_data_source.dart';

/// كتالوج Supabase - بيستخدم نفس اسماء الجداول والأعمدة الموجودة في ملف الـ SQL.
class SupabaseCatalogDataSource implements CatalogDataSource {
  SupabaseCatalogDataSource(this._supabase);

  final SupabaseProvider _supabase;

  static const String _products = 'products';
  static const String _categories = 'categories';

  /// نفس أعمدة الـ join المستخدمة في الوضع المحلي.
  static const String _select =
      '*, category:categories(id, name_ar), seller:profiles(full_name, lat, lng, rating)';

  @override
  Future<List<Map<String, dynamic>>> categories() async {
    final client = await _supabase.client;
    final rows = await client.from(_categories).select().order('sort_order');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    String? query,
    String? sellerId,
    bool onlyActive = true,
  }) async {
    final client = await _supabase.client;
    var request = client.from(_products).select(_select);
    if (onlyActive) request = request.eq('is_active', true);
    if (categoryId != null) request = request.eq('category_id', categoryId);
    if (sellerId != null) request = request.eq('seller_id', sellerId);
    if (query != null && query.trim().isNotEmpty) request = request.ilike('title', '%${query.trim()}%');

    final rows = await request.order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>?> product(String id) async {
    final client = await _supabase.client;
    return client.from(_products).select(_select).eq('id', id).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> row) async {
    final client = await _supabase.client;
    final payload = Map<String, dynamic>.from(row)..remove('seller')
      ..remove('category')
      ..remove('seller_name');
    final saved = await client.from(_products).upsert(payload).select(_select).single();
    return Map<String, dynamic>.from(saved);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final client = await _supabase.client;
    await client.from(_products).delete().eq('id', id);
  }
}
