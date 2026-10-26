part of 'product_details_bloc.dart';

class ProductDetailsState extends Equatable {
  const ProductDetailsState({this.product, this.isLoading = false, this.errorMessage});

  final Product? product;
  final bool isLoading;
  final String? errorMessage;

  ProductDetailsState copyWith({
    Product? product,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductDetailsState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [product, isLoading, errorMessage];
}
