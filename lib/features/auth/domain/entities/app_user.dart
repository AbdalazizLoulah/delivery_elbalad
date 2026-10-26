import 'package:equatable/equatable.dart';

/// أدوار المستخدمين في التطبيق.
enum UserRole {
  buyer,
  seller,
  courier;

  static UserRole fromApi(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.buyer,
    );
  }
}

/// كيان المستخدم - نقي من أي تفاصيل تقنية (Dart only).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone = '',
    this.avatarUrl,
    this.rating = 0,
    this.ratingsCount = 0,
    this.lat,
    this.lng,
    this.addressText,
    this.isAvailable = false,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String phone;
  final String? avatarUrl;

  /// تقييم المستخدم (بيستخدم لتقييم الدليفاري والبائع).
  final double rating;
  final int ratingsCount;

  /// موقع المتجر (للبائع) أو الموقع الحالي (للدليفاري).
  final double? lat;
  final double? lng;
  final String? addressText;

  /// متاح لاستلام طلبات؟ (للدليفاري بس)
  final bool isAvailable;
  final DateTime? createdAt;

  bool get hasLocation => lat != null && lng != null;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    double? rating,
    int? ratingsCount,
    double? lat,
    double? lng,
    String? addressText,
    bool? isAvailable,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      addressText: addressText ?? this.addressText,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        role,
        phone,
        avatarUrl,
        rating,
        ratingsCount,
        lat,
        lng,
        addressText,
        isAvailable,
      ];
}
