import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/address.dart';
import '../../domain/usecases/profile_usecases.dart';

part 'addresses_event.dart';
part 'addresses_state.dart';

/// بلوك عناوين المستخدم (إضافة / تعديل / حذف).
class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  AddressesBloc({
    required this._getAddresses,
    required this._saveAddress,
    required this._deleteAddress,
  }) : super(const AddressesState()) {
    on<AddressesStarted>(_onStarted);
    on<AddressSaved>(_onSaved);
    on<AddressDeleted>(_onDeleted);
  }

  final GetAddressesUseCase _getAddresses;
  final SaveAddressUseCase _saveAddress;
  final DeleteAddressUseCase _deleteAddress;

  Future<void> _onStarted(AddressesStarted event, Emitter<AddressesState> emit) async {
    emit(state.copyWith(isLoading: true, userId: event.userId, clearError: true));
    final result = await _getAddresses(event.userId);
    result.fold(
      (addresses) => emit(state.copyWith(addresses: addresses, isLoading: false)),
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onSaved(AddressSaved event, Emitter<AddressesState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _saveAddress(event.address);
    result.fold(
      (saved) {
        final addresses = [
          saved,
          ...state.addresses.where((address) => address.id != saved.id),
        ];
        emit(state.copyWith(
          isSaving: false,
          addresses: saved.isDefault
              ? [
                  for (final address in addresses)
                    address.isDefault && address.id != saved.id
                        ? address.copyWith(isDefault: false)
                        : address,
                ]
              : addresses,
          savedAddress: saved,
        ));
      },
      (failure) => emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
    );
  }

  Future<void> _onDeleted(AddressDeleted event, Emitter<AddressesState> emit) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _deleteAddress(event.addressId);
    result.fold(
      (_) => emit(state.copyWith(
        isSaving: false,
        addresses: state.addresses.where((address) => address.id != event.addressId).toList(),
      )),
      (failure) => emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
    );
  }
}
