import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/order_usecases.dart';
import '../bloc/buyer_orders_bloc.dart';
import '../utils/order_ui.dart';
import '../widgets/order_card.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/utils/responsive.dart';
/// قايمة طلبات المشتري (الحالية والسابقة).
class BuyerOrdersPage extends StatelessWidget {
  const BuyerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return BlocProvider(
      create: (_) => di<BuyerOrdersBloc>()..add(BuyerOrdersStarted(user.id)),
      child: const _BuyerOrdersView(),
    );
  }
}

class _BuyerOrdersView extends StatelessWidget {
  const _BuyerOrdersView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const AppText('طلباتي'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [Tab(child: AppText('جارية')), Tab(child: AppText('السابقة'))],
          ),
        ),
        body: BlocConsumer<BuyerOrdersBloc, BuyerOrdersState>(
          listenWhen: (previous, current) => current.errorMessage != null,
          listener: (context, state) =>
              showAppSnackBar(context, state.errorMessage ?? '', isError: true),
          builder: (context, state) {
            if (state.isLoading) return const LoadingView();
            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () async => context.read<BuyerOrdersBloc>().add(const BuyerOrdersRefreshed()),
                  child: _OrdersList(
                    orders: state.activeOrders,
                    emptyTitle: 'مفيش طلبات جارية',
                    emptySubtitle: 'اطلب من الصفحة الرئيسية واتابع الطلب لحظة بلحظة',
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () async => context.read<BuyerOrdersBloc>().add(const BuyerOrdersRefreshed()),
                  child: _OrdersList(
                    orders: state.pastOrders,
                    emptyTitle: 'مفيش طلبات سابقة',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyTitle,
    this.emptySubtitle,
  });

  final List<Order> orders;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Responsive.centerContent(ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyView(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: Icons.receipt_long_outlined,
            ),
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
        return OrderCard(
          order: order,
          subtitle: order.status.description,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.orderDetails,
            arguments: OrderDetailsArgs(orderId: order.id),
          ),
          footer: order.canBeRated
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => _rateCourier(context, order),
                    icon: const Icon(Icons.star_border_rounded, size: 18),
                    label: const AppText('قيّم الطيار'),
                  ),
                )
              : null,
        );
      },
    ));
  }

  Future<void> _rateCourier(BuildContext context, Order order) async {
    final courierId = order.courierId;
    if (courierId == null || courierId.isEmpty) {
      showAppSnackBar(context, 'الطلب لسه ما اتسندش لطيار.', isError: true);
      return;
    }
    final input = await showCourierRatingDialog(context);
    if (input == null || !context.mounted) return;

    final result = await di<RateDeliveryUseCase>()(
      RateDeliveryParams(
        orderId: order.id,
        courierId: courierId,
        rating: input.rating,
        comment: input.comment,
        buyerName: order.buyerName,
      ),
    );
    if (!context.mounted) return;
    result.fold(
      (_) {
        showAppSnackBar(context, 'تم تسجيل تقييمك، شكرًا!', isSuccess: true);
        context.read<BuyerOrdersBloc>().add(const BuyerOrdersRefreshed());
      },
      (failure) => showAppSnackBar(context, failure.message, isError: true),
    );
  }
}
