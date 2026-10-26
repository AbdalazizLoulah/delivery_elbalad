import 'package:equatable/equatable.dart';

/// عنوان المستخدم المحفوظ (مع إحداثيات لتحديد الموقع على الخريطة).
class Address extends Equatable {
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.details,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String label;
  final String details;
  final double lat;
  final double lng;
  final bool isDefault;

  Address copyWith({
    String? label,
    String? details,
    double? lat,
    double? lng,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      userId: userId,
      label: label ?? this.label,
      details: details ?? this.details,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, userId, label, details, lat, lng, isDefault];
}
