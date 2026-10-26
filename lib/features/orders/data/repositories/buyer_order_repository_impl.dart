import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/pricing.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../cart/domain/entities/cart_line.dart';
import '../../../profile/domain/entities/address.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_data_source.dart';
import '../models/order_model.dart';

/// عمليات المشتري: إنشاء الطلب، متابعته، إلغاءه، وتقييم الدليفاري.
class BuyerOrderRepositoryImpl implements OrderRepository {
  BuyerOrderRepositoryImpl(this._dataSource);

  final OrderDataSource _dataSource;

  @override
  Future<Result<List<Order>>> placeOrders({
    required AppUser buyer,
    required Map<String, List<CartLine>> linesBySeller,
    required Address address,
    required PaymentMethod paymentMethod,
    required double deliveryFeePerOrder,
    String note = '',
  }) {
    return guard(() async {
      if (linesBySeller.isEmpty) {
        throw const AppException('السلة فاضية، ضيف منتجات الأول.');
      }

      final created = <Order>[];
      for (final entry in linesBySeller.entries) {
        final sellerId = entry.key;
        final lines = entry.value;
        if (lines.isEmpty) continue;

        final sellerRow = await _dataSource.profile(sellerId);
        final sellerName = (sellerRow?['full_name'] as String?) ?? 'متجر';
        final storeLat = (sellerRow?['lat'] as num?)?.toDouble();
        final storeLng = (sellerRow?['lng'] as num?)?.toDouble();

        final subtotal = lines.fold<double>(0, (sum, line) => sum + line.total);
        final distanceKm = (storeLat == null || storeLng == null)
            ? 0.0
            : DistanceCalculator.betweenKm(
                fromLat: storeLat,
                fromLng: storeLng,
                toLat: address.lat,
                toLng: address.lng,
              );
        final deliveryFee = distanceKm == 0 ? deliveryFeePerOrder : Pricing.deliveryFee(distanceKm);

        final id = _newId();
        final now = DateTime.now();
        final order = OrderModel(
          id: id,
          code: Formatters.orderCode(now, id),
          buyerId: buyer.id,
          buyerName: buyer.fullName,
          buyerPhone: buyer.phone,
          sellerId: sellerId,
          sellerName: sellerName,
          storeName: sellerName,
          status: OrderStatus.pendingSeller,
          paymentMethod: paymentMethod,
          paymentStatus:
              paymentMethod == PaymentMethod.visa ? PaymentStatus.paid : PaymentStatus.unpaid,
          itemsSubtotal: double.parse(subtotal.toStringAsFixed(2)),
          deliveryFee: deliveryFee,
          total: double.parse((subtotal + deliveryFee).toStringAsFixed(2)),
          addressLabel: address.label,
          addressDetails: address.details,
          addressLat: address.lat,
          addressLng: address.lng,
          storeLat: storeLat,
          storeLng: storeLng,
          note: note,
          createdAt: now,
          updatedAt: now,
          items: [
            for (final line in lines)
              OrderItemModel(
                id: _newId(),
                productId: line.product.id,
                title: line.product.title,
                unitPrice: line.product.price,
                quantity: line.quantity,
                imageUrl: line.product.imageUrl,
              ),
          ],
        );

        final itemRows = order.items
            .map((item) => item.asModel.toJson(order.id))
            .toList();

        // بنحجز الكميات من المخزون الأول. لو إنشاء الطلب فشل بنرجّعها تاني،
        // ولو المخزون مش كفاية العملية كلها بتفشل قبل ما يتعمل أي طلب.
        final reserved = <CartLine>[];
        try {
          for (final line in lines) {
            await _dataSource.decrementStock(
              productId: line.product.id,
              quantity: line.quantity,
              title: line.product.title,
            );
            reserved.add(line);
          }
          final row = await _dataSource.createOrder(order.toJson(), itemRows);
          created.add(OrderModel.fromJson(row));
        } catch (error) {
          for (final line in reserved) {
            try {
              await _dataSource.incrementStock(
                productId: line.product.id,
                quantity: line.quantity,
              );
            } catch (_) {
              // الربجوع للمخزون أفضل جهد؛ منمنعوش الخطأ الأصلي.
            }
          }
          rethrow;
        }
      }

      if (created.isEmpty) {
        throw const AppException('مش قادرين ننشئ الطلب، حاول تاني.');
      }
      return created;
    });
  }

  @override
  Future<Result<List<Order>>> buyerOrders(String buyerId) {
    return guard(() async {
      final rows = await _dataSource.buyerOrders(buyerId);
      return rows.map(OrderModel.fromJson).cast<Order>().toList();
    });
  }

  @override
  Future<Result<Order>> order(String orderId) {
    return guard(() async {
      final row = await _dataSource.order(orderId);
      if (row == null) throw const NotFoundException('الطلب غير موجود.');
      return OrderModel.fromJson(row);
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
  Future<Result<Order>> cancelOrder({required String orderId, required String actorName}) {
    return guard(() async {
      final current = await _dataSource.order(orderId);
      if (current == null) throw const NotFoundException('الطلب غير موجود.');
      final order = OrderModel.fromJson(current);
      if (!order.canBeCancelledByBuyer) {
        throw const AppException('الطلب بدأ التجهيز، مش ممكن يتلغي دلوقتي.');
      }

      await _dataSource.updateOrder(orderId, {
        'status': OrderStatus.cancelled.name,
        'payment_status': order.isPaid ? PaymentStatus.refunded.name : order.paymentStatus.name,
      });
      await _dataSource.addEvent(
        orderId,
        status: OrderStatus.cancelled.name,
        note: 'تم إلغاء الطلب',
        actorName: actorName,
      );

      final updated = await _dataSource.order(orderId);
      return OrderModel.fromJson(updated!);
    });
  }

  @override
  Future<Result<Order>> rateDelivery({
    required String orderId,
    required String courierId,
    required int rating,
    String comment = '',
    String buyerName = '',
  }) {
    return guard(() async {
      if (rating < 1 || rating > 5) {
        throw const AppException('التقييم من 1 لـ 5 نجوم.');
      }
      await _dataSource.rateDelivery(
        orderId: orderId,
        courierId: courierId,
        rating: rating,
        comment: comment,
        buyerName: buyerName,
      );
      final updated = await _dataSource.order(orderId);
      if (updated == null) throw const NotFoundException('الطلب غير موجود.');
      return OrderModel.fromJson(updated);
    });
  }

  String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.toRadixString(36).padLeft(8, '0');
    return 'o-$random-${now % 100000}';
  }
}
