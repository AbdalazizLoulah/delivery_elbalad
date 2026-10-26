/// عقد مصدر بيانات الطلبات (كل العمليات على الأوردر + التتبع + مواقع الطيارين).
///
/// الريبو هيفصل بين العمليات دي على 3 عقود مستقلة للمشتري والبائع والطيار
/// (Interface Segregation) بينما مصدر البيانات واحد بيمنع التكرار.
abstract interface class OrderDataSource {
  Future<List<Map<String, dynamic>>> buyerOrders(String buyerId);

  Future<List<Map<String, dynamic>>> sellerOrders(String sellerId);

  Future<List<Map<String, dynamic>>> courierOrders(String courierId, {required bool onlyActive});

  Future<List<Map<String, dynamic>>> offeredOrders(String courierId);

  /// الطلبات الجاهزة للاستلام وجاهزة ياخدها أي طيار في النطاق.
  Future<List<Map<String, dynamic>>> availableOrders({
    required double lat,
    required double lng,
    required double radiusKm,
  });

  Future<Map<String, dynamic>?> order(String orderId);

  Stream<Map<String, dynamic>> watchOrder(String orderId);

  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderRow,
    List<Map<String, dynamic>> itemRows,
  );

  /// بتنقص كمية من مخزون منتج بشكل آمن (بترفض لو المخزون مش كفاية).
  Future<void> decrementStock({
    required String productId,
    required int quantity,
    String title = '',
  });

  /// بترجّع الكمية للمخزون (لو إنشاء الطلب فشل بعد الحجز).
  Future<void> incrementStock({
    required String productId,
    required int quantity,
  });

  Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> patch);

  Future<void> addEvent(
    String orderId, {
    required String status,
    String note,
    String actorName,
  });

  Future<void> rateDelivery({
    required String orderId,
    required String courierId,
    required int rating,
    String comment,
    String buyerName,
  });

  Future<void> assignCourier({
    required String orderId,
    required String courierId,
    required bool asOffer,
  });

  Future<void> pushLocation({
    required String courierId,
    required String orderId,
    required double lat,
    required double lng,
  });

  Future<Map<String, dynamic>?> courierLocation(String courierId);

  Stream<Map<String, dynamic>> watchCourierLocation(String courierId);

  Future<void> setAvailability({
    required String courierId,
    required bool isAvailable,
    required double lat,
    required double lng,
  });

  Future<List<Map<String, dynamic>>> availableCouriers();

  /// بيانات أي مستخدم (بائع / طيار) - بنحتاجها في تفاصيل الطلب.
  Future<Map<String, dynamic>?> profile(String userId);
}
