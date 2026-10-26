import '../../../../core/demo/demo_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/countries.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../domain/entities/order.dart';
import 'order_data_source.dart';

/// مصدر الطلبات المحلي - بيحاكي الـ Realtime والفلترة الجغرافية.
class LocalOrderDataSource implements OrderDataSource {
  LocalOrderDataSource(this._db);

  final DemoDatabase _db;

  @override
  Future<List<Map<String, dynamic>>> buyerOrders(String buyerId) async {
    final rows = _db
        .rows('orders')
        .where((row) => row['buyer_id'] == buyerId)
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> sellerOrders(String sellerId) async {
    final rows = _db
        .rows('orders')
        .where((row) => row['seller_id'] == sellerId)
        .toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> courierOrders(String courierId, {required bool onlyActive}) async {
    final rows = _db.rows('orders').where((row) {
      if (row['courier_id'] != courierId) return false;
      if (!onlyActive) return true;
      return !_isFinal(row['status'] as String?);
    }).toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> offeredOrders(String courierId) async {
    final rows = _db
        .rows('orders')
        .where((row) =>
            row['offered_courier_id'] == courierId &&
            row['courier_id'] == null &&
            row['status'] == OrderStatus.readyForPickup.name &&
            _sameServiceCountry(row))
        .toList();
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> availableOrders({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final rows = _db.rows('orders').where((row) {
      if (row['status'] != OrderStatus.readyForPickup.name) return false;
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

    rows.sort((a, b) {
      final first = _distanceFrom(lat, lng, a);
      final second = _distanceFrom(lat, lng, b);
      return first.compareTo(second);
    });
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> order(String orderId) async => _db.row('orders', orderId);

  @override
  Stream<Map<String, dynamic>> watchOrder(String orderId) async* {
    final current = _db.row('orders', orderId);
    if (current != null) yield current;
    await for (final _ in _db.changes) {
      final row = _db.row('orders', orderId);
      if (row != null) yield row;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderRow,
    List<Map<String, dynamic>> itemRows,
  ) async {
    final row = {...orderRow, 'order_items': itemRows, 'order_events': <Map<String, dynamic>>[]};
    _db.upsert('orders', row);
    _db.addOrderEvent(
      orderRow['id'] as String,
      status: OrderStatus.pendingSeller.name,
      note: 'تم إنشاء الطلب',
    );
    return _db.row('orders', orderRow['id'] as String)!;
  }

  @override
  Future<void> decrementStock({
    required String productId,
    required int quantity,
    String title = '',
  }) async {
    if (quantity <= 0) return;
    final product = _db.row('products', productId);
    if (product == null) {
      throw const NotFoundException('المنتج مش موجود.');
    }
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final label = title.isNotEmpty ? title : '${product['title'] ?? 'المنتج'}';
    if (stock < quantity) {
      throw AppException(
        'الكمية المطلوبة من "$label" مش متاحة. المتاح $stock بس.',
      );
    }
    _db.patch('products', productId, {'stock': stock - quantity});
  }

  @override
  Future<void> incrementStock({
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) return;
    final product = _db.row('products', productId);
    if (product == null) return;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    _db.patch('products', productId, {'stock': stock + quantity});
  }

  @override
  Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> patch) async {
    final existing = _db.row('orders', orderId);
    if (existing == null) throw const NotFoundException('الطلب غير موجود.');
    _db.patch('orders', orderId, {
      ...patch,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return _db.row('orders', orderId)!;
  }

  @override
  Future<void> addEvent(
    String orderId, {
    required String status,
    String note = '',
    String actorName = '',
  }) async {
    _db.addOrderEvent(orderId, status: status, note: note, actorName: actorName);
  }

  @override
  Future<void> rateDelivery({
    required String orderId,
    required String courierId,
    required int rating,
    String comment = '',
    String buyerName = '',
  }) async {
    _db.patch('orders', orderId, {
      'delivery_rating': rating,
      'delivery_review': comment,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final courier = _db.row('profiles', courierId);
    if (courier != null) {
      final count = (courier['ratings_count'] as num?)?.toInt() ?? 0;
      final current = (courier['rating'] as num?)?.toDouble() ?? 0;
      final newCount = count + 1;
      final newRating = ((current * count) + rating) / newCount;
      _db.patch('profiles', courierId, {
        'rating': double.parse(newRating.toStringAsFixed(2)),
        'ratings_count': newCount,
      });
    }
  }

  @override
  Future<void> assignCourier({
    required String orderId,
    required String courierId,
    required bool asOffer,
  }) async {
    _db.patch('orders', orderId, {
      if (asOffer) 'offered_courier_id': courierId,
      if (!asOffer) 'courier_id': courierId,
      if (!asOffer) 'offered_courier_id': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> pushLocation({
    required String courierId,
    required String orderId,
    required double lat,
    required double lng,
  }) async {
    _db.upsert('courier_locations', {
      'courier_id': courierId,
      'lat': lat,
      'lng': lng,
      'order_id': orderId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _db.patch('profiles', courierId, {'lat': lat, 'lng': lng});
  }

  @override
  Future<Map<String, dynamic>?> courierLocation(String courierId) async =>
      _db.row('courier_locations', courierId);

  @override
  Stream<Map<String, dynamic>> watchCourierLocation(String courierId) async* {
    final current = _db.row('courier_locations', courierId);
    if (current != null) yield current;
    await for (final _ in _db.changes) {
      final row = _db.row('courier_locations', courierId);
      if (row != null) yield row;
    }
  }

  @override
  Future<void> setAvailability({
    required String courierId,
    required bool isAvailable,
    required double lat,
    required double lng,
  }) async {
    _db.patch('profiles', courierId, {
      'is_available': isAvailable,
      'lat': lat,
      'lng': lng,
    });
    _db.upsert('courier_locations', {
      'courier_id': courierId,
      'lat': lat,
      'lng': lng,
      'order_id': _db.row('courier_locations', courierId)?['order_id'],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> availableCouriers() async {
    return _db
        .rows('profiles')
        .where((row) => row['role'] == 'courier' && row['is_available'] == true)
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> profile(String userId) async => _db.row('profiles', userId);

  bool _isFinal(String? status) => status == OrderStatus.delivered.name || status == OrderStatus.cancelled.name;

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

  double _distanceFrom(double lat, double lng, Map<String, dynamic> order) {
    final storeLat = (order['store_lat'] as num?)?.toDouble() ?? (order['address_lat'] as num).toDouble();
    final storeLng = (order['store_lng'] as num?)?.toDouble() ?? (order['address_lng'] as num).toDouble();
    return DistanceCalculator.betweenKm(fromLat: lat, fromLng: lng, toLat: storeLat, toLng: storeLng);
  }
}
