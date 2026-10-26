import 'dart:math' as math;

/// حسابات المسافات (Haversine) - مستخدمة في ترتيب الطلبات لأقرب طيار دليفاري.
class DistanceCalculator {
  const DistanceCalculator._();

  static const double earthRadiusKm = 6371;

  static double betweenKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final dLat = _toRadians(toLat - fromLat);
    final dLng = _toRadians(toLng - fromLng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(fromLat)) *
            math.cos(_toRadians(toLat)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  /// نقطة على المسافة بين نقطتين (بنستخدمها في محاكاة تحرك الطيار في الوضع التجريبي).
  static ({double lat, double lng}) interpolate({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required double fraction,
  }) {
    final f = fraction.clamp(0.0, 1.0);
    return (
      lat: fromLat + (toLat - fromLat) * f,
      lng: fromLng + (toLng - fromLng) * f,
    );
  }
}
