import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_data_source.dart';
import '../models/product_model.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._dataSource);

  final CatalogDataSource _dataSource;

  @override
  Future<Result<List<Category>>> categories() {
    return guard(() async {
      final rows = await _dataSource.categories();
      return rows.map(CategoryModel.fromJson).cast<Category>().toList();
    });
  }

  @override
  Future<Result<List<Product>>> products({
    String? categoryId,
    String? query,
    String? sellerId,
    bool onlyActive = true,
  }) {
    return guard(() async {
      final rows = await _dataSource.products(
        categoryId: categoryId,
        query: query,
        sellerId: sellerId,
        onlyActive: onlyActive,
      );
      return rows.map(ProductModel.fromJson).cast<Product>().toList();
    });
  }

  @override
  Future<Result<Product>> product(String id) {
    return guard(() async {
      final row = await _dataSource.product(id);
      if (row == null) throw const NotFoundException('المنتج غير موجود أو تم حذفه.');
      return ProductModel.fromJson(row);
    });
  }

  @override
  Future<Result<Product>> saveProduct(Product product) {
    return guard(() async {
      if (product.title.trim().isEmpty) {
        throw const AppException('عنوان المنتج مطلوب.');
      }
      if (product.price <= 0) {
        throw const AppException('سعر المنتج لازم يكون أكبر من صفر.');
      }
      final row = await _dataSource.saveProduct(ProductModel.fromEntity(product).toJson());
      return ProductModel.fromJson(row);
    });
  }

  @override
  Future<Result<void>> deleteProduct(String id) => guard(() => _dataSource.deleteProduct(id));
}
