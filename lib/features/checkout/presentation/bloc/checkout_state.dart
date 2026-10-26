part of 'checkout_bloc.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.user,
    this.addresses = const [],
    this.selectedAddress,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
    this.note = '',
    this.isLoading = false,
    this.isSavingAddress = false,
    this.isLocating = false,
    this.isPlacing = false,
    this.errorMessage,
    this.pickedPoint,
    this.pickedAddressText,
    this.createdOrders = const [],
  });

  final AppUser? user;
  final List<Address> addresses;
  final Address? selectedAddress;
  final PaymentMethod paymentMethod;
  final String note;
  final bool isLoading;
  final bool isSavingAddress;
  final bool isLocating;
  final bool isPlacing;
  final String? errorMessage;

  /// آخر نقطة اتحددت من الـ GPS قبل تأكيد العنوان.
  final GeoPoint? pickedPoint;
  final String? pickedAddressText;

  final List<Order> createdOrders;

  bool get hasCreatedOrders => createdOrders.isNotEmpty;

  CheckoutState copyWith({
    AppUser? user,
    List<Address>? addresses,
    Address? selectedAddress,
    PaymentMethod? paymentMethod,
    String? note,
    bool? isLoading,
    bool? isSavingAddress,
    bool? isLocating,
    bool? isPlacing,
    String? errorMessage,
    bool clearError = false,
    GeoPoint? pickedPoint,
    String? pickedAddressText,
    List<Order>? createdOrders,
  }) {
    return CheckoutState(
      user: user ?? this.user,
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      isLoading: isLoading ?? this.isLoading,
      isSavingAddress: isSavingAddress ?? this.isSavingAddress,
      isLocating: isLocating ?? this.isLocating,
      isPlacing: isPlacing ?? this.isPlacing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pickedPoint: pickedPoint ?? this.pickedPoint,
      pickedAddressText: pickedAddressText ?? this.pickedAddressText,
      createdOrders: createdOrders ?? this.createdOrders,
    );
  }

  @override
  List<Object?> get props => [
        user,
        addresses,
        selectedAddress,
        paymentMethod,
        note,
        isLoading,
        isSavingAddress,
        isLocating,
        isPlacing,
        errorMessage,
        pickedPoint,
        pickedAddressText,
        createdOrders,
      ];
}
