part of 'seller_products_bloc.dart';

class SellerProductsState extends Equatable {
  const SellerProductsState({
    this.products = const [],
    this.sellerId = '',
    this.isLoading = false,
    this.isSaving = false,
    this.savedProductId,
    this.errorMessage,
  });

  final List<Product> products;
  final String sellerId;
  final bool isLoading;
  final bool isSaving;
  final String? savedProductId;
  final String? errorMessage;

  SellerProductsState copyWith({
    List<Product>? products,
    String? sellerId,
    bool? isLoading,
    bool? isSaving,
    String? savedProductId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerProductsState(
      products: products ?? this.products,
      sellerId: sellerId ?? this.sellerId,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      savedProductId: savedProductId ?? this.savedProductId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [products, sellerId, isLoading, isSaving, savedProductId, errorMessage];
}
