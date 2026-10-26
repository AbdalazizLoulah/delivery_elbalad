import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/exceptions.dart';

/// عقد خدمة تحديد الموقع (Dependency Inversion): الـ blocs بتتعامل مع التجريد دا.
abstract interface class LocationService {
  Future<GeoPoint> currentPosition({bool allowPermissionRequest = true});

  Future<bool> ensurePermission({bool allowPermissionRequest = true});

  /// آخر موقع معروف اتخزن على الجهاز (بيستخدم كبديل لو GPS اتأخر).
  GeoPoint? lastKnownLocation();

  Stream<GeoPoint> positionStream({int distanceFilterMeters = 15});

  Future<double> distanceBetweenKm(GeoPoint from, GeoPoint to);
}

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

abstract interface class GeocodingService {
  Future<String> addressFromCoordinates(GeoPoint point);

  Future<GeoPoint?> coordinatesFromAddress(String address);
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService(this._preferences);

  final SharedPreferences _preferences;

  /// بنسأل على صلاحية الموقع مرة واحدة بس. بعد كده بنعتمد على الحالة
  /// المحفوظة وعلى إعدادات النظام — من غير ما نزعج المستخدم كل مرة.
  static const String _askedKey = 'location_permission_asked';
  static const String _grantedKey = 'location_permission_granted';

  /// آخر إحداثيات معروفة (عشان الشاشات تفتح فورًا من غير انتظار GPS).
  static const String _latKey = 'location_last_lat';
  static const String _lngKey = 'location_last_lng';
  static const String _atKey = 'location_last_at';

  /// مدة كافية جدًا لاستدعاءات المنصة السريعة (فحص الخدمة/الصلاحية)،
  /// وبتحمي التطبيق من إن القناة تفصل ومايتعلقش التحميل للأبد.
  static const Duration _platformCallTimeout = Duration(seconds: 5);

  /// أقصى مدة لانتظار قراءة GPS حقيقية (مع الدقة العالية ممكن تطول).
  static const Duration _positionTimeout = Duration(seconds: 25);

  @override
  Future<bool> ensurePermission({bool allowPermissionRequest = true}) async {
    final serviceEnabled = await _guard(Geolocator.isLocationServiceEnabled());
    if (!serviceEnabled) {
      throw const AppException('خدمة تحديد الموقع مقفولة، فعّلها من إعدادات الموبايل.');
    }

    var permission = await _guard(Geolocator.checkPermission());
    final alreadyAsked = _preferences.getBool(_askedKey) ?? false;

    if (permission == LocationPermission.denied &&
        allowPermissionRequest &&
        !alreadyAsked) {
      // بنسجل إننا سألنا *قبل* ما نفتح النافذة، عشان لو المستخدم قفل
      // التطبيق أثناء النافذة ما يتسألش تاني في كل فتحة.
      await _preferences.setBool(_askedKey, true);
      // دي بتفتح نافذة صلاحية للمستخدم، فبنسيبها من غير مهلة.
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    await _preferences.setBool(_grantedKey, granted);

    if (!granted) {
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          'صلاحية الموقع متقفلة للحساب دا. افتح إعدادات الموبايل → التطبيقات → ديليفاري البلد وفعّل الموقع.',
        );
      }
      throw const AppException(
        'محتاجين صلاحية الموقع علشان نحدد عنوانك ونتبع الطلب. تقدر تفعّلها من إعدادات الموبايل.',
      );
    }
    return true;
  }

  @override
  Future<GeoPoint> currentPosition({bool allowPermissionRequest = true}) async {
    await ensurePermission(allowPermissionRequest: allowPermissionRequest);
    try {
      final position = await _guard(
        Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ),
        timeout: _positionTimeout,
      );
      await _savePosition(position.latitude, position.longitude);
      return GeoPoint(lat: position.latitude, lng: position.longitude);
    } on AppException {
      // لو GPS اتأخر أو فشل، بنرجع آخر موقع معروف بدل ما نعطّل المستخدم.
      final last = lastKnownLocation();
      if (last != null) return last;
      rethrow;
    }
  }

  @override
  GeoPoint? lastKnownLocation() {
    final lat = _preferences.getDouble(_latKey);
    final lng = _preferences.getDouble(_lngKey);
    if (lat == null || lng == null) return null;
    return GeoPoint(lat: lat, lng: lng);
  }

  Future<void> _savePosition(double lat, double lng) async {
    await _preferences.setDouble(_latKey, lat);
    await _preferences.setDouble(_lngKey, lng);
    await _preferences.setInt(_atKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// بيلف استدعاء المنصة بمهلة، ولو اتأخر أو فشل بيرجّع خطأ مفهوم بالعربي.
  Future<T> _guard<T>(Future<T> call, {Duration timeout = _platformCallTimeout}) async {
    try {
      return await call.timeout(timeout);
    } on TimeoutException {
      throw const AppException('خدمة تحديد الموقع مش بتستجيب، جرب تاني.');
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('تعذر تحديد موقعك، اتأكد إن خدمة الموقع شغالة وجرب تاني.');
    }
  }

  @override
  Stream<GeoPoint> positionStream({int distanceFilterMeters = 15}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((position) {
      unawaited(_savePosition(position.latitude, position.longitude));
      return GeoPoint(lat: position.latitude, lng: position.longitude);
    });
  }

  @override
  Future<double> distanceBetweenKm(GeoPoint from, GeoPoint to) async {
    final meters = Geolocator.distanceBetween(from.lat, from.lng, to.lat, to.lng);
    return meters / 1000;
  }
}

/// تحويل الإحداثيات لعنوان مكتوب باستخدام geocoding (بلا API key).
class PlatformGeocodingService implements GeocodingService {
  const PlatformGeocodingService();

  @override
  Future<String> addressFromCoordinates(GeoPoint point) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(point.lat, point.lng);
      if (placemarks.isEmpty) return _fallback(point);
      final place = placemarks.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty);
      final address = parts.join('، ');
      return address.isEmpty ? _fallback(point) : address;
    } on PlatformException {
      return _fallback(point);
    } catch (_) {
      return _fallback(point);
    }
  }

  @override
  Future<GeoPoint?> coordinatesFromAddress(String address) async {
    try {
      final locations = await Geocoding().locationFromAddress(address);
      if (locations.isEmpty) return null;
      return GeoPoint(lat: locations.first.latitude, lng: locations.first.longitude);
    } catch (_) {
      return null;
    }
  }

  String _fallback(GeoPoint point) =>
      '${point.lat.toStringAsFixed(5)}, ${point.lng.toStringAsFixed(5)}';
}
