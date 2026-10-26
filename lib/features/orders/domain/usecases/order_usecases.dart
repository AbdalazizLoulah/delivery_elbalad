import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../cart/domain/entities/cart_line.dart';
import '../../../profile/domain/entities/address.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

/// مهمة واحدة: تحويل السلة لأوردرات (طلب لكل بائع).
class PlaceOrderUseCase implements UseCase<List<Order>, PlaceOrderParams> {
  const PlaceOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(PlaceOrderParams params) => _repository.placeOrders(
        buyer: params.buyer,
        linesBySeller: params.linesBySeller,
        address: params.address,
        paymentMethod: params.paymentMethod,
        deliveryFeePerOrder: params.deliveryFeePerOrder,
        note: params.note,
      );
}

class PlaceOrderParams extends Equatable {
  const PlaceOrderParams({
    required this.buyer,
    required this.linesBySeller,
    required this.address,
    required this.paymentMethod,
    required this.deliveryFeePerOrder,
    this.note = '',
  });

  final AppUser buyer;
  final Map<String, List<CartLine>> linesBySeller;
  final Address address;
  final PaymentMethod paymentMethod;
  final double deliveryFeePerOrder;
  final String note;

  @override
  List<Object?> get props => [buyer, address, paymentMethod, deliveryFeePerOrder, note, linesBySeller.length];
}

class GetBuyerOrdersUseCase implements UseCase<List<Order>, String> {
  const GetBuyerOrdersUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(String buyerId) => _repository.buyerOrders(buyerId);
}

class GetOrderDetailsUseCase implements UseCase<Order, String> {
  const GetOrderDetailsUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String orderId) => _repository.order(orderId);
}

class WatchOrderUseCase implements StreamUseCase<Order, String> {
  const WatchOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Stream<Result<Order>> call(String orderId) => _repository.watchOrder(orderId);
}

class CancelOrderUseCase implements UseCase<Order, CancelOrderParams> {
  const CancelOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(CancelOrderParams params) =>
      _repository.cancelOrder(orderId: params.orderId, actorName: params.actorName);
}

class CancelOrderParams extends Equatable {
  const CancelOrderParams({required this.orderId, required this.actorName});

  final String orderId;
  final String actorName;

  @override
  List<Object?> get props => [orderId, actorName];
}

/// تقييم الدليفاري بعد التسليم (مهمة مستقلة - SRP).
class RateDeliveryUseCase implements UseCase<Order, RateDeliveryParams> {
  const RateDeliveryUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(RateDeliveryParams params) => _repository.rateDelivery(
        orderId: params.orderId,
        courierId: params.courierId,
        rating: params.rating,
        comment: params.comment,
        buyerName: params.buyerName,
      );
}

class RateDeliveryParams extends Equatable {
  const RateDeliveryParams({
    required this.orderId,
    required this.courierId,
    required this.rating,
    this.comment = '',
    this.buyerName = '',
  });

  final String orderId;
  final String courierId;
  final int rating;
  final String comment;
  final String buyerName;

  @override
  List<Object?> get props => [orderId, courierId, rating, comment];
}

class GetSellerOrdersUseCase implements UseCase<List<Order>, String> {
  const GetSellerOrdersUseCase(this._repository);

  final SellerOrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(String sellerId) => _repository.sellerOrders(sellerId);
}

class UpdateOrderStatusUseCase implements UseCase<Order, UpdateOrderStatusParams> {
  const UpdateOrderStatusUseCase(this._repository);

  final SellerOrderRepository _repository;

  @override
  Future<Result<Order>> call(UpdateOrderStatusParams params) => _repository.updateStatus(
        orderId: params.orderId,
        status: params.status,
        actorName: params.actorName,
        note: params.note,
        courierId: params.courierId,
        courierName: params.courierName,
        courierPhone: params.courierPhone,
        paymentStatus: params.paymentStatus,
      );
}

class UpdateOrderStatusParams extends Equatable {
  const UpdateOrderStatusParams({
    required this.orderId,
    required this.status,
    required this.actorName,
    this.note = '',
    this.courierId,
    this.courierName,
    this.courierPhone,
    this.paymentStatus,
  });

  final String orderId;
  final OrderStatus status;
  final String actorName;
  final String note;
  final String? courierId;
  final String? courierName;
  final String? courierPhone;
  final PaymentStatus? paymentStatus;

  @override
  List<Object?> get props => [orderId, status, actorName, note, courierId, paymentStatus];
}

/// مستخدمة في شاشة البائع لتسليم الطلب: تعرض بيانات الطيار المسؤول.
class CourierInfo extends Equatable {
  const CourierInfo({required this.id, required this.name, this.phone = ''});

  final String id;
  final String name;
  final String phone;

  @override
  List<Object?> get props => [id, name, phone];
}

/// بيانات محسوبة للعرض (فاتورة الطلب).
class OrderInvoice extends Equatable {
  const OrderInvoice({
    required this.itemsSubtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  final double itemsSubtotal;
  final double deliveryFee;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  @override
  List<Object?> get props => [itemsSubtotal, deliveryFee, total, paymentMethod, paymentStatus];
}

class BuyerInfo extends Equatable {
  const BuyerInfo({required this.name, required this.phone, required this.address});

  final String name;
  final String phone;
  final String address;

  @override
  List<Object?> get props => [name, phone, address];
}
