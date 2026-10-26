import '../../../../core/result/result.dart';
import '../entities/product.dart';

abstract interface class CatalogRepository {
  Future<Result<List<Category>>> categories();

  Future<Result<List<Product>>> products({
    String? categoryId,
    String? query,
    String? sellerId,
    bool onlyActive = true,
  });

  Future<Result<Product>> product(String id);

  Future<Result<Product>> saveProduct(Product product);

  Future<Result<void>> deleteProduct(String id);
}
