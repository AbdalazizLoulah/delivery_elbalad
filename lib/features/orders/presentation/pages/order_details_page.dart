import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../../core/widgets/map_view.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_tracking_bloc.dart';
import '../utils/order_ui.dart';
import '../widgets/order_card.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// صفحة تفاصيل وتتبع الطلب: خريطة حية + خط زمني + تقييم الدليفاري.
class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId, this.fromCourier = false});

  final String orderId;
  final bool fromCourier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<OrderTrackingBloc>()..add(OrderTrackingStarted(orderId)),
      child: _OrderDetailsView(orderId: orderId, fromCourier: fromCourier),
    );
  }
}

class _OrderDetailsView extends StatefulWidget {
  const _OrderDetailsView({required this.orderId, required this.fromCourier});

  final String orderId;
  final bool fromCourier;

  @override
  State<_OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<_OrderDetailsView> {
  bool _promptScheduled = false;

  void _scheduleRatingPrompt(BuildContext context, Order order) {
    if (_promptScheduled ||
        widget.fromCourier ||
        order.courierId == null ||
        order.courierId!.isEmpty) {
      return;
    }
    _promptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final current = context.read<OrderTrackingBloc>().state.order;
      if (current == null || !current.canBeRated) return;

      // بنسأل مرة واحدة بس لكل طلب، وبعدها الزرار بيفضل موجود في الصفحة والكارت.
      final preferences = di<SharedPreferences>();
      final key = 'courier_rating_prompted_${current.id}';
      if (preferences.getBool(key) ?? false) return;
      await preferences.setBool(key, true);

      if (!mounted || !context.mounted) return;
      final input = await showCourierRatingDialog(context);
      if (input == null || !mounted || !context.mounted) return;
      context.read<OrderTrackingBloc>().add(
            OrderTrackingRateRequested(
              rating: input.rating,
              comment: input.comment,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = context.read<AuthBloc>().state.user?.role == UserRole.buyer;
    return BlocConsumer<OrderTrackingBloc, OrderTrackingState>(
      listenWhen: (previous, current) =>
          (current.errorMessage != null && previous.errorMessage != current.errorMessage) ||
          (current.ratingSubmitted && !previous.ratingSubmitted),
      listener: (context, state) {
        if (state.ratingSubmitted) {
          showAppSnackBar(context, 'تم تسجيل تقييمك، شكرًا!', isSuccess: true);
        } else {
          showAppSnackBar(context, state.errorMessage ?? '', isError: true);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.order == null) return const Scaffold(body: LoadingView());
        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const AppText('تفاصيل الطلب')),
            body: ErrorView(
              message: state.errorMessage ?? 'مش قادرين نحمل الطلب',
              onRetry: () => context
                  .read<OrderTrackingBloc>()
                  .add(OrderTrackingStarted(widget.orderId)),
            ),
          );
        }

        if (isBuyer && order.canBeRated) _scheduleRatingPrompt(context, order);

        return Scaffold(
          appBar: AppBar(title: AppText('طلب ${order.code}')),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<OrderTrackingBloc>().add(OrderTrackingStarted(order.id));
            },
            child: Responsive.centerContent(ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _StatusHeader(
                  order: order,
                  courierLocation: state.courierLocation,
                  remainingDistanceKm: state.remainingDistanceKm,
                  hasRoadRoute: state.hasRoadRoute,
                ),
                const SizedBox(height: 12),
                _TrackingMap(
                  order: order,
                  courierLocation: state.courierLocation,
                  remainingDistanceKm: state.remainingDistanceKm,
                  remainingDurationMinutes: state.remainingDurationMinutes,
                  routePoints: state.routePoints,
                  hasRoadRoute: state.hasRoadRoute,
                ),
                const SizedBox(height: 14),
                if (order.hasCourier) _CourierCard(order: order),
                if (isBuyer && (order.canBeRated || order.deliveryRating != null)) ...[
                  const SizedBox(height: 10),
                  _RatingSection(order: order, isSubmitting: state.isRating),
                ],
                const SizedBox(height: 14),
                const SectionHeader(title: 'مراحل الطلب'),
                _Timeline(order: order),
                const SizedBox(height: 14),
                const SectionHeader(title: 'تفاصيل التسليم'),
                _DeliveryDetails(order: order),
                const SizedBox(height: 14),
                const SectionHeader(title: 'الفاتورة'),
                _Invoice(order: order),
                const SizedBox(height: 14),
                const SectionHeader(title: 'المنتجات'),
                for (final item in order.items) _ItemTile(item: item),
                const SizedBox(height: 20),
              ],
            )),
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.order,
    this.courierLocation,
    this.remainingDistanceKm,
    this.hasRoadRoute = false,
  });

  final Order order;
  final CourierLocation? courierLocation;
  final double? remainingDistanceKm;
  final bool hasRoadRoute;

  @override
  Widget build(BuildContext context) {
    final distanceKm = remainingDistanceKm ??
        (courierLocation == null
            ? null
            : DistanceCalculator.betweenKm(
                fromLat: courierLocation!.lat,
                fromLng: courierLocation!.lng,
                toLat: order.addressLat,
                toLng: order.addressLng,
              ));

    final statusColor = order.status.colorFor(context);
    return AppCard(
      color: statusColor.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(order.status.icon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(order.status.label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    AppText(order.status.description,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (distanceKm != null && order.status.isActive) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                AppText(
                  'الطيار فاضل عليه ${Formatters.distanceKm(distanceKm)}'
                  '${hasRoadRoute ? ' بالطريق' : ''}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// خريطة التتبع داخل الصفحة + المسافة المتبقية بين الطيار والعميل.
class _TrackingMap extends StatelessWidget {
  const _TrackingMap({
    required this.order,
    this.courierLocation,
    this.remainingDistanceKm,
    this.remainingDurationMinutes,
    this.routePoints,
    this.hasRoadRoute = false,
  });

  final Order order;
  final CourierLocation? courierLocation;
  final double? remainingDistanceKm;
  final double? remainingDurationMinutes;
  final List<LatLng>? routePoints;
  final bool hasRoadRoute;

  @override
  Widget build(BuildContext context) {
    final data = _TrackingMapData.of(order, courierLocation, roadPoints: routePoints);
    final isActive = order.status.isActive;
    final showDistance = remainingDistanceKm != null && isActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 230,
            child: Stack(
              children: [
                MapView(
                  center: data.center,
                  markers: data.markers,
                  polylines: data.polylines,
                  zoom: 14,
                  interactive: false,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      tooltip: trOf(context, 'فتح الخريطة كاملة'),
                      icon: const Icon(Icons.fullscreen, size: 22),
                      onPressed: () => _openFullScreen(context),
                    ),
                  ),
                ),
                if (showDistance)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _MapDistanceBadge(
                      distanceKm: remainingDistanceKm!,
                      durationMinutes: remainingDurationMinutes,
                      byRoad: hasRoadRoute,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openFullScreen(context),
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const AppText('فتح الخريطة كاملة'),
        ),
        if (isActive && !showDistance) ...[
          const SizedBox(height: 6),
          const AppText(
            'هتظهر المسافة المتبقية بين الطيار وعنوانك لحظة ما الطيار يبدأ التوصيل.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<OrderTrackingBloc>(),
          child: const _FullScreenTrackingMap(),
        ),
      ),
    );
  }
}

/// شاشة الخريطة كاملة الشاشة — بتتابع تحديثات الطيار لحظة بلحظة (جوّه التطبيق).
class _FullScreenTrackingMap extends StatelessWidget {
  const _FullScreenTrackingMap();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText('تتبع الطلب على الخريطة')),
      body: BlocBuilder<OrderTrackingBloc, OrderTrackingState>(
        builder: (context, state) {
          final order = state.order;
          if (order == null) return const LoadingView();
          final data = _TrackingMapData.of(order, state.courierLocation,
              roadPoints: state.routePoints);
          final showDistance =
              state.remainingDistanceKm != null && order.status.isActive;
          return Stack(
            children: [
              MapView(
                center: data.center,
                markers: data.markers,
                polylines: data.polylines,
                zoom: 15,
              ),
              if (showDistance)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapDistanceBadge(
                    distanceKm: state.remainingDistanceKm!,
                    durationMinutes: state.remainingDurationMinutes,
                    byRoad: state.hasRoadRoute,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// شارة المسافة المتبقية المعروضة على الخريطة.
class _MapDistanceBadge extends StatelessWidget {
  const _MapDistanceBadge({
    required this.distanceKm,
    this.durationMinutes,
    this.byRoad = false,
  });

  final double distanceKm;
  final double? durationMinutes;
  final bool byRoad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route, size: 15, color: AppColors.primary),
              const SizedBox(width: 5),
              AppText(
                'المتبقي ${Formatters.distanceKm(distanceKm)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 2),
          AppText(
            durationMinutes != null
                ? 'الوصول خلال ${Formatters.durationMinutes(durationMinutes!)}'
                : (byRoad ? 'حسب الطريق' : 'خط مباشر (تقديري)'),
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// بيانات الخريطة المشتركة بين العرض المصغر والشاشة الكاملة.
class _TrackingMapData {
  const _TrackingMapData({
    required this.center,
    required this.markers,
    required this.polylines,
  });

  final LatLng center;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  static _TrackingMapData of(
    Order order,
    CourierLocation? courier, {
    List<LatLng>? roadPoints,
  }) {
    final storePoint = order.storeLat != null && order.storeLng != null
        ? LatLng(order.storeLat!, order.storeLng!)
        : null;
    final courierPoint = courier == null ? null : LatLng(courier.lat, courier.lng);
    final buyerPoint = LatLng(order.addressLat, order.addressLng);

    final markers = <Marker>{
      if (storePoint != null)
        MapHelpers.marker(
          id: 'store',
          lat: storePoint.latitude,
          lng: storePoint.longitude,
          title: 'المتجر',
          snippet: order.storeName.isEmpty ? order.sellerName : order.storeName,
          color: AppColors.info,
        ),
      MapHelpers.marker(
        id: 'buyer',
        lat: buyerPoint.latitude,
        lng: buyerPoint.longitude,
        title: 'عنوان التسليم',
        snippet: order.addressLabel,
        color: AppColors.success,
      ),
      if (courierPoint != null)
        MapHelpers.marker(
          id: 'courier',
          lat: courierPoint.latitude,
          lng: courierPoint.longitude,
          title: 'الطيار ${order.courierName}',
          color: AppColors.accent,
        ),
    };

    // خط الطريق الحقيقي (OSRM) لو موجود، وإلا خط مباشر كبديل.
    final hasRoad = roadPoints != null && roadPoints.length > 1;
    final pathPoints = hasRoad
        ? roadPoints
        : <LatLng>[
            ?courierPoint,
            buyerPoint,
          ];

    return _TrackingMapData(
      center: courierPoint ?? storePoint ?? buyerPoint,
      markers: markers,
      polylines: {
        if (pathPoints.length > 1)
          MapHelpers.route(
            id: 'route',
            points: pathPoints,
            color: hasRoad ? AppColors.primary : AppColors.info,
          ),
      },
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accentLight,
            child: const Icon(Icons.delivery_dining, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('الطيار المسؤول',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                AppText(order.courierName.isEmpty ? 'جاري التعيين' : order.courierName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              ],
            ),
          ),
          if (order.courierPhone.isNotEmpty)
            IconButton(
              tooltip: trOf(context, 'اتصل بالطيار'),
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: order.courierPhone);
                final canLaunch = await canLaunchUrl(uri);
                if (!context.mounted) return;
                if (canLaunch) {
                  await launchUrl(uri);
                } else {
                  showAppSnackBar(context, 'مش قادرين نفتح الاتصال.', isError: true);
                }
              },
              icon: const Icon(Icons.call, color: AppColors.success),
            ),
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.order, required this.isSubmitting});

  final Order order;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    if (order.deliveryRating != null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('تقييمك للطيار',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  if ((order.deliveryReview ?? '').isNotEmpty)
                    AppText(order.deliveryReview!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            RatingStars(rating: order.deliveryRating!.toDouble()),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          const AppText('قيّم الطيار وخلّي الناس تعرف تجربتك',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          const SizedBox(height: 8),
          AppPrimaryButton(
            label: isSubmitting ? 'بنسجل التقييم...' : 'قيّم الدليفاري',
            icon: Icons.star_border_rounded,
            isLoading: isSubmitting,
            onPressed: () => _showRatingDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    final input = await showCourierRatingDialog(context);
    if (input == null || !context.mounted) return;
    context.read<OrderTrackingBloc>().add(
          OrderTrackingRateRequested(
            rating: input.rating,
            comment: input.comment,
          ),
        );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final events = order.timeline.reversed.toList();
    if (events.isEmpty) {
      return const AppText('لسه مفيش تحديثات على الطلب.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
    }

    return AppCard(
      child: Column(
        children: [
          for (var index = 0; index < events.length; index++)
            _TimelineTile(
              event: events[index],
              isLast: index == events.length - 1,
              isCurrent: index == 0,
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.isCurrent,
  });

  final OrderEvent event;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? event.status.colorFor(context) : AppColors.textHint;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(event.status.icon, size: 14, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).dividerTheme.color ??
                        Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    event.note.isEmpty ? event.status.label : event.note,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${Formatters.dateTime(event.createdAt)}${event.actorName.isEmpty ? '' : ' • ${event.actorName}'}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _Row(icon: Icons.place_outlined, label: 'العنوان', value: order.addressDetails),
          if (order.note.isNotEmpty)
            _Row(icon: Icons.sticky_note_2_outlined, label: 'ملاحظات', value: order.note),
          _Row(
            icon: Icons.timer_outlined,
            label: 'وقت الإنشاء',
            value: Formatters.dateTime(order.createdAt),
          ),
          if (order.deliveredAt != null)
            _Row(
              icon: Icons.check_circle_outline,
              label: 'وقت التسليم',
              value: Formatters.dateTime(order.deliveredAt!),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          AppText(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Invoice extends StatelessWidget {
  const _Invoice({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _InvoiceRow(label: 'إجمالي المنتجات', value: order.itemsSubtotal),
          _InvoiceRow(label: 'مصاريف الدليفاري', value: order.deliveryFee),
          const Divider(height: 18),
          _InvoiceRow(label: 'الإجمالي', value: order.total, isBold: true),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(status: order.status, compact: true),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.paymentStatus.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  '${order.paymentMethod.label} • ${order.paymentStatus.label}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: order.paymentStatus.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value, this.isBold = false});

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AppText(label,
              style: TextStyle(
                fontSize: isBold ? 14.5 : 13,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              )),
          const Spacer(),
          AppText(
            Formatters.money(value),
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: FontWeight.w800,
              color: isBold ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            AppNetworkImage(
              url: item.imageUrl,
              width: 48,
              height: 48,
              radius: 10,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  AppText('${item.quantity} × ${Formatters.money(item.unitPrice)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AppText(Formatters.money(item.total),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
