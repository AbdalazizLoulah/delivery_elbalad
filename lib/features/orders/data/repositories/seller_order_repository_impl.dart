import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_data_source.dart';
import '../models/order_model.dart';

/// عمليات البائع: الطلبات الواردة ونقلها بين المراحل.
class SellerOrderRepositoryImpl implements SellerOrderRepository {
  SellerOrderRepositoryImpl(this._dataSource);

  final OrderDataSource _dataSource;

  @override
  Future<Result<List<Order>>> sellerOrders(String sellerId) {
    return guard(() async {
      final rows = await _dataSource.sellerOrders(sellerId);
      return rows.map(OrderModel.fromJson).cast<Order>().toList();
    });
  }

  @override
  Stream<Result<Order>> watchOrder(String orderId) async* {
    try {
      await for (final row in _dataSource.watchOrder(orderId)) {
        yield Result<Order>.success(OrderModel.fromJson(row));
      }
    } catch (error, stackTrace) {
      yield Result<Order>.failure(mapError(error, stackTrace));
    }
  }

  @override
  Future<Result<Order>> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String actorName,
    String note = '',
    String? courierId,
    String? courierName,
    String? courierPhone,
    PaymentStatus? paymentStatus,
  }) {
    return guard(() async {
      final current = await _dataSource.order(orderId);
      if (current == null) throw const NotFoundException('الطلب غير موجود.');
      final order = OrderModel.fromJson(current);

      if (order.status == OrderStatus.delivered) {
        throw const AppException('الطلب دا تم تسليمه بالفعل.');
      }
      if (order.status == OrderStatus.cancelled) {
        throw const AppException('الطلب دا ملغي.');
      }

      final now = DateTime.now();
      await _dataSource.updateOrder(orderId, {
        'status': status.name,
        'courier_id': ?courierId,
        'courier_name': ?courierName,
        'courier_phone': ?courierPhone,
        if (paymentStatus != null) 'payment_status': paymentStatus.name,
        if (status == OrderStatus.delivered) 'delivered_at': now.toUtc().toIso8601String(),
        // الطلب بيتم تسليمه => الدفع كاش اتحصل.
        if (status == OrderStatus.delivered) 'payment_status': PaymentStatus.paid.name,
      });

      await _dataSource.addEvent(
        orderId,
        status: status.name,
        note: note.isEmpty ? _defaultNote(status) : note,
        actorName: actorName,
      );

      final updated = await _dataSource.order(orderId);
      return OrderModel.fromJson(updated!);
    });
  }

  String _defaultNote(OrderStatus status) => switch (status) {
        OrderStatus.confirmed => 'المتجر قبل الطلب',
        OrderStatus.preparing => 'جاري تجهيز الطلب',
        OrderStatus.readyForPickup => 'الطلب جاهز للاستلام',
        OrderStatus.pickedUp => 'الطيار استلم الطلب من المتجر',
        OrderStatus.onTheWay => 'الطيار في الطريق إليك',
        OrderStatus.delivered => 'تم تسليم الطلب',
        OrderStatus.cancelled => 'تم إلغاء الطلب',
        OrderStatus.assigned => 'تم تعيين طيار للطلب',
        OrderStatus.pendingSeller => 'تم إنشاء الطلب',
      };
}
