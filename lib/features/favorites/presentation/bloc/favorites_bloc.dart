import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/domain/usecases/catalog_usecases.dart';
import '../../domain/usecases/favorites_usecases.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

/// بلوك المفضلة: بيحفظ المعرفات على الجهاز وبيجيب تفاصيل المنتجات من الكتالوج.
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required this._loadFavorites,
    required this._saveFavorites,
    required this._getProducts,
  }) : super(const FavoritesState()) {
    on<FavoritesStarted>(_onStarted);
    on<FavoriteToggled>(_onToggled);
  }

  final LoadFavoritesUseCase _loadFavorites;
  final SaveFavoritesUseCase _saveFavorites;
  final GetProductsUseCase _getProducts;

  Future<void> _onStarted(FavoritesStarted event, Emitter<FavoritesState> emit) async {
    if (event.userId.isEmpty) {
      emit(state.copyWith(ids: const [], products: const [], isLoading: false));
      return;
    }
    emit(state.copyWith(isLoading: true, userId: event.userId, clearError: true));
    final idsResult = await _loadFavorites(event.userId);
    final productsResult = await _getProducts(const GetProductsParams());

    if (idsResult.isFailure) {
      emit(state.copyWith(isLoading: false, errorMessage: idsResult.failure!.message));
      return;
    }

    final ids = idsResult.data!;
    final allProducts = productsResult.data ?? <Product>[];
    emit(state.copyWith(
      isLoading: false,
      ids: ids,
      products: allProducts.where((product) => ids.contains(product.id)).toList(),
      allProducts: allProducts,
    ));
  }

  Future<void> _onToggled(FavoriteToggled event, Emitter<FavoritesState> emit) async {
    final ids = [...state.ids];
    final isFavorite = ids.contains(event.product.id);
    if (isFavorite) {
      ids.remove(event.product.id);
    } else {
      ids.add(event.product.id);
    }

    final products = [...state.products];
    if (isFavorite) {
      products.removeWhere((product) => product.id == event.product.id);
    } else {
      products.insert(0, event.product);
    }

    final allProducts = [...state.allProducts];
    if (!allProducts.any((product) => product.id == event.product.id)) {
      allProducts.add(event.product);
    }

    emit(state.copyWith(
      ids: ids,
      products: products,
      allProducts: allProducts,
      lastToggledId: event.product.id,
      lastActionWasRemove: isFavorite,
    ));

    final result = await _saveFavorites(SaveFavoritesParams(userId: state.userId, productIds: ids));
    result.fold((_) {}, (failure) => emit(state.copyWith(errorMessage: failure.message)));
  }
}
