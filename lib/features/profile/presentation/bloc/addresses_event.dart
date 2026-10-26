part of 'addresses_bloc.dart';

sealed class AddressesEvent extends Equatable {
  const AddressesEvent();

  @override
  List<Object?> get props => [];
}

final class AddressesStarted extends AddressesEvent {
  const AddressesStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class AddressSaved extends AddressesEvent {
  const AddressSaved(this.address);

  final Address address;

  @override
  List<Object?> get props => [address];
}

final class AddressDeleted extends AddressesEvent {
  const AddressDeleted(this.addressId);

  final String addressId;

  @override
  List<Object?> get props => [addressId];
}
