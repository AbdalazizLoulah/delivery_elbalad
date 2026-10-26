import '../../../../core/utils/json_utils.dart';
import '../../../auth/domain/entities/app_user.dart';

/// نموذج المستخدم - مسؤول عن التحويل بين الـ JSON والكيان.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.rating,
    super.ratingsCount,
    super.lat,
    super.lng,
    super.addressText,
    super.isAvailable,
    super.createdAt,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: JsonX.str(json, 'id'),
      fullName: JsonX.str(json, 'full_name'),
      email: JsonX.str(json, 'email'),
      role: UserRole.fromApi(JsonX.str(json, 'role')),
      phone: JsonX.str(json, 'phone'),
      avatarUrl: JsonX.strOrNull(json, 'avatar_url'),
      rating: JsonX.dbl(json, 'rating'),
      ratingsCount: JsonX.integer(json, 'ratings_count'),
      lat: JsonX.dblOrNull(json, 'lat'),
      lng: JsonX.dblOrNull(json, 'lng'),
      addressText: JsonX.strOrNull(json, 'address_text'),
      isAvailable: JsonX.boolean(json, 'is_available'),
      createdAt: JsonX.dateOrNull(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role.name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'rating': rating,
        'ratings_count': ratingsCount,
        'lat': lat,
        'lng': lng,
        'address_text': addressText,
        'is_available': isAvailable,
      };

  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        rating: user.rating,
        ratingsCount: user.ratingsCount,
        lat: user.lat,
        lng: user.lng,
        addressText: user.addressText,
        isAvailable: user.isAvailable,
        createdAt: user.createdAt,
      );
}
