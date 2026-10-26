import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    required super.userId,
    required super.label,
    required super.details,
    required super.lat,
    required super.lng,
    super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: JsonX.str(json, 'id'),
        userId: JsonX.str(json, 'user_id'),
        label: JsonX.str(json, 'label'),
        details: JsonX.str(json, 'details'),
        lat: JsonX.dbl(json, 'lat'),
        lng: JsonX.dbl(json, 'lng'),
        isDefault: JsonX.boolean(json, 'is_default'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'label': label,
        'details': details,
        'lat': lat,
        'lng': lng,
        'is_default': isDefault,
      };

  factory AddressModel.fromEntity(Address address) => AddressModel(
        id: address.id,
        userId: address.userId,
        label: address.label,
        details: address.details,
        lat: address.lat,
        lng: address.lng,
        isDefault: address.isDefault,
      );
}
