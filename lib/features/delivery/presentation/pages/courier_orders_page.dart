import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/delivery_orders_bloc.dart';
import '../widgets/courier_cancel_order_button.dart';
import '../widgets/courier_order_card.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// توصيلات الطيار: الجارية والمكتملة مع أرباح كل طلب.
///
/// الصفحة بتقرأ `DeliveryOrdersBloc` من الشجرة (بيتم توفيره في شل الطيار أو
/// في الغلاف المستقل).
class CourierOrdersPage extends StatelessWidget {
  const CourierOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('توصيلاتي'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: trOf(context, 'تحديث'),
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<DeliveryOrdersBloc>().add(const DeliveryDashboardRefreshed()),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [Tab(child: AppText('جارية')), Tab(child: AppText('مكتملة'))],
          ),
        ),
        body: BlocConsumer<DeliveryOrdersBloc, DeliveryOrdersState>(
          listenWhen: (previous, current) =>
              (current.successMessage ?? '').isNotEmpty &&
                  current.successMessage != previous.successMessage ||
              (current.errorMessage != null && current.errorMessage != previous.errorMessage),
          listener: (context, state) {
            if (state.errorMessage != null) {
              showAppSnackBar(context, state.errorMessage!, isError: true);
            } else if ((state.successMessage ?? '').isNotEmpty) {
              showAppSnackBar(context, state.successMessage!, isSuccess: true);
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.myOrders.isEmpty) {
              return const LoadingView(label: 'بنجيب توصيلاتك...');
            }

            return TabBarView(
              children: [
                _OrdersList(
                  orders: state.activeOrders,
                  emptyTitle: 'مفيش توصيلات جارية',
                  emptySubtitle: 'اقبل طلب من اللوحة وابدأ التوصيل',
                  showAdvanceButton: true,
                ),
                _OrdersList(
                  orders: state.completedOrders,
                  emptyTitle: 'مفيش توصيلات مكتملة',
                  emptySubtitle: 'أول ما تسلّم طلب هيظهر هنا مع أرباحه',
                  header: _CompletedHeader(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({required this.state});

  final DeliveryOrdersState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('إجمالي أرباحك',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                AppText(
                  Formatters.money(state.totalEarnings),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          AppText(
            '${state.completedOrders.length} طلب',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyTitle,
    this.emptySubtitle,
    this.header,
    this.showAdvanceButton = false,
  });

  final List<Order> orders;
  final String emptyTitle;
  final String? emptySubtitle;
  final Widget? header;
  final bool showAdvanceButton;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Responsive.centerContent(ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: EmptyView(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: Icons.delivery_dining_outlined,
            ),
          ),
        ],
      ));
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<DeliveryOrdersBloc>().add(const DeliveryDashboardRefreshed()),
      child: Responsive.centerContent(ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length + (header == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (header != null && index == 0) return header!;
          final order = orders[index - (header == null ? 0 : 1)];
          final isUpdating =
              context.watch<DeliveryOrdersBloc>().state.updatingOrderId == order.id;
          final next = order.nextCourierStatus;

          return CourierOrderCard(
            order: order,
            tripDistanceKm: order.distanceKm,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.orderDetails,
              arguments: OrderDetailsArgs(orderId: order.id, fromCourier: true),
            ),
            footer: showAdvanceButton
                ? Column(
                    children: [
                      if (next != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FilledButton(
                            onPressed: isUpdating
                                ? null
                                : () => context
                                    .read<DeliveryOrdersBloc>()
                                    .add(DeliveryStatusAdvanced(order)),
                            child: isUpdating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2, color: Colors.white),
                                  )
                                : AppText(_labelFor(next),
                                    style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      CourierCancelOrderButton(order: order),
                    ],
                  )
                : null,
          );
        },
      )),
    );
  }

  String _labelFor(OrderStatus status) => switch (status) {
        OrderStatus.pickedUp => 'استلمت الطلب من المتجر',
        OrderStatus.onTheWay => 'في الطريق للعميل',
        OrderStatus.delivered => 'تم تسليم الطلب',
        _ => 'تحديث الحالة',
      };
}
