import '../../../../core/services/supabase_provider.dart';
import 'profile_data_source.dart';

class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseProfileDataSource(this._supabase);

  final SupabaseProvider _supabase;

  static const String _profiles = 'profiles';
  static const String _addresses = 'addresses';

  @override
  Future<Map<String, dynamic>?> profile(String userId) async {
    final client = await _supabase.client;
    return client.from(_profiles).select().eq('id', userId).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> row) async {
    final client = await _supabase.client;
    final payload = Map<String, dynamic>.from(row)
      ..remove('email')
      ..remove('created_at')
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final updated = await client.from(_profiles).update(payload).eq('id', row['id']).select().single();
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<List<Map<String, dynamic>>> addresses(String userId) async {
    final client = await _supabase.client;
    final rows = await client
        .from(_addresses)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<Map<String, dynamic>> saveAddress(Map<String, dynamic> row) async {
    final client = await _supabase.client;
    final saved = await client.from(_addresses).upsert(row).select().single();
    return Map<String, dynamic>.from(saved);
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    final client = await _supabase.client;
    await client.from(_addresses).delete().eq('id', addressId);
  }
}
