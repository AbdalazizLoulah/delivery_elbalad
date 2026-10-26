import 'package:equatable/equatable.dart';

import '../../../../core/utils/distance_calculator.dart';

/// حالة الطلب عبر دورة حياته الكاملة.
enum OrderStatus {
  pendingSeller,
  confirmed,
  preparing,
  readyForPickup,
  assigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled;

  static OrderStatus fromApi(String? value) => OrderStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => OrderStatus.pendingSeller,
      );

  bool get isFinal => this == delivered || this == cancelled;

  bool get isActive => !isFinal;
}

enum PaymentMethod {
  cashOnDelivery,
  visa;

  static PaymentMethod fromApi(String? value) => PaymentMethod.values.firstWhere(
        (method) => method.name == value,
        orElse: () => PaymentMethod.cashOnDelivery,
      );
}

enum PaymentStatus {
  unpaid,
  paid,
  refunded;

  static PaymentStatus fromApi(String? value) => PaymentStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => PaymentStatus.unpaid,
      );
}

/// عنصر داخل الطلب (نسخة ثابتة من المنتج وقت الشراء).
class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl = '',
  });

  final String id;
  final String productId;
  final String title;
  final double unitPrice;
  final int quantity;
  final String imageUrl;

  double get total => unitPrice * quantity;

  @override
  List<Object?> get props => [id, productId, title, unitPrice, quantity];
}

/// حدث في خط زمني الطلب (بيبان للمشتري في صفحة التتبع).
class OrderEvent extends Equatable {
  const OrderEvent({
    required this.status,
    required this.createdAt,
    this.note = '',
    this.actorName = '',
  });

  final OrderStatus status;
  final DateTime createdAt;
  final String note;
  final String actorName;

  @override
  List<Object?> get props => [status, createdAt, note, actorName];
}

/// الطلب: بيجمع بين المشتري والبائع والدليفاري وحالة الدفع والتتبع.
class Order extends Equatable {
  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemsSubtotal,
    required this.deliveryFee,
    required this.total,
    required this.addressLabel,
    required this.addressDetails,
    required this.addressLat,
    required this.addressLng,
    required this.createdAt,
    required this.updatedAt,
    this.code = '',
    this.buyerName = '',
    this.buyerPhone = '',
    this.sellerName = '',
    this.storeName = '',
    this.storeLat,
    this.storeLng,
    this.courierId,
    this.courierName = '',
    this.courierPhone = '',
    this.offeredCourierId,
    this.note = '',
    this.deliveredAt,
    this.deliveryRating,
    this.deliveryReview,
    this.items = const [],
    this.timeline = const [],
  });

  final String id;
  final String code;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String storeName;
  final String? courierId;
  final String courierName;
  final String courierPhone;

  /// الطيار الأقرب اللي الطلب معروض عليه حاليًا.
  final String? offeredCourierId;

  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  final double itemsSubtotal;
  final double deliveryFee;
  final double total;

  final String addressLabel;
  final String addressDetails;
  final double addressLat;
  final double addressLng;
  final double? storeLat;
  final double? storeLng;

  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;

  /// تقييم المشتري للدليفاري.
  final int? deliveryRating;
  final String? deliveryReview;

  final List<OrderItem> items;
  final List<OrderEvent> timeline;

  bool get isPaid => paymentStatus == PaymentStatus.paid;

  bool get isCash => paymentMethod == PaymentMethod.cashOnDelivery;

  bool get hasCourier => (courierId ?? '').isNotEmpty;

  bool get canBeCancelledByBuyer =>
      status == OrderStatus.pendingSeller || status == OrderStatus.confirmed;

  /// الطيار يقدر يلغي الطلب **فقط** لو الدفع عند الاستلام ولسه ما اتحصلش.
  ///
  /// الطلبات المدفوعة أونلاين مش بتتلغى من الطيار (الفلوس اتدفعت بالفعل).
  bool get canCourierCancel => isCash && !isPaid && status.isActive;

  bool get canBeRated => status == OrderStatus.delivered && deliveryRating == null;

  /// الحالة التالية اللي البائع يقدر ينقل الطلب عليها.
  OrderStatus? get nextSellerStatus => switch (status) {
        OrderStatus.pendingSeller => OrderStatus.confirmed,
        OrderStatus.confirmed => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.readyForPickup,
        _ => null,
      };

  /// الحالة التالية اللي الطيار يقدر ينقل الطلب عليها.
  OrderStatus? get nextCourierStatus => switch (status) {
        OrderStatus.assigned => OrderStatus.pickedUp,
        OrderStatus.pickedUp => OrderStatus.onTheWay,
        OrderStatus.onTheWay => OrderStatus.delivered,
        _ => null,
      };

  double get distanceKm {
    final lat = storeLat;
    final lng = storeLng;
    if (lat == null || lng == null) return 0;
    return _distance(lat, lng, addressLat, addressLng);
  }

  Order copyWith({
    String? code,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? courierId,
    String? courierName,
    String? courierPhone,
    String? offeredCourierId,
    bool clearOfferedCourier = false,
    double? deliveryFee,
    double? total,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    int? deliveryRating,
    String? deliveryReview,
    List<OrderItem>? items,
    List<OrderEvent>? timeline,
  }) {
    return Order(
      id: id,
      code: code ?? this.code,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      sellerId: sellerId,
      sellerName: sellerName,
      storeName: storeName,
      courierId: courierId ?? this.courierId,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      offeredCourierId: clearOfferedCourier ? null : (offeredCourierId ?? this.offeredCourierId),
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      itemsSubtotal: itemsSubtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      addressLabel: addressLabel,
      addressDetails: addressDetails,
      addressLat: addressLat,
      addressLng: addressLng,
      storeLat: storeLat,
      storeLng: storeLng,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      deliveryReview: deliveryReview ?? this.deliveryReview,
      items: items ?? this.items,
      timeline: timeline ?? this.timeline,
    );
  }

  static double _distance(double fromLat, double fromLng, double toLat, double toLng) {
    return DistanceCalculator.betweenKm(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        paymentStatus,
        courierId,
        offeredCourierId,
        total,
        updatedAt,
        deliveryRating,
        items.length,
        timeline.length,
      ];
}

/// موقع الطيار اللحظي (بيقرأه المشتري في خريطة التتبع بشكل Realtime).
class CourierLocation extends Equatable {
  const CourierLocation({
    required this.courierId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
    this.orderId,
  });

  final String courierId;
  final double lat;
  final double lng;
  final DateTime updatedAt;
  final String? orderId;

  @override
  List<Object?> get props => [courierId, lat, lng, updatedAt, orderId];
}
