part of 'checkout_bloc.dart';

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

final class CheckoutStarted extends CheckoutEvent {
  const CheckoutStarted(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user.id];
}

final class CheckoutAddressSelected extends CheckoutEvent {
  const CheckoutAddressSelected(this.address);

  final Address address;

  @override
  List<Object?> get props => [address.id];
}

/// المستخدم اختار نقطة على الخريطة وأدخل وصف العنوان.
final class CheckoutLocationPicked extends CheckoutEvent {
  const CheckoutLocationPicked({
    required this.lat,
    required this.lng,
    required this.label,
    required this.details,
  });

  final double lat;
  final double lng;
  final String label;
  final String details;

  @override
  List<Object?> get props => [lat, lng, label, details];
}

final class CheckoutCurrentLocationRequested extends CheckoutEvent {
  const CheckoutCurrentLocationRequested();
}

final class CheckoutPaymentMethodSelected extends CheckoutEvent {
  const CheckoutPaymentMethodSelected(this.method);

  final PaymentMethod method;

  @override
  List<Object?> get props => [method];
}

final class CheckoutNoteChanged extends CheckoutEvent {
  const CheckoutNoteChanged(this.note);

  final String note;

  @override
  List<Object?> get props => [note];
}

final class CheckoutSubmitted extends CheckoutEvent {
  const CheckoutSubmitted({
    required this.lines,
    this.cardValidated = false,
  });

  final List<CartLine> lines;
  final bool cardValidated;

  Map<String, List<CartLine>> get linesBySeller => CartSummary.fromLines(lines).bySeller;

  @override
  List<Object?> get props => [lines, cardValidated];
}
