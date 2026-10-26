import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// مسار قيادة كامل بين نقطتين: خط الطريق + المسافة + الزمن المتوقع.
class DrivingRoute {
  const DrivingRoute({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;
}

/// خدمة حساب مسار السواقة الحقيقي على الطرق.
///
/// بتستخدم OSRM (مجاني وبدون مفتاح): بترجع مسافة الطريق الفعلية
/// وزمن الوصول المتوقع وخط الطريق المرسوم على الخريطة.
/// لو الخدمة مش متاحة، التطبيق بيرجع للمسافة المباشرة (Haversine).
class RouteService {
  const RouteService();

  static const String _base = 'https://router.project-osrm.org/route/v1/driving';
  static const String _userAgent =
      'delivery_elbalad/1.0 (com.deliveryelbalad.delivery_elbalad)';

  Future<DrivingRoute?> drivingRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final uri = Uri.parse(
      '$_base/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson&alternatives=false&steps=false',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first;
      if (route is! Map<String, dynamic>) return null;

      final distance = (route['distance'] as num?)?.toDouble();
      final duration = (route['duration'] as num?)?.toDouble();
      final geometry = route['geometry'];
      final coordinates = geometry is Map ? geometry['coordinates'] : null;
      if (distance == null || duration == null || coordinates is! List) {
        return null;
      }

      final points = <LatLng>[];
      for (final raw in coordinates) {
        if (raw is List && raw.length >= 2) {
          final lng = (raw[0] as num).toDouble();
          final lat = (raw[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }
      if (points.isEmpty) return null;

      return DrivingRoute(
        points: points,
        distanceKm: distance / 1000,
        durationMinutes: duration / 60,
      );
    } catch (_) {
      return null;
    }
  }
}
