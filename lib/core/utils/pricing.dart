import '../config/app_config.dart';

/// حساب مصاريف الدليفاري حسب المسافة بين المتجر وعنوان العميل.
class Pricing {
  const Pricing._();

  static double deliveryFee(double distanceKm) {
    if (distanceKm <= 0) return AppConfig.baseDeliveryFee;
    final fee = AppConfig.baseDeliveryFee + (distanceKm * AppConfig.perKmDeliveryFee);
    return fee > AppConfig.maxDeliveryFee ? AppConfig.maxDeliveryFee : double.parse(fee.toStringAsFixed(2));
  }
}
