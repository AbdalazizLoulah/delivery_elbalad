import '../../../../core/demo/demo_database.dart';
import '../../../../core/error/exceptions.dart';
import 'profile_data_source.dart';

class LocalProfileDataSource implements ProfileDataSource {
  LocalProfileDataSource(this._db);

  final DemoDatabase _db;

  @override
  Future<Map<String, dynamic>?> profile(String userId) async => _db.row('profiles', userId);

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> row) async {
    final existing = _db.row('profiles', row['id'] as String);
    if (existing == null) throw const NotFoundException('المستخدم غير موجود.');
    _db.upsert('profiles', {...existing, ...row});
    return _db.row('profiles', row['id'] as String)!;
  }

  @override
  Future<List<Map<String, dynamic>>> addresses(String userId) async {
    return _db.rows('addresses').where((row) => row['user_id'] == userId).toList();
  }

  @override
  Future<Map<String, dynamic>> saveAddress(Map<String, dynamic> row) async {
    _db.upsert('addresses', row);
    if (row['is_default'] == true) {
      for (final address in _db.rows('addresses')) {
        if (address['user_id'] == row['user_id'] && address['id'] != row['id']) {
          _db.patch('addresses', address['id'] as String, {'is_default': false});
        }
      }
    }
    return _db.row('addresses', row['id'] as String)!;
  }

  @override
  Future<void> deleteAddress(String addressId) async => _db.remove('addresses', addressId);
}
