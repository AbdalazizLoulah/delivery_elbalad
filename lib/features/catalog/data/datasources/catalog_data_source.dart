/// عقد مصدر بيانات الكتالوج (منتجات + تصنيفات).
abstract interface class CatalogDataSource {
  Future<List<Map<String, dynamic>>> categories();

  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    String? query,
    String? sellerId,
    bool onlyActive,
  });

  Future<Map<String, dynamic>?> product(String id);

  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> row);

  Future<void> deleteProduct(String id);
}
