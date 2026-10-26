import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/domain/usecases/catalog_usecases.dart';

part 'catalog_event.dart';
part 'catalog_state.dart';

/// بلوك الصفحة الرئيسية للمشتري: التصنيفات + المنتجات + البحث.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({
    required this._getCategories,
    required this._getProducts,
  }) : super(const CatalogState()) {
    on<CatalogStarted>(_onStarted);
    on<CatalogCategorySelected>(_onCategorySelected);
    on<CatalogSearchChanged>(_onSearchChanged);
  }

  final GetCategoriesUseCase _getCategories;
  final GetProductsUseCase _getProducts;

  Future<void> _onStarted(CatalogStarted event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final categoriesResult = await _getCategories(const NoParams());
    final productsResult = await _getProducts(const GetProductsParams());

    final failure = categoriesResult.failure ?? productsResult.failure;
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      return;
    }

    emit(state.copyWith(
      isLoading: false,
      categories: categoriesResult.data ?? const [],
      products: productsResult.data ?? const [],
      clearError: true,
    ));
  }

  Future<void> _onCategorySelected(CatalogCategorySelected event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearCategory: event.categoryId == null,
      isLoading: true,
    ));
    final result = await _getProducts(GetProductsParams(
      categoryId: event.categoryId,
      query: state.query,
    ));
    result.fold(
      (products) => emit(state.copyWith(products: products, isLoading: false, clearError: true)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onSearchChanged(CatalogSearchChanged event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(query: event.query, isLoading: true));
    final result = await _getProducts(GetProductsParams(
      categoryId: state.selectedCategoryId,
      query: event.query,
    ));
    result.fold(
      (products) => emit(state.copyWith(products: products, isLoading: false, clearError: true)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }
}
