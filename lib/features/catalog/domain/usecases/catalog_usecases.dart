import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/catalog_repository.dart';

class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  const GetCategoriesUseCase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Result<List<Category>>> call(NoParams params) => _repository.categories();
}

class GetProductsParams extends Equatable {
  const GetProductsParams({this.categoryId, this.query, this.sellerId, this.onlyActive = true});

  final String? categoryId;
  final String? query;
  final String? sellerId;
  final bool onlyActive;

  @override
  List<Object?> get props => [categoryId, query, sellerId, onlyActive];
}

class GetProductsUseCase implements UseCase<List<Product>, GetProductsParams> {
  const GetProductsUseCase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Result<List<Product>>> call(GetProductsParams params) => _repository.products(
        categoryId: params.categoryId,
        query: params.query,
        sellerId: params.sellerId,
        onlyActive: params.onlyActive,
      );
}

class GetProductDetailsUseCase implements UseCase<Product, String> {
  const GetProductDetailsUseCase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Result<Product>> call(String params) => _repository.product(params);
}

class SaveProductUseCase implements UseCase<Product, Product> {
  const SaveProductUseCase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Result<Product>> call(Product params) => _repository.saveProduct(params);
}

class DeleteProductUseCase implements UseCase<void, String> {
  const DeleteProductUseCase(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.deleteProduct(params);
}
