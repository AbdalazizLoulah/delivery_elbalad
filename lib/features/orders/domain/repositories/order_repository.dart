import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../cart/domain/entities/cart_line.dart';
import '../../../profile/domain/entities/address.dart';
import '../entities/order.dart';

/// العمليات المشتركة لتحديث حالة الطلب (البائع والطيار بيستخدموها).
abstract interface class OrderStatusRepository {
  Future<Result<Order>> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String actorName,
    String note,
    String? courierId,
    String? courierName,
    String? courierPhone,
    PaymentStatus? paymentStatus,
  });
}

/// عمليات المشتري على الطلبات.
abstract interface class OrderRepository {
  Future<Result<List<Order>>> placeOrders({
    required AppUser buyer,
    required Map<String, List<CartLine>> linesBySeller,
    required Address address,
    required PaymentMethod paymentMethod,
    required double deliveryFeePerOrder,
    String note = '',
  });

  Future<Result<List<Order>>> buyerOrders(String buyerId);

  Future<Result<Order>> order(String orderId);

  Stream<Result<Order>> watchOrder(String orderId);

  Future<Result<Order>> cancelOrder({required String orderId, required String actorName});

  Future<Result<Order>> rateDelivery({
    required String orderId,
    required String courierId,
    required int rating,
    String comment = '',
    String buyerName = '',
  });
}

/// عمليات البائع على الطلبات.
abstract interface class SellerOrderRepository implements OrderStatusRepository {
  Future<Result<List<Order>>> sellerOrders(String sellerId);

  /// متابعة طلب واحد لحظيًا (Realtime) عشان الإشعارات.
  Stream<Result<Order>> watchOrder(String orderId);
}

/// عمليات طيار الدليفاري.
abstract interface class CourierOrderRepository implements OrderStatusRepository {
  /// الطلبات الجاهزة للاستلام مرتبة بالأقرب لموقع الطيار.
  Future<Result<List<Order>>> availableOrders({
    required double lat,
    required double lng,
    required double radiusKm,
  });

  /// الطلبات اللي معروضة على طيار معين (أقرب طيار للطلب).
  Future<Result<List<Order>>> offeredOrders(String courierId);

  Future<Result<List<Order>>> courierOrders(String courierId, {bool onlyActive = false});

  /// متابعة طلب واحد لحظيًا (Realtime) عشان الإشعارات.
  Stream<Result<Order>> watchOrder(String orderId);

  Future<Result<Order>> acceptOrder({
    required String orderId,
    required AppUser courier,
    required double deliveryFee,
    double? lat,
    double? lng,
  });

  /// إلغاء الطلب من الطيار — مسموح **فقط** لو الدفع عند الاستلام.
  Future<Result<Order>> cancelOrder({
    required String orderId,
    required String actorName,
    String note = '',
  });

  /// تعيين طيار للطلب - كعرض (asOffer) أو تعيين مباشر بعد القبول.
  Future<Result<void>> assignCourier({
    required String orderId,
    required String courierId,
    required bool asOffer,
  });

  Future<Result<void>> pushLocation({
    required String courierId,
    required String orderId,
    required double lat,
    required double lng,
  });

  Stream<Result<CourierLocation>> watchCourierLocation(String courierId);

  Future<Result<CourierLocation?>> courierLocation(String courierId);

  Future<Result<void>> setAvailability({
    required String courierId,
    required bool isAvailable,
    required double lat,
    required double lng,
  });

  Future<Result<List<AppUser>>> availableCouriers();
}
