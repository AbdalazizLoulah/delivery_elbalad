/// عقد مصدر بيانات البروفايل والعناوين.
abstract interface class ProfileDataSource {
  Future<Map<String, dynamic>?> profile(String userId);

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> row);

  Future<List<Map<String, dynamic>>> addresses(String userId);

  Future<Map<String, dynamic>> saveAddress(Map<String, dynamic> row);

  Future<void> deleteAddress(String addressId);
}
