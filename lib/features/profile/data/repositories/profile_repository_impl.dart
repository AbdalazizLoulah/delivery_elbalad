import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/result/result.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';
import '../models/address_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dataSource);

  final ProfileDataSource _dataSource;

  @override
  Future<Result<AppUser>> profile(String userId) {
    return guard(() async {
      final row = await _dataSource.profile(userId);
      if (row == null) throw const NotFoundException('مفيش بيانات للمستخدم دا.');
      return AppUserModel.fromJson(row);
    });
  }

  @override
  Future<Result<AppUser>> updateProfile(AppUser user) {
    return guard(() async {
      if (user.fullName.trim().isEmpty) {
        throw const AppException('الاسم مطلوب.');
      }
      final row = await _dataSource.updateProfile(AppUserModel.fromEntity(user).toJson());
      return AppUserModel.fromJson(row);
    });
  }

  @override
  Future<Result<List<Address>>> addresses(String userId) {
    return guard(() async {
      final rows = await _dataSource.addresses(userId);
      return rows.map(AddressModel.fromJson).cast<Address>().toList();
    });
  }

  @override
  Future<Result<Address>> saveAddress(Address address) {
    return guard(() async {
      if (address.details.trim().isEmpty) {
        throw const AppException('اكتب تفاصيل العنوان.');
      }
      final row = await _dataSource.saveAddress(AddressModel.fromEntity(address).toJson());
      return AddressModel.fromJson(row);
    });
  }

  @override
  Future<Result<void>> deleteAddress(String addressId) =>
      guard(() => _dataSource.deleteAddress(addressId));
}
