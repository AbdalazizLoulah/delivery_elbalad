import '../../../core/config/app_config.dart';
import '../../../core/utils/countries.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../auth/domain/entities/app_user.dart';
import '../../orders/domain/entities/order.dart';

/// قواعد ظهور الطلب للطيار:
/// - الطيار لازم يكون "متاح" (مش موقف استلام).
/// - الطيار لازم يكون قريب من المتجر في نطاق البحث.
/// - المتجر والعميل والطيار لازم يكونوا في نفس البلد (لما نقدر نحدده).
///
/// لو أي شرط مش متحقق الطلب ميتعرضش للطيار خالص، ولا بيتبعتله إشعار بيه.
class CourierEligibility {
  const CourierEligibility._();

  static bool canServe({
    required AppUser courier,
    required Order order,
    bool? available,
    double? lat,
    double? lng,
    double radiusKm = AppConfig.courierSearchRadiusKm,
  }) {
    if (!(available ?? courier.isAvailable)) return false;

    final courierLat = lat ?? courier.lat;
    final courierLng = lng ?? courier.lng;

    if (!Countries.isValidPoint(courierLat, courierLng)) return false;
    if (!Countries.isValidPoint(order.storeLat, order.storeLng)) return false;
    if (!Countries.isValidPoint(order.addressLat, order.addressLng)) return false;

    final distanceToStore = DistanceCalculator.betweenKm(
      fromLat: courierLat!,
      fromLng: courierLng!,
      toLat: order.storeLat!,
      toLng: order.storeLng!,
    );
    if (distanceToStore > radiusKm) return false;

    final storeCountry = Countries.byCoordinates(order.storeLat, order.storeLng);
    final buyerCountry = Countries.byCoordinates(order.addressLat, order.addressLng);

    // طلب مسافته من المتجر للعميل دولتين مختلفتين = طلب غير صالح.
    if (storeCountry != null &&
        buyerCountry != null &&
        storeCountry.code != buyerCountry.code) {
      return false;
    }

    final orderCountry = buyerCountry ??
        storeCountry ??
        Countries.fromPhone(order.buyerPhone, fallback: Countries.egypt);
    final courierCountry = Countries.byCoordinates(courierLat, courierLng) ??
        Countries.fromPhone(courier.phone, fallback: Countries.egypt);

    if (orderCountry != null &&
        courierCountry != null &&
        orderCountry.code != courierCountry.code) {
      return false;
    }

    return true;
  }
}
