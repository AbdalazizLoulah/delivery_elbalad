import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/utils/order_ui.dart';
import '../bloc/delivery_orders_bloc.dart';
import '../widgets/courier_cancel_order_button.dart';
import '../widgets/courier_order_card.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// لوحة الطيار: حالة الاستلام + الأرباح + العروض والطلبات القريبة.
class CourierDashboardPage extends StatelessWidget {
  const CourierDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('لوحة الطلبات'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: trOf(context, 'تحديث'),
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<DeliveryOrdersBloc>().add(const DeliveryDashboardRefreshed()),
          ),
        ],
      ),
      body: BlocConsumer<DeliveryOrdersBloc, DeliveryOrdersState>(
        listenWhen: (previous, current) =>
            (current.successMessage ?? '').isNotEmpty && current.successMessage != previous.successMessage ||
            (current.errorMessage != null && current.errorMessage != previous.errorMessage),
        listener: (context, state) {
          if (state.errorMessage != null) {
            showAppSnackBar(context, state.errorMessage!, isError: true);
          } else if ((state.successMessage ?? '').isNotEmpty) {
            showAppSnackBar(context, state.successMessage!, isSuccess: true);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.myOrders.isEmpty && state.offered.isEmpty) {
            return const LoadingView(label: 'بنجهز طلباتك القريبة...');
          }

          final activeOrders = state.activeOrders;
          final hasAnything = activeOrders.isNotEmpty ||
              state.offered.isNotEmpty ||
              state.nearby.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DeliveryOrdersBloc>().add(const DeliveryDashboardRefreshed()),
            child: Responsive.centerContent(ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _AvailabilityCard(state: state),
                const SizedBox(height: 14),
                _EarningsRow(state: state),
                const SizedBox(height: 16),
                if (!hasAnything)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: EmptyView(
                      title: 'مفيش طلبات متاحة دلوقتي',
                      subtitle: state.isAvailable
                          ? 'استنى شوية، أول ما متجر يجهّز طلب قريب منك هيوصلك إشعار هنا'
                          : 'فعّل حالة "متاح" علشان توصلك الطلبات القريبة منك',
                      icon: Icons.delivery_dining_outlined,
                    ),
                  ),
                if (activeOrders.isNotEmpty) ...[
                  const SectionHeader(title: 'طلباتك الحالية'),
                  for (final order in activeOrders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CourierOrderCard(
                        order: order,
                        tripDistanceKm: order.distanceKm,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.orderDetails,
                          arguments: OrderDetailsArgs(orderId: order.id, fromCourier: true),
                        ),
                        footer: _ActiveOrderActions(order: order, state: state),
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                if (state.offered.isNotEmpty) ...[
                  const SectionHeader(title: 'طلبات معروضة عليك (أنت الأقرب)'),
                  for (final order in state.offered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CourierOrderCard(
                        order: order,
                        tripDistanceKm: order.distanceKm,
                        footer: _OfferActions(order: order, state: state),
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                if (state.nearby.isNotEmpty) ...[
                  const SectionHeader(title: 'طلبات جاهزة قريبة منك'),
                  for (final nearby in state.nearby)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CourierOrderCard(
                        order: nearby.order,
                        distanceToStoreKm: nearby.distanceFromCourierKm,
                        tripDistanceKm: nearby.tripDistanceKm,
                        footer: _OfferActions(order: nearby.order, state: state, isNearby: true),
                      ),
                    ),
                ],
                const SizedBox(height: 20),
              ],
            )),
          );
        },
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.state});

  final DeliveryOrdersState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: state.isAvailable
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.textHint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  state.isAvailable ? Icons.online_prediction : Icons.pause_circle_outline,
                  color: state.isAvailable ? AppColors.success : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      state.isAvailable ? 'متاح لاستلام طلبات' : 'متوقف عن استلام الطلبات',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    AppText(
                      state.myLocation == null
                          ? 'موقعك الحالي مش متحدد - الطلبات بتتحسب من آخر موقع معروف'
                          : 'موقعك: ${state.myLocation!.lat.toStringAsFixed(4)}، ${state.myLocation!.lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.isAvailable,
                onChanged: (value) =>
                    context.read<DeliveryOrdersBloc>().add(DeliveryAvailabilityToggled(value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  const _EarningsRow({required this.state});

  final DeliveryOrdersState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'أرباح اليوم',
            value: Formatters.money(state.todayEarnings),
            color: AppColors.success,
            icon: Icons.today_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: 'إجمالي الأرباح',
            value: Formatters.money(state.totalEarnings),
            color: AppColors.primary,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            label: 'توصيلات مكتملة',
            value: '${state.completedOrders.length}',
            color: AppColors.accent,
            icon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          AppText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          AppText(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OfferActions extends StatelessWidget {
  const _OfferActions({required this.order, required this.state, this.isNearby = false});

  final Order order;
  final DeliveryOrdersState state;
  final bool isNearby;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeliveryOrdersBloc>();
    final isUpdating = state.updatingOrderId == order.id;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: 'قبول الطلب',
              icon: Icons.check,
              isLoading: isUpdating,
              onPressed: () => bloc.add(DeliveryOfferAccepted(order)),
            ),
          ),
          if (!isNearby) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size(84, 52),
              ),
              onPressed: isUpdating ? null : () => bloc.add(DeliveryOfferDeclined(order)),
              child: const AppText('تجاهل'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveOrderActions extends StatelessWidget {
  const _ActiveOrderActions({required this.order, required this.state});

  final Order order;
  final DeliveryOrdersState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DeliveryOrdersBloc>();
    final isUpdating = state.updatingOrderId == order.id;
    final next = order.nextCourierStatus;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          if (next != null)
            AppPrimaryButton(
              label: _labelFor(next),
              icon: next.icon,
              isLoading: isUpdating,
              onPressed: () => bloc.add(DeliveryStatusAdvanced(order)),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.orderDetails,
              arguments: OrderDetailsArgs(orderId: order.id, fromCourier: true),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 18),
                SizedBox(width: 6),
                AppText('تفاصيل الطلب والخريطة'),
              ],
            ),
          ),
          CourierCancelOrderButton(order: order),
        ],
      ),
    );
  }

  String _labelFor(OrderStatus status) => switch (status) {
        OrderStatus.pickedUp => 'استلمت الطلب من المتجر',
        OrderStatus.onTheWay => 'في الطريق للعميل',
        OrderStatus.delivered => 'تم تسليم الطلب',
        _ => 'تحديث الحالة',
      };
}
