import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/order.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.title,
    required super.unitPrice,
    required super.quantity,
    super.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: JsonX.str(json, 'id'),
        productId: JsonX.str(json, 'product_id'),
        title: JsonX.str(json, 'title'),
        unitPrice: JsonX.dbl(json, 'unit_price'),
        quantity: JsonX.integer(json, 'quantity'),
        imageUrl: JsonX.str(json, 'image_url'),
      );

  Map<String, dynamic> toJson(String orderId) => {
        'id': id,
        'order_id': orderId,
        'product_id': productId,
        'title': title,
        'unit_price': unitPrice,
        'quantity': quantity,
        'image_url': imageUrl,
      };
}

class OrderEventModel extends OrderEvent {
  const OrderEventModel({
    required super.status,
    required super.createdAt,
    super.note,
    super.actorName,
  });

  factory OrderEventModel.fromJson(Map<String, dynamic> json) => OrderEventModel(
        status: OrderStatus.fromApi(JsonX.str(json, 'status')),
        createdAt: JsonX.date(json, 'created_at'),
        note: JsonX.str(json, 'note'),
        actorName: JsonX.str(json, 'actor_name'),
      );

  Map<String, dynamic> toJson(String orderId) => {
        'order_id': orderId,
        'status': status.name,
        'note': note,
        'actor_name': actorName,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.buyerId,
    required super.sellerId,
    required super.status,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.itemsSubtotal,
    required super.deliveryFee,
    required super.total,
    required super.addressLabel,
    required super.addressDetails,
    required super.addressLat,
    required super.addressLng,
    required super.createdAt,
    required super.updatedAt,
    super.code,
    super.buyerName,
    super.buyerPhone,
    super.sellerName,
    super.storeName,
    super.storeLat,
    super.storeLng,
    super.courierId,
    super.courierName,
    super.courierPhone,
    super.offeredCourierId,
    super.note,
    super.deliveredAt,
    super.deliveryRating,
    super.deliveryReview,
    super.items,
    super.timeline,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: JsonX.str(json, 'id'),
      code: JsonX.str(json, 'code'),
      buyerId: JsonX.str(json, 'buyer_id'),
      buyerName: JsonX.str(json, 'buyer_name'),
      buyerPhone: JsonX.str(json, 'buyer_phone'),
      sellerId: JsonX.str(json, 'seller_id'),
      sellerName: JsonX.str(json, 'seller_name'),
      storeName: JsonX.str(json, 'store_name'),
      courierId: JsonX.strOrNull(json, 'courier_id'),
      courierName: JsonX.str(json, 'courier_name'),
      courierPhone: JsonX.str(json, 'courier_phone'),
      offeredCourierId: JsonX.strOrNull(json, 'offered_courier_id'),
      status: OrderStatus.fromApi(JsonX.str(json, 'status')),
      paymentMethod: PaymentMethod.fromApi(JsonX.str(json, 'payment_method')),
      paymentStatus: PaymentStatus.fromApi(JsonX.str(json, 'payment_status')),
      itemsSubtotal: JsonX.dbl(json, 'items_subtotal'),
      deliveryFee: JsonX.dbl(json, 'delivery_fee'),
      total: JsonX.dbl(json, 'total'),
      addressLabel: JsonX.str(json, 'address_label'),
      addressDetails: JsonX.str(json, 'address_details'),
      addressLat: JsonX.dbl(json, 'address_lat'),
      addressLng: JsonX.dbl(json, 'address_lng'),
      storeLat: JsonX.dblOrNull(json, 'store_lat'),
      storeLng: JsonX.dblOrNull(json, 'store_lng'),
      note: JsonX.str(json, 'note'),
      createdAt: JsonX.date(json, 'created_at'),
      updatedAt: JsonX.date(json, 'updated_at'),
      deliveredAt: JsonX.dateOrNull(json, 'delivered_at'),
      deliveryRating: JsonX.integerOrNull(json, 'delivery_rating'),
      deliveryReview: JsonX.strOrNull(json, 'delivery_review'),
      items: JsonX.list(json, 'order_items').map(OrderItemModel.fromJson).toList(),
      timeline: JsonX.list(json, 'order_events')
          .map(OrderEventModel.fromJson)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );
  }

  /// بيانات صف الطلب (بدون العناصر والأحداث).
  Map<String, dynamic> toRowJson() => {
        'id': id,
        'code': code,
        'buyer_id': buyerId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'store_name': storeName,
        'courier_id': courierId,
        'courier_name': courierName,
        'courier_phone': courierPhone,
        'offered_courier_id': offeredCourierId,
        'status': status.name,
        'payment_method': paymentMethod.name,
        'payment_status': paymentStatus.name,
        'items_subtotal': itemsSubtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'address_label': addressLabel,
        'address_details': addressDetails,
        'address_lat': addressLat,
        'address_lng': addressLng,
        'store_lat': storeLat,
        'store_lng': storeLng,
        'note': note,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'delivered_at': deliveredAt?.toUtc().toIso8601String(),
        'delivery_rating': deliveryRating,
        'delivery_review': deliveryReview,
      };

  Map<String, dynamic> toJson() => {
        ...toRowJson(),
        'order_items': items.map((item) => item.asModel.toJson(id)).toList(),
        'order_events': timeline.map((event) => event.asModel.toJson(id)).toList(),
      };

  factory OrderModel.fromEntity(Order order) => OrderModel(
        id: order.id,
        code: order.code,
        buyerId: order.buyerId,
        buyerName: order.buyerName,
        buyerPhone: order.buyerPhone,
        sellerId: order.sellerId,
        sellerName: order.sellerName,
        storeName: order.storeName,
        courierId: order.courierId,
        courierName: order.courierName,
        courierPhone: order.courierPhone,
        offeredCourierId: order.offeredCourierId,
        status: order.status,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        itemsSubtotal: order.itemsSubtotal,
        deliveryFee: order.deliveryFee,
        total: order.total,
        addressLabel: order.addressLabel,
        addressDetails: order.addressDetails,
        addressLat: order.addressLat,
        addressLng: order.addressLng,
        storeLat: order.storeLat,
        storeLng: order.storeLng,
        note: order.note,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        deliveredAt: order.deliveredAt,
        deliveryRating: order.deliveryRating,
        deliveryReview: order.deliveryReview,
        items: order.items,
        timeline: order.timeline,
      );
}

extension OrderItemModelX on OrderItem {
  OrderItemModel get asModel => OrderItemModel(
        id: id,
        productId: productId,
        title: title,
        unitPrice: unitPrice,
        quantity: quantity,
        imageUrl: imageUrl,
      );
}

extension OrderEventModelX on OrderEvent {
  OrderEventModel get asModel => OrderEventModel(
        status: status,
        createdAt: createdAt,
        note: note,
        actorName: actorName,
      );
}

class CourierLocationModel extends CourierLocation {
  const CourierLocationModel({
    required super.courierId,
    required super.lat,
    required super.lng,
    required super.updatedAt,
    super.orderId,
  });

  factory CourierLocationModel.fromJson(Map<String, dynamic> json) => CourierLocationModel(
        courierId: JsonX.str(json, 'courier_id'),
        lat: JsonX.dbl(json, 'lat'),
        lng: JsonX.dbl(json, 'lng'),
        updatedAt: JsonX.date(json, 'updated_at'),
        orderId: JsonX.strOrNull(json, 'order_id'),
      );

  Map<String, dynamic> toJson() => {
        'courier_id': courierId,
        'lat': lat,
        'lng': lng,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'order_id': orderId,
      };
}
