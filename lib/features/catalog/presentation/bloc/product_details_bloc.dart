import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/domain/usecases/catalog_usecases.dart';

part 'product_details_event.dart';
part 'product_details_state.dart';

/// بلوك تفاصيل المنتج (بيحمّل المنتج من الكتالوج).
class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  ProductDetailsBloc({required this._getProductDetails})
      : super(const ProductDetailsState()) {
    on<ProductDetailsStarted>(_onStarted);
  }

  final GetProductDetailsUseCase _getProductDetails;

  Future<void> _onStarted(ProductDetailsStarted event, Emitter<ProductDetailsState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getProductDetails(event.productId);
    result.fold(
      (product) => emit(state.copyWith(product: product, isLoading: false)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }
}
