part of 'favorites_bloc.dart';

class FavoritesState extends Equatable {
  const FavoritesState({
    this.ids = const [],
    this.products = const [],
    this.allProducts = const [],
    this.userId = '',
    this.isLoading = false,
    this.errorMessage,
    this.lastToggledId,
    this.lastActionWasRemove = false,
  });

  final List<String> ids;
  final List<Product> products;
  final List<Product> allProducts;
  final String userId;
  final bool isLoading;
  final String? errorMessage;
  final String? lastToggledId;
  final bool lastActionWasRemove;

  bool isFavorite(String productId) => ids.contains(productId);

  FavoritesState copyWith({
    List<String>? ids,
    List<Product>? products,
    List<Product>? allProducts,
    String? userId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastToggledId,
    bool? lastActionWasRemove,
  }) {
    return FavoritesState(
      ids: ids ?? this.ids,
      products: products ?? this.products,
      allProducts: allProducts ?? this.allProducts,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastToggledId: lastToggledId ?? this.lastToggledId,
      lastActionWasRemove: lastActionWasRemove ?? this.lastActionWasRemove,
    );
  }

  @override
  List<Object?> get props => [
        ids,
        products,
        allProducts,
        userId,
        isLoading,
        errorMessage,
        lastToggledId,
        lastActionWasRemove,
      ];
}
