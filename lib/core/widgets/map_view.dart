import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

import '../../core/localization/app_text.dart';
/// التجريد الموحد للخريطة في كل الشاشات.
///
/// بيستخدم OpenStreetMap (مجاني — بدون مفتاح API أو بطاقة بنكية)،
/// وبيتابع أي تغيير في `center` وينقل الكاميرا عليه تلقائيًا
/// علشان التتبع اللحظي للطيار يشتغل.
class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.center,
    this.markers = const {},
    this.polylines = const {},
    this.zoom = 14,
    this.onTap,
    this.interactive = true,
  });

  final LatLng center;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final double zoom;
  final ValueChanged<LatLng>? onTap;

  /// لو false بنقفل السحب/التكبير — مفيد لو الخريطة جوه صفحة بتنسحب.
  final bool interactive;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready && (oldWidget.center != widget.center || oldWidget.zoom != widget.zoom)) {
      _controller.move(widget.center, widget.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            onMapReady: () => _ready = true,
            onTap: (_, point) => widget.onTap?.call(point),
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.deliveryelbalad.delivery_elbalad',
              maxZoom: 19,
            ),
            if (widget.polylines.isNotEmpty)
              PolylineLayer(polylines: widget.polylines.toList()),
            if (widget.markers.isNotEmpty)
              MarkerLayer(markers: widget.markers.toList()),
          ],
        ),
        Positioned(
          left: 6,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const AppText(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

/// أدوات مساعدة لبناء العلامات وخطوط المسار.
class MapHelpers {
  const MapHelpers._();

  static Marker marker({
    required String id,
    required double lat,
    required double lng,
    required String title,
    String? snippet,
    Color color = AppColors.primary,
  }) {
    final label = (snippet == null || snippet.isEmpty) ? title : '$title — $snippet';
    return Marker(
      key: ValueKey(id),
      point: LatLng(lat, lng),
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: Tooltip(
        message: label,
        child: Icon(Icons.location_pin, size: 44, color: color),
      ),
    );
  }

  static Polyline route({
    required String id,
    required List<LatLng> points,
    Color color = AppColors.primary,
  }) {
    return Polyline(
      points: points,
      color: color,
      strokeWidth: 5,
      borderColor: Colors.white,
      borderStrokeWidth: 1.5,
      hitValue: id,
    );
  }
}
