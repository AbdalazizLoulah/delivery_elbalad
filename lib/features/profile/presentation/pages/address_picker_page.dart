import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/map_view.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
/// شاشة تحديد العنوان على الخريطة: تحريك العلامة أو استخدام الموقع الحالي.
class AddressPickerPage extends StatefulWidget {
  const AddressPickerPage({super.key, this.initialPoint, this.initialDetails});

  final LatLngLike? initialPoint;
  final String? initialDetails;

  @override
  State<AddressPickerPage> createState() => _AddressPickerPageState();
}

class _AddressPickerPageState extends State<AddressPickerPage> {
  static const LatLng _defaultPoint = LatLng(30.5566, 31.0106); // شبين الكوم - المنوفية

  late LatLng _point = widget.initialPoint == null
      ? _defaultPoint
      : LatLng(widget.initialPoint!.lat, widget.initialPoint!.lng);

  final _detailsController = TextEditingController();
  String _label = 'البيت';
  bool _isLocating = false;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _detailsController.text = widget.initialDetails ?? '';
    if (_detailsController.text.isEmpty) _resolveAddress();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _resolveAddress() async {
    setState(() => _isResolving = true);
    try {
      final text = await di<GeocodingService>().addressFromCoordinates(
        GeoPoint(lat: _point.latitude, lng: _point.longitude),
      );
      if (!mounted) return;
      _detailsController.text = text;
    } catch (_) {
      // بنكمل بالوصف اليدوي.
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final point = await di<LocationService>().currentPosition();
      if (!mounted) return;
      setState(() {
        _point = LatLng(point.lat, point.lng);
        _isLocating = false;
      });
      await _resolveAddress();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      final message = error is AppException ? error.message : error.toString();
      showAppSnackBar(context, message, isError: true);
    }
  }

  void _confirm() {
    if (_detailsController.text.trim().isEmpty) {
      showAppSnackBar(context, 'اكتب وصف العنوان (اسم الشارع / علامة مميزة).', isError: true);
      return;
    }
    Navigator.of(context).pop(
      PickedAddress(
        lat: _point.latitude,
        lng: _point.longitude,
        label: _label,
        details: _detailsController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('تحديد العنوان على الخريطة')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MapView(
                  center: _point,
                  zoom: 15,
                  markers: {
                    MapHelpers.marker(
                      id: 'picked',
                      lat: _point.latitude,
                      lng: _point.longitude,
                      title: 'عنوان التوصيل',
                      color: AppColors.primary,
                    ),
                  },
                  onTap: (latLng) {
                    setState(() => _point = latLng);
                    _resolveAddress();
                  },
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: AppText(
                            'اضغط على الخريطة لتحديد مكان التسليم بالظبط',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                        IconButton(
                          onPressed: _isLocating ? null : _useCurrentLocation,
                          icon: Icon(Icons.my_location,
                              color: Theme.of(context).colorScheme.primary),
                          tooltip: trOf(context, 'موقعي الحالي'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final label in const ['البيت', 'الشغل', 'المتجر', 'أخرى'])
                      ChoiceChip(
                        label: AppText(label),
                        selected: _label == label,
                        onSelected: (_) => setState(() => _label = label),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _detailsController,
                  label: 'وصف العنوان',
                  hint: 'مثال: شارع الجيش - عمارة 12 - الدور 3',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  suffix: _isResolving
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'تأكيد العنوان',
                  icon: Icons.check,
                  onPressed: _confirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
