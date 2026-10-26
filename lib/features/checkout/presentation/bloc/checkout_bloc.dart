import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../cart/domain/entities/cart_line.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/usecases/order_usecases.dart';
import '../../../profile/domain/entities/address.dart';
import '../../../profile/domain/usecases/profile_usecases.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

/// بلوك إتمام الشراء: العنوان على الخريطة + طريقة الدفع + إنشاء الطلبات.
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc({
    required this._getAddresses,
    required this._saveAddress,
    required this._placeOrder,
    required this._locationService,
    required this._geocodingService,
  }) : super(const CheckoutState()) {
    on<CheckoutStarted>(_onStarted);
    on<CheckoutAddressSelected>(_onAddressSelected);
    on<CheckoutLocationPicked>(_onLocationPicked);
    on<CheckoutCurrentLocationRequested>(_onCurrentLocationRequested);
    on<CheckoutPaymentMethodSelected>(_onPaymentMethodSelected);
    on<CheckoutNoteChanged>(_onNoteChanged);
    on<CheckoutSubmitted>(_onSubmitted);
  }

  final GetAddressesUseCase _getAddresses;
  final SaveAddressUseCase _saveAddress;
  final PlaceOrderUseCase _placeOrder;
  final LocationService _locationService;
  final GeocodingService _geocodingService;

  Future<void> _onStarted(CheckoutStarted event, Emitter<CheckoutState> emit) async {
    emit(state.copyWith(isLoading: true, user: event.user, clearError: true));
    final result = await _getAddresses(event.user.id);
    result.fold(
      (addresses) => emit(state.copyWith(
        addresses: addresses,
        isLoading: false,
        selectedAddress: state.selectedAddress ??
            addresses.where((address) => address.isDefault).firstOrNull ??
            addresses.firstOrNull,
      )),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }

  void _onAddressSelected(CheckoutAddressSelected event, Emitter<CheckoutState> emit) {
    emit(state.copyWith(selectedAddress: event.address, clearError: true));
  }

  Future<void> _onLocationPicked(CheckoutLocationPicked event, Emitter<CheckoutState> emit) async {
    final user = state.user;
    if (user == null) return;

    final address = Address(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      userId: user.id,
      label: event.label,
      details: event.details,
      lat: event.lat,
      lng: event.lng,
      isDefault: state.addresses.isEmpty,
    );

    emit(state.copyWith(selectedAddress: address, isSavingAddress: true, clearError: true));
    final result = await _saveAddress(address);
    result.fold(
      (saved) => emit(state.copyWith(
        isSavingAddress: false,
        selectedAddress: saved,
        addresses: [
          saved,
          ...state.addresses.where((item) => item.id != saved.id),
        ],
      )),
      (failure) => emit(state.copyWith(isSavingAddress: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onCurrentLocationRequested(
    CheckoutCurrentLocationRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(isLocating: true, clearError: true));
    try {
      final point = await _locationService.currentPosition();
      final details = await _geocodingService.addressFromCoordinates(point);
      emit(state.copyWith(isLocating: false, pickedPoint: point, pickedAddressText: details));
    } catch (error) {
      emit(state.copyWith(
        isLocating: false,
        errorMessage: error is AppException ? error.message : error.toString(),
      ));
    }
  }

  void _onPaymentMethodSelected(CheckoutPaymentMethodSelected event, Emitter<CheckoutState> emit) {
    emit(state.copyWith(paymentMethod: event.method, clearError: true));
  }

  void _onNoteChanged(CheckoutNoteChanged event, Emitter<CheckoutState> emit) {
    emit(state.copyWith(note: event.note));
  }

  Future<void> _onSubmitted(CheckoutSubmitted event, Emitter<CheckoutState> emit) async {
    final user = state.user;
    final address = state.selectedAddress;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'لازم تسجل دخول الأول.'));
      return;
    }
    if (address == null) {
      emit(state.copyWith(errorMessage: 'اختار عنوان التوصيل من الخريطة.'));
      return;
    }
    if (event.lines.isEmpty) {
      emit(state.copyWith(errorMessage: 'السلة فاضية.'));
      return;
    }
    if (state.paymentMethod == PaymentMethod.visa && !event.cardValidated) {
      emit(state.copyWith(errorMessage: 'بيانات الكارت غير مكتملة.'));
      return;
    }

    emit(state.copyWith(isPlacing: true, clearError: true));
    final result = await _placeOrder(PlaceOrderParams(
      buyer: user,
      linesBySeller: event.linesBySeller,
      address: address,
      paymentMethod: state.paymentMethod,
      deliveryFeePerOrder: AppConfig.baseDeliveryFee,
      note: state.note,
    ));

    result.fold(
      (orders) => emit(state.copyWith(isPlacing: false, createdOrders: orders)),
      (failure) => emit(state.copyWith(isPlacing: false, errorMessage: failure.message)),
    );
  }
}

/// بيسهل على الواجهة تمرير خطوط السلة مجمعة حسب البائع.
extension CartLinesGrouping on List<CartLine> {
  Map<String, List<CartLine>> get bySeller => CartSummary.fromLines(this).bySeller;
}
