part of 'catalog_bloc.dart';

class CatalogState extends Equatable {
  const CatalogState({
    this.categories = const [],
    this.products = const [],
    this.selectedCategoryId,
    this.query = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Category> categories;
  final List<Product> products;
  final String? selectedCategoryId;
  final String query;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => !isLoading && products.isEmpty;

  CatalogState copyWith({
    List<Category>? categories,
    List<Product>? products,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? query,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [categories, products, selectedCategoryId, query, isLoading, errorMessage];
}
