import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/domain/usecases/catalog_usecases.dart';

part 'seller_products_event.dart';
part 'seller_products_state.dart';

/// بلوك منتجات البائع (إضافة / تعديل / حذف).
class SellerProductsBloc extends Bloc<SellerProductsEvent, SellerProductsState> {
  SellerProductsBloc({
    required this._getProducts,
    required this._saveProduct,
    required this._deleteProduct,
  }) : super(const SellerProductsState()) {
    on<SellerProductsStarted>(_onStarted);
    on<SellerProductSaved>(_onSaved);
    on<SellerProductDeleted>(_onDeleted);
  }

  final GetProductsUseCase _getProducts;
  final SaveProductUseCase _saveProduct;
  final DeleteProductUseCase _deleteProduct;

  Future<void> _onStarted(SellerProductsStarted event, Emitter<SellerProductsState> emit) async {
    emit(state.copyWith(isLoading: true, sellerId: event.sellerId, clearError: true));
    final result = await _getProducts(GetProductsParams(
      sellerId: event.sellerId,
      onlyActive: false,
    ));
    result.fold(
      (products) => emit(state.copyWith(products: products, isLoading: false)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onSaved(SellerProductSaved event, Emitter<SellerProductsState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _saveProduct(event.product);
    result.fold(
      (saved) {
        final products = [...state.products];
        final index = products.indexWhere((product) => product.id == saved.id);
        if (index == -1) {
          products.insert(0, saved);
        } else {
          products[index] = saved;
        }
        emit(state.copyWith(products: products, isSaving: false, savedProductId: saved.id));
      },
      (failure) => emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onDeleted(SellerProductDeleted event, Emitter<SellerProductsState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _deleteProduct(event.productId);
    result.fold(
      (_) => emit(state.copyWith(
        isSaving: false,
        products: state.products.where((product) => product.id != event.productId).toList(),
      )),
      (failure) => emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
    );
  }
}
