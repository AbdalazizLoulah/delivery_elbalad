part of 'addresses_bloc.dart';

class AddressesState extends Equatable {
  const AddressesState({
    this.addresses = const [],
    this.userId = '',
    this.isLoading = false,
    this.isSaving = false,
    this.savedAddress,
    this.errorMessage,
  });

  final List<Address> addresses;
  final String userId;
  final bool isLoading;
  final bool isSaving;
  final Address? savedAddress;
  final String? errorMessage;

  Address? get defaultAddress => addresses.where((address) => address.isDefault).firstOrNull;

  AddressesState copyWith({
    List<Address>? addresses,
    String? userId,
    bool? isLoading,
    bool? isSaving,
    Address? savedAddress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      savedAddress: savedAddress ?? this.savedAddress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [addresses, userId, isLoading, isSaving, savedAddress, errorMessage];
}
