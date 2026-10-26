import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/utils/order_ui.dart';
import '../../../orders/presentation/widgets/order_card.dart';
import '../bloc/seller_orders_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/utils/responsive.dart';
/// طلبات المتجر: طابور جديد / قيد التجهيز / منتهية.
class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return BlocProvider(
      create: (_) => di<SellerOrdersBloc>()..add(SellerOrdersStarted(user.id)),
      child: const _SellerOrdersView(),
    );
  }
}

class _SellerOrdersView extends StatelessWidget {
  const _SellerOrdersView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('طلبات المتجر'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [
              Tab(child: AppText('جديدة')),
              Tab(child: AppText('قيد التنفيذ')),
              Tab(child: AppText('منتهية')),
            ],
          ),
        ),
        body: BlocConsumer<SellerOrdersBloc, SellerOrdersState>(
          listenWhen: (previous, current) =>
              (current.lastUpdatedStatus != previous.lastUpdatedStatus) ||
              (current.errorMessage != null && previous.errorMessage != current.errorMessage),
          listener: (context, state) {
            if (state.errorMessage != null) {
              showAppSnackBar(context, state.errorMessage!, isError: true);
            }
            if (state.lastUpdatedStatus != null) {
              showAppSnackBar(context, 'تم تحديث الطلب: ${state.lastUpdatedStatus!.label}',
                  isSuccess: true);
            }
          },
          builder: (context, state) {
            if (state.isLoading) return const LoadingView();
            return TabBarView(
              children: [
                _OrdersTab(orders: state.newOrders, emptyTitle: 'مفيش طلبات جديدة'),
                _OrdersTab(orders: state.inProgress, emptyTitle: 'مفيش طلبات قيد التنفيذ'),
                _OrdersTab(orders: state.finished, emptyTitle: 'مفيش طلبات منتهية', finished: true),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.orders, required this.emptyTitle, this.finished = false});

  final List<Order> orders;
  final String emptyTitle;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Responsive.centerContent(ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: EmptyView(title: emptyTitle, icon: Icons.receipt_long_outlined),
          ),
        ],
      ));
    }

    return Responsive.centerContent(ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final bloc = context.read<SellerOrdersBloc>();
        final isUpdating = context.watch<SellerOrdersBloc>().state.updatingOrderId == order.id;
        final next = order.nextSellerStatus;

        return OrderCard(
          order: order,
          showBuyer: true,
          subtitle: '${order.items.length} منتج • ${order.addressDetails}',
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.orderDetails,
            arguments: OrderDetailsArgs(orderId: order.id),
          ),
          trailing: const SizedBox.shrink(),
          // أزرار التحكم في حالة الطلب
          footer: !finished && next != null
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: _actionLabel(order.status),
                            icon: order.status.icon,
                            isLoading: isUpdating,
                            onPressed: () => bloc.add(SellerOrderAdvanced(order)),
                          ),
                        ),
                        if (order.canBeCancelledByBuyer) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              minimumSize: const Size(80, 52),
                            ),
                            onPressed: isUpdating ? null : () => bloc.add(SellerOrderCancelled(order)),
                            child: const AppText('رفض'),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              : null,
        );
      },
    ));
  }

  String _actionLabel(OrderStatus status) => switch (status) {
        OrderStatus.pendingSeller => 'قبول الطلب',
        OrderStatus.confirmed => 'ابدأ التجهيز',
        OrderStatus.preparing => 'جاهز للاستلام',
        OrderStatus.readyForPickup => 'بانتظار طيار',
        _ => 'تحديث',
      };
}
