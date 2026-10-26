import 'dart:async';
import 'dart:convert';

import '../utils/distance_calculator.dart';

/// قاعدة بيانات تجريبية في الذاكرة بتشتغل بنفس شكل صفوف Supabase
/// (نفس أسماء الأعمدة) علشان الكود يكون واحد في الوضعين.
///
/// كل التعديلات بتطلع على `changes` فتقدر طبقة البيانات تبني عليها Streams
/// تحاكي الـ Realtime.
class DemoDatabase {
  DemoDatabase._();

  static final DemoDatabase instance = DemoDatabase._();

  static const String demoPassword = '123456';

  final Map<String, Map<String, Map<String, dynamic>>> _tables = {
    'profiles': {},
    'passwords': {},
    'categories': {},
    'products': {},
    'addresses': {},
    'orders': {},
    'courier_locations': {},
  };

  final StreamController<void> _changes = StreamController<void>.broadcast();
  Timer? _rideTimer;
  String? currentUserId;

  Stream<void> get changes => _changes.stream;

  bool get isSeeded => _tables['profiles']!.isNotEmpty;

  // ------------------------- API عام يشبه الجداول -------------------------

  List<Map<String, dynamic>> rows(String table) =>
      _tables[table]!.values.map(_copy).toList(growable: false);

  Map<String, dynamic>? row(String table, String id) {
    final value = _tables[table]![id];
    return value == null ? null : _copy(value);
  }

  Map<String, dynamic>? firstWhere(String table, bool Function(Map<String, dynamic>) test) {
    for (final row in _tables[table]!.values) {
      if (test(row)) return _copy(row);
    }
    return null;
  }

  void upsert(String table, Map<String, dynamic> row) {
    _tables[table]![row['id'].toString()] = _copy(row);
    _emit();
  }

  void patch(String table, String id, Map<String, dynamic> changes) {
    final existing = _tables[table]![id];
    if (existing == null) return;
    existing.addAll(changes);
    _emit();
  }

  void remove(String table, String id) {
    _tables[table]!.remove(id);
    _emit();
  }

  void addOrderEvent(
    String orderId, {
    required String status,
    String note = '',
    String actorName = '',
  }) {
    final order = _tables['orders']![orderId];
    if (order == null) return;
    final events = List<Map<String, dynamic>>.from(
      (order['order_events'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    events.add({
      'id': 'ev-${DateTime.now().microsecondsSinceEpoch}',
      'order_id': orderId,
      'status': status,
      'note': note,
      'actor_name': actorName,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    order['order_events'] = events;
    order['updated_at'] = DateTime.now().toUtc().toIso8601String();
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

  // ------------------------- المحاكاة -------------------------

  /// محاكاة حركة الطيار أثناء التوصيل (تتبع مباشر في الوضع التجريبي).
  void startDemoRide() {
    if (_rideTimer != null) return;
    _rideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final location = _tables['courier_locations']!['u-courier-1'];
      if (location == null) return;
      final orderId = location['order_id'] as String?;
      if (orderId == null) return;
      final order = _tables['orders']![orderId];
      if (order == null) return;

      final status = order['status'] as String?;
      if (status != 'onTheWay' && status != 'pickedUp' && status != 'assigned') return;

      final targetLat = (order['address_lat'] as num).toDouble();
      final targetLng = (order['address_lng'] as num).toDouble();
      final currentLat = (location['lat'] as num).toDouble();
      final currentLng = (location['lng'] as num).toDouble();

      final next = DistanceCalculator.interpolate(
        fromLat: currentLat,
        fromLng: currentLng,
        toLat: targetLat,
        toLng: targetLng,
        fraction: 0.14,
      );

      location['lat'] = next.lat;
      location['lng'] = next.lng;
      location['updated_at'] = DateTime.now().toUtc().toIso8601String();
      _emit();
    });
  }

  void dispose() => _rideTimer?.cancel();

  // ------------------------- البيانات التجريبية -------------------------

  void seed() {
    if (isSeeded) return;
    _seedProfiles();
    _seedCatalog();
    _seedAddresses();
    _seedOrders();
    _seedCourierLocations();
    _emit();
  }

  void _seedProfiles() {
    final now = DateTime.now().toUtc().toIso8601String();
    final profiles = [
      {
        'id': 'u-buyer-1',
        'full_name': 'أحمد محمود',
        'email': 'buyer@elbalad.app',
        'role': 'buyer',
        'phone': '01012345678',
        'avatar_url': null,
        'rating': 4.9,
        'ratings_count': 12,
        'lat': 30.5566,
        'lng': 31.0106,
        'address_text': 'شبين الكوم - شارع الجيش - عمارة 12',
        'is_available': false,
        'created_at': now,
      },
      {
        'id': 'u-seller-1',
        'full_name': 'سوبر ماركت البلد',
        'email': 'seller@elbalad.app',
        'role': 'seller',
        'phone': '01112345678',
        'avatar_url': null,
        'rating': 4.6,
        'ratings_count': 84,
        'lat': 30.5528,
        'lng': 31.0058,
        'address_text': 'شبين الكوم - ميدان الساعة',
        'is_available': true,
        'created_at': now,
      },
      {
        'id': 'u-seller-2',
        'full_name': 'خضار وفاكهة العمدة',
        'email': 'seller2@elbalad.app',
        'role': 'seller',
        'phone': '01223456789',
        'avatar_url': null,
        'rating': 4.8,
        'ratings_count': 57,
        'lat': 30.5610,
        'lng': 31.0180,
        'address_text': 'شبين الكوم - سوق الخضار',
        'is_available': true,
        'created_at': now,
      },
      {
        'id': 'u-courier-1',
        'full_name': 'محمود الدليفاري',
        'email': 'courier@elbalad.app',
        'role': 'courier',
        'phone': '01098765432',
        'avatar_url': null,
        'rating': 4.7,
        'ratings_count': 132,
        'lat': 30.5500,
        'lng': 31.0090,
        'address_text': 'شبين الكوم',
        'is_available': true,
        'created_at': now,
      },
      {
        'id': 'u-courier-2',
        'full_name': 'كريم سريع',
        'email': 'courier2@elbalad.app',
        'role': 'courier',
        'phone': '01555667788',
        'avatar_url': null,
        'rating': 4.4,
        'ratings_count': 41,
        'lat': 30.5680,
        'lng': 31.0260,
        'address_text': 'شبين الكوم',
        'is_available': true,
        'created_at': now,
      },
    ];

    for (final profile in profiles) {
      _tables['profiles']![profile['id'] as String] = profile;
      _tables['passwords']![profile['id'] as String] = {'id': profile['id'], 'password': demoPassword};
    }
  }

  void _seedCatalog() {
    final categories = [
      {'id': 'grocery', 'name_ar': 'بقالة', 'icon': '🥫', 'sort_order': 1},
      {'id': 'fruits', 'name_ar': 'فاكهة وخضار', 'icon': '🍅', 'sort_order': 2},
      {'id': 'bakery', 'name_ar': 'مخبوزات', 'icon': '🥖', 'sort_order': 3},
      {'id': 'drinks', 'name_ar': 'مشروبات', 'icon': '🥤', 'sort_order': 4},
      {'id': 'cleaning', 'name_ar': 'منظفات', 'icon': '🧼', 'sort_order': 5},
      {'id': 'other', 'name_ar': 'منتجات أخرى', 'icon': '🛍️', 'sort_order': 6},
    ];
    for (final category in categories) {
      _tables['categories']![category['id'] as String] = category;
    }

    final products = [
      ('p-1', 'u-seller-1', 'أرز مصري فاخر 1 كجم', 34.0, 'grocery', 40, 'rice'),
      ('p-2', 'u-seller-1', 'زيت ذرة 1 لتر', 78.0, 'grocery', 25, 'oil'),
      ('p-3', 'u-seller-1', 'سكر ناعم 1 كجم', 32.5, 'grocery', 60, 'sugar'),
      ('p-4', 'u-seller-1', 'شاي العروسة 250 جم', 56.0, 'drinks', 30, 'tea'),
      ('p-5', 'u-seller-1', 'لبن جهينة 1 لتر', 42.0, 'drinks', 20, 'milk'),
      ('p-6', 'u-seller-1', 'عيش بلدي 10 أرغفة', 15.0, 'bakery', 15, 'bread'),
      ('p-7', 'u-seller-1', 'مسحوق غسيل 3 كجم', 120.0, 'cleaning', 12, 'detergent'),
      ('p-8', 'u-seller-1', 'صابون أطباق 1 لتر', 38.0, 'cleaning', 18, 'dishsoap'),
      ('p-9', 'u-seller-2', 'طماطم بلدي 1 كجم', 14.0, 'fruits', 35, 'tomato'),
      ('p-10', 'u-seller-2', 'بطاطس 1 كجم', 12.0, 'fruits', 40, 'potato'),
      ('p-11', 'u-seller-2', 'برتقال عصير 1 كجم', 18.0, 'fruits', 30, 'orange'),
      ('p-12', 'u-seller-2', 'موز 1 كجم', 22.0, 'fruits', 25, 'banana'),
      ('p-13', 'u-seller-2', 'خيار 1 كجم', 13.0, 'fruits', 28, 'cucumber'),
      ('p-14', 'u-seller-2', 'فراولة 500 جم', 45.0, 'fruits', 10, 'strawberry'),
      ('p-15', 'u-seller-2', 'ليمون 1 كجم', 20.0, 'fruits', 22, 'lemon'),
      ('p-16', 'u-seller-2', 'جزر 1 كجم', 11.0, 'fruits', 26, 'carrot'),
    ];

    for (final (id, sellerId, title, price, categoryId, stock, imageSeed) in products) {
      final seller = _tables['profiles']![sellerId]!;
      _tables['products']![id] = {
        'id': id,
        'seller_id': sellerId,
        'seller_name': seller['full_name'],
        'title': title,
        'description': 'منتج طازج بيتوصل لباب البيت في أسرع وقت.',
        'price': price,
        'image_url': 'https://picsum.photos/seed/$imageSeed/600/400',
        'category_id': categoryId,
        'stock': stock,
        'rating': 4.2 + (id.hashCode % 8) / 10,
        'reviews_count': 5 + (id.hashCode.abs() % 40),
        'is_active': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
    }
  }

  void _seedAddresses() {
    _tables['addresses']!['a-1'] = {
      'id': 'a-1',
      'user_id': 'u-buyer-1',
      'label': 'البيت',
      'details': 'شبين الكوم - شارع الجيش - عمارة 12 - الدور 3',
      'lat': 30.5566,
      'lng': 31.0106,
      'is_default': true,
    };
    _tables['addresses']!['a-2'] = {
      'id': 'a-2',
      'user_id': 'u-buyer-1',
      'label': 'الشغل',
      'details': 'شبين الكوم - جامعة المنوفية - بوابة 2',
      'lat': 30.5420,
      'lng': 31.0170,
      'is_default': false,
    };
  }

  void _seedOrders() {
    final now = DateTime.now();
    String iso(DateTime value) => value.toUtc().toIso8601String();

    Map<String, dynamic> item(String id, String orderId, String productId, String title, double price,
            int quantity, String imageSeed) =>
        {
          'id': id,
          'order_id': orderId,
          'product_id': productId,
          'title': title,
          'unit_price': price,
          'quantity': quantity,
          'image_url': 'https://picsum.photos/seed/$imageSeed/600/400',
        };

    Map<String, dynamic> event(String orderId, String status, DateTime at, String note, [String actor = '']) => {
          'id': 'ev-$orderId-$status',
          'order_id': orderId,
          'status': status,
          'note': note,
          'actor_name': actor,
          'created_at': iso(at),
        };

    _tables['orders']!['o-1001'] = {
      'id': 'o-1001',
      'code': '#240813-1001',
      'buyer_id': 'u-buyer-1',
      'buyer_name': 'أحمد محمود',
      'buyer_phone': '01012345678',
      'seller_id': 'u-seller-1',
      'seller_name': 'سوبر ماركت البلد',
      'store_name': 'سوبر ماركت البلد',
      'courier_id': 'u-courier-1',
      'courier_name': 'محمود الدليفاري',
      'courier_phone': '01098765432',
      'offered_courier_id': null,
      'status': 'delivered',
      'payment_method': 'cashOnDelivery',
      'payment_status': 'paid',
      'items_subtotal': 132.0,
      'delivery_fee': 19.0,
      'total': 151.0,
      'address_label': 'البيت',
      'address_details': 'شبين الكوم - شارع الجيش - عمارة 12 - الدور 3',
      'address_lat': 30.5566,
      'address_lng': 31.0106,
      'store_lat': 30.5528,
      'store_lng': 31.0058,
      'note': '',
      'created_at': iso(now.subtract(const Duration(days: 3))),
      'updated_at': iso(now.subtract(const Duration(days: 3, hours: -1))),
      'delivered_at': iso(now.subtract(const Duration(days: 3, hours: -1))),
      'delivery_rating': 5,
      'delivery_review': 'وصل بسرعة وبأدب، شكرًا.',
      'order_items': [
        item('oi-1', 'o-1001', 'p-1', 'أرز مصري فاخر 1 كجم', 34.0, 2, 'rice'),
        item('oi-2', 'o-1001', 'p-3', 'سكر ناعم 1 كجم', 32.5, 1, 'sugar'),
        item('oi-3', 'o-1001', 'p-6', 'عيش بلدي 10 أرغفة', 15.0, 2, 'bread'),
      ],
      'order_events': [
        event('o-1001', 'pendingSeller', now.subtract(const Duration(days: 3, hours: 2)), 'تم إنشاء الطلب'),
        event('o-1001', 'confirmed', now.subtract(const Duration(days: 3, hours: 2, minutes: -4)), 'قبل المتجر الطلب', 'سوبر ماركت البلد'),
        event('o-1001', 'readyForPickup', now.subtract(const Duration(days: 3, hours: 2, minutes: -12)), 'الطلب جاهز للاستلام'),
        event('o-1001', 'assigned', now.subtract(const Duration(days: 3, hours: 2, minutes: -18)), 'تم تعيين الطيار', 'محمود الدليفاري'),
        event('o-1001', 'onTheWay', now.subtract(const Duration(days: 3, hours: 2, minutes: -25)), 'الطيار في الطريق إليك', 'محمود الدليفاري'),
        event('o-1001', 'delivered', now.subtract(const Duration(days: 3, hours: 1)), 'تم تسليم الطلب', 'محمود الدليفاري'),
      ],
    };

    _tables['orders']!['o-1002'] = {
      'id': 'o-1002',
      'code': '#240813-1002',
      'buyer_id': 'u-buyer-1',
      'buyer_name': 'أحمد محمود',
      'buyer_phone': '01012345678',
      'seller_id': 'u-seller-2',
      'seller_name': 'خضار وفاكهة العمدة',
      'store_name': 'خضار وفاكهة العمدة',
      'courier_id': 'u-courier-1',
      'courier_name': 'محمود الدليفاري',
      'courier_phone': '01098765432',
      'offered_courier_id': null,
      'status': 'onTheWay',
      'payment_method': 'visa',
      'payment_status': 'paid',
      'items_subtotal': 77.0,
      'delivery_fee': 22.0,
      'total': 99.0,
      'address_label': 'البيت',
      'address_details': 'شبين الكوم - شارع الجيش - عمارة 12 - الدور 3',
      'address_lat': 30.5566,
      'address_lng': 31.0106,
      'store_lat': 30.5610,
      'store_lng': 31.0180,
      'note': 'كلمني قبل ما توصل',
      'created_at': iso(now.subtract(const Duration(minutes: 40))),
      'updated_at': iso(now.subtract(const Duration(minutes: 6))),
      'delivered_at': null,
      'delivery_rating': null,
      'delivery_review': null,
      'order_items': [
        item('oi-4', 'o-1002', 'p-9', 'طماطم بلدي 1 كجم', 14.0, 2, 'tomato'),
        item('oi-5', 'o-1002', 'p-11', 'برتقال عصير 1 كجم', 18.0, 1, 'orange'),
        item('oi-6', 'o-1002', 'p-14', 'فراولة 500 جم', 45.0, 1, 'strawberry'),
      ],
      'order_events': [
        event('o-1002', 'pendingSeller', now.subtract(const Duration(minutes: 40)), 'تم إنشاء الطلب ودفع أونلاين'),
        event('o-1002', 'confirmed', now.subtract(const Duration(minutes: 37)), 'قبل المتجر الطلب', 'خضار وفاكهة العمدة'),
        event('o-1002', 'preparing', now.subtract(const Duration(minutes: 33)), 'جاري تجهيز الطلب'),
        event('o-1002', 'readyForPickup', now.subtract(const Duration(minutes: 28)), 'الطلب جاهز للاستلام'),
        event('o-1002', 'assigned', now.subtract(const Duration(minutes: 24)), 'تم تعيين الطيار', 'محمود الدليفاري'),
        event('o-1002', 'pickedUp', now.subtract(const Duration(minutes: 18)), 'تم استلام الطلب من المتجر', 'محمود الدليفاري'),
        event('o-1002', 'onTheWay', now.subtract(const Duration(minutes: 6)), 'الطيار في الطريق إليك', 'محمود الدليفاري'),
      ],
    };

    _tables['orders']!['o-1003'] = {
      'id': 'o-1003',
      'code': '#240813-1003',
      'buyer_id': 'u-buyer-1',
      'buyer_name': 'أحمد محمود',
      'buyer_phone': '01012345678',
      'seller_id': 'u-seller-2',
      'seller_name': 'خضار وفاكهة العمدة',
      'store_name': 'خضار وفاكهة العمدة',
      'courier_id': null,
      'courier_name': '',
      'courier_phone': '',
      'offered_courier_id': 'u-courier-1',
      'status': 'readyForPickup',
      'payment_method': 'cashOnDelivery',
      'payment_status': 'unpaid',
      'items_subtotal': 55.0,
      'delivery_fee': 18.0,
      'total': 73.0,
      'address_label': 'الشغل',
      'address_details': 'شبين الكوم - جامعة المنوفية - بوابة 2',
      'address_lat': 30.5420,
      'address_lng': 31.0170,
      'store_lat': 30.5610,
      'store_lng': 31.0180,
      'note': '',
      'created_at': iso(now.subtract(const Duration(minutes: 12))),
      'updated_at': iso(now.subtract(const Duration(minutes: 5))),
      'delivered_at': null,
      'delivery_rating': null,
      'delivery_review': null,
      'order_items': [
        item('oi-7', 'o-1003', 'p-12', 'موز 1 كجم', 22.0, 1, 'banana'),
        item('oi-8', 'o-1003', 'p-13', 'خيار 1 كجم', 13.0, 1, 'cucumber'),
        item('oi-9', 'o-1003', 'p-15', 'ليمون 1 كجم', 20.0, 1, 'lemon'),
      ],
      'order_events': [
        event('o-1003', 'pendingSeller', now.subtract(const Duration(minutes: 12)), 'تم إنشاء الطلب'),
        event('o-1003', 'confirmed', now.subtract(const Duration(minutes: 10)), 'قبل المتجر الطلب', 'خضار وفاكهة العمدة'),
        event('o-1003', 'readyForPickup', now.subtract(const Duration(minutes: 5)), 'الطلب جاهز للاستلام'),
      ],
    };

    _tables['orders']!['o-1004'] = {
      'id': 'o-1004',
      'code': '#240813-1004',
      'buyer_id': 'u-buyer-1',
      'buyer_name': 'أحمد محمود',
      'buyer_phone': '01012345678',
      'seller_id': 'u-seller-1',
      'seller_name': 'سوبر ماركت البلد',
      'store_name': 'سوبر ماركت البلد',
      'courier_id': null,
      'courier_name': '',
      'courier_phone': '',
      'offered_courier_id': null,
      'status': 'pendingSeller',
      'payment_method': 'cashOnDelivery',
      'payment_status': 'unpaid',
      'items_subtotal': 120.0,
      'delivery_fee': 17.0,
      'total': 137.0,
      'address_label': 'البيت',
      'address_details': 'شبين الكوم - شارع الجيش - عمارة 12 - الدور 3',
      'address_lat': 30.5566,
      'address_lng': 31.0106,
      'store_lat': 30.5528,
      'store_lng': 31.0058,
      'note': '',
      'created_at': iso(now.subtract(const Duration(minutes: 3))),
      'updated_at': iso(now.subtract(const Duration(minutes: 3))),
      'delivered_at': null,
      'delivery_rating': null,
      'delivery_review': null,
      'order_items': [
        item('oi-10', 'o-1004', 'p-7', 'مسحوق غسيل 3 كجم', 120.0, 1, 'detergent'),
      ],
      'order_events': [
        event('o-1004', 'pendingSeller', now.subtract(const Duration(minutes: 3)), 'تم إنشاء الطلب'),
      ],
    };
  }

  void _seedCourierLocations() {
    _tables['courier_locations']!['u-courier-1'] = {
      'courier_id': 'u-courier-1',
      'lat': 30.5580,
      'lng': 31.0140,
      'order_id': 'o-1002',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    _tables['courier_locations']!['u-courier-2'] = {
      'courier_id': 'u-courier-2',
      'lat': 30.5680,
      'lng': 31.0260,
      'order_id': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
