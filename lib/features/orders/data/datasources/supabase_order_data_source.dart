import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/supabase_provider.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../domain/entities/order.dart';
import 'order_data_source.dart';

/// مصدر الطلبات على Supabase (Realtime على orders و order_events و courier_locations).
class SupabaseOrderDataSource implements OrderDataSource {
  SupabaseOrderDataSource(this._supabase);

  final SupabaseProvider _supabase;

  static const String _orders = 'orders';
  static const String _items = 'order_items';
  static const String _events = 'order_events';
  static const String _locations = 'courier_locations';
  static const String _profiles = 'profiles';
  static const String _products = 'products';

  /// بنجيب الطلب كامل بالعناصر والأحداث في نداء واحد.
  static const String _select = '*, order_items(*), order_events(*)';

  static const List<String> _finalStatuses = ['delivered', 'cancelled'];

  @override
  Future<List<Map<String, dynamic>>> buyerOrders(String buyerId) async {
    final client = await _supabase.client;
    final rows = await client
        .from(_orders)
        .select(_select)
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);
    return _asList(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> sellerOrders(String sellerId) async {
    final client = await _supabase.client;
    final rows = await client
        .from(_orders)
        .select(_select)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return _asList(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> courierOrders(String courierId, {required bool onlyActive}) async {
    final client = await _supabase.client;
    final rows = await client
        .from(_orders)
        .select(_select)
        .eq('courier_id', courierId)
        .order('created_at', ascending: false);
    return _asList(rows)
        .where((row) => !onlyActive || !_finalStatuses.contains(row['status']))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> offeredOrders(String courierId) async {
    final client = await _supabase.client;
    final rows = await client
        .from(_orders)
        .select(_select)
        .eq('offered_courier_id', courierId)
        .eq('status', OrderStatus.readyForPickup.name)
        .order('created_at', ascending: false);
    return _asList(rows)
        .where((row) => row['courier_id'] == null && _sameServiceCountry(row))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> availableOrders({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final client = await _supabase.client;
    final rows = await client
        .from(_orders)
        .select(_select)
        .eq('status', OrderStatus.readyForPickup.name)
        .order('created_at', ascending: false);

    final result = _asList(rows).where((row) {
      if (row['courier_id'] != null) return false;
      final storeLat = (row['store_lat'] as num?)?.toDouble();
      final storeLng = (row['store_lng'] as num?)?.toDouble();
      // من غير موقع متجر مؤكد مينفعش نحسب قرب الطيار.
      if (storeLat == null || storeLng == null) return false;
      if (!_sameServiceCountry(row)) return false;
      final distance = DistanceCalculator.betweenKm(
        fromLat: lat,
        fromLng: lng,
        toLat: storeLat,
        toLng: storeLng,
      );
      return distance <= radiusKm;
    }).toList();

    result.sort((a, b) {
      double distanceOf(Map<String, dynamic> row) {
        final storeLat = (row['store_lat'] as num?)?.toDouble();
        final storeLng = (row['store_lng'] as num?)?.toDouble();
        if (storeLat == null || storeLng == null) return double.infinity;
        return DistanceCalculator.betweenKm(
          fromLat: lat,
          fromLng: lng,
          toLat: storeLat,
          toLng: storeLng,
        );
      }

      return distanceOf(a).compareTo(distanceOf(b));
    });
    return result;
  }

  @override
  Future<Map<String, dynamic>?> order(String orderId) async {
    final client = await _supabase.client;
    return client.from(_orders).select(_select).eq('id', orderId).maybeSingle();
  }

  @override
  Stream<Map<String, dynamic>> watchOrder(String orderId) async* {
    final initial = await order(orderId);
    if (initial != null) yield initial;

    final client = await _supabase.client;
    final stream = client
        .from(_orders)
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .asyncMap((rows) async {
          // أي تغيير في صف الطلب بنجيب معاه العناصر والأحداث المحدثة.
          final fresh = await order(orderId);
          if (fresh != null) return fresh;
          return rows.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(rows.first);
        });

    await for (final row in stream) {
      if (row.isNotEmpty) yield row;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderRow,
    List<Map<String, dynamic>> itemRows,
  ) async {
    final client = await _supabase.client;
    final orderId = orderRow['id'] as String;
    final payload = Map<String, dynamic>.from(orderRow)
      ..remove('order_items')
      ..remove('order_events')
      ..remove('seller')
      ..remove('category');

    await client.from(_orders).upsert(payload);
    if (itemRows.isNotEmpty) {
      await client.from(_items).insert(itemRows);
    }
    await client.from(_events).insert({
      'order_id': orderId,
      'status': OrderStatus.pendingSeller.name,
      'note': 'تم إنشاء الطلب',
      'actor_name': orderRow['buyer_name'] ?? '',
    });

    final created = await order(orderId);
    return created ?? payload;
  }

  @override
  Future<void> decrementStock({
    required String productId,
    required int quantity,
    String title = '',
  }) async {
    if (quantity <= 0) return;
    final client = await _supabase.client;

    // الأفضل: دالة SQL ذرّية (موجودة في supabase/stock_functions.sql).
    // لو المشروع لسه ما اتعملوش migration، بنرجع لقراءة وتحديث آمن.
    try {
      await client.rpc('decrement_product_stock', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
      });
      return;
    } on PostgrestException catch (error) {
      if (_isInsufficientStock(error)) {
        throw AppException(_stockMessage(title));
      }
      if (!_isMissingRpc(error)) rethrow;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      final row = await client
          .from(_products)
          .select('stock, title')
          .eq('id', productId)
          .maybeSingle();
      if (row == null) {
        throw const NotFoundException('المنتج مش موجود.');
      }
      final stock = (row['stock'] as num?)?.toInt() ?? 0;
      final label = title.isNotEmpty ? title : '${row['title'] ?? 'المنتج'}';
      if (stock < quantity) {
        throw AppException(_stockMessage(label, available: stock));
      }
      final updated = await client
          .from(_products)
          .update({'stock': stock - quantity})
          .eq('id', productId)
          .eq('stock', stock)
          .select('id');
      if ((updated as List).isNotEmpty) return;
    }
    throw const AppException('مش قادرين نحدّث المخزون، حاول تاني.');
  }

  @override
  Future<void> incrementStock({
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    final client = await _supabase.client;

    try {
      await client.rpc('increment_product_stock', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
      });
      return;
    } on PostgrestException catch (error) {
      if (!_isMissingRpc(error)) rethrow;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      final row = await client
          .from(_products)
          .select('stock')
          .eq('id', productId)
          .maybeSingle();
      if (row == null) return;
      final stock = (row['stock'] as num?)?.toInt() ?? 0;
      final updated = await client
          .from(_products)
          .update({'stock': stock + quantity})
          .eq('id', productId)
          .eq('stock', stock)
          .select('id');
      if ((updated as List).isNotEmpty) return;
    }
  }

  bool _isMissingRpc(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST202' ||
        message.contains('could not find the function') ||
        (message.contains('function') && message.contains('does not exist'));
  }

  bool _isInsufficientStock(PostgrestException error) {
    return error.message.toUpperCase().contains('INSUFFICIENT_STOCK');
  }

  String _stockMessage(String title, {int? available}) {
    final label = title.isEmpty ? 'المنتج' : title;
    if (available == null) {
      return 'الكمية المطلوبة من "$label" مش متاحة في المخزون.';
    }
    return 'الكمية المطلوبة من "$label" مش متاحة. المتاح $available بس.';
  }

  @override
  Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> patch) async {
    final client = await _supabase.client;
    final payload = Map<String, dynamic>.from(patch)
      ..remove('order_items')
      ..remove('order_events')
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final updated = await client.from(_orders).update(payload).eq('id', orderId).select().single();
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<void> addEvent(
    String orderId, {
    required String status,
    String note = '',
    String actorName = '',
  }) async {
    final client = await _supabase.client;
    await client.from(_events).insert({
      'order_id': orderId,
      'status': status,
      'note': note,
      'actor_name': actorName,
    });
  }

  @override
  Future<void> rateDelivery({
    required String orderId,
    required String courierId,
    required int rating,
    String comment = '',
    String buyerName = '',
  }) async {
    await updateOrder(orderId, {
      'delivery_rating': rating,
      'delivery_review': comment,
    });

    final client = await _supabase.client;
    final courier = await client
        .from(_profiles)
        .select('rating, ratings_count')
        .eq('id', courierId)
        .maybeSingle();
    if (courier == null) return;

    final count = (courier['ratings_count'] as num?)?.toInt() ?? 0;
    final current = (courier['rating'] as num?)?.toDouble() ?? 0;
    final newCount = count + 1;
    final newRating = ((current * count) + rating) / newCount;

    await client.from(_profiles).update({
      'rating': double.parse(newRating.toStringAsFixed(2)),
      'ratings_count': newCount,
    }).eq('id', courierId);
  }

  @override
  Future<void> assignCourier({
    required String orderId,
    required String courierId,
    required bool asOffer,
  }) async {
    await updateOrder(orderId, {
      if (asOffer) 'offered_courier_id': courierId,
      if (!asOffer) 'courier_id': courierId,
      if (!asOffer) 'offered_courier_id': null,
    });
  }

  @override
  Future<void> pushLocation({
    required String courierId,
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    final client = await _supabase.client;
    await client.from(_locations).upsert({
      'courier_id': courierId,
      'lat': lat,
      'lng': lng,
      'order_id': orderId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await client.from(_profiles).update({'lat': lat, 'lng': lng}).eq('id', courierId);
  }

  @override
  Future<Map<String, dynamic>?> courierLocation(String courierId) async {
    final client = await _supabase.client;
    return client.from(_locations).select().eq('courier_id', courierId).maybeSingle();
  }

  @override
  Stream<Map<String, dynamic>> watchCourierLocation(String courierId) async* {
    final client = await _supabase.client;
    yield* client
        .from(_locations)
        .stream(primaryKey: ['courier_id'])
        .eq('courier_id', courierId)
        .where((rows) => rows.isNotEmpty)
        .map((rows) => Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<void> setAvailability({
    required String courierId,
    required bool isAvailable,
    required double lat,
    required double lng,
  }) async {
    final client = await _supabase.client;
    await client.from(_profiles).update({
      'is_available': isAvailable,
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', courierId);

    await client.from(_locations).upsert({
      'courier_id': courierId,
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> availableCouriers() async {
    final client = await _supabase.client;
    final rows = await client
        .from(_profiles)
        .select()
        .eq('role', 'courier')
        .eq('is_available', true);
    return _asList(rows);
  }

  @override
  Future<Map<String, dynamic>?> profile(String userId) async {
    final client = await _supabase.client;
    return client.from(_profiles).select().eq('id', userId).maybeSingle();
  }

  /// المتجر والعميل لازم يكونوا في نفس البلد (لو الإحداثيات معروفة).
  bool _sameServiceCountry(Map<String, dynamic> row) {
    final storeCountry = Countries.byCoordinates(
      (row['store_lat'] as num?)?.toDouble(),
      (row['store_lng'] as num?)?.toDouble(),
    );
    final buyerCountry = Countries.byCoordinates(
          (row['address_lat'] as num?)?.toDouble(),
          (row['address_lng'] as num?)?.toDouble(),
        ) ??
        Countries.fromPhone(row['buyer_phone'] as String?, fallback: Countries.egypt);
    if (storeCountry == null || buyerCountry == null) return true;
    return storeCountry.code == buyerCountry.code;
  }

  List<Map<String, dynamic>> _asList(List<dynamic> rows) =>
      rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
}
