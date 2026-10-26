import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/seller_orders_bloc.dart';
import '../bloc/seller_products_bloc.dart';
import 'seller_products_page.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/utils/responsive.dart';
/// لوحة المتجر: ملخص سريع للطلبات والمنتجات والأرباح.
class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di<SellerOrdersBloc>()..add(SellerOrdersStarted(user.id))),
        BlocProvider(create: (_) => di<SellerProductsBloc>()..add(SellerProductsStarted(user.id))),
      ],
      child: _SellerDashboardView(user: user),
    );
  }
}

class _SellerDashboardView extends StatelessWidget {
  const _SellerDashboardView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('لوحة المتجر'),
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<SellerOrdersBloc, SellerOrdersState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null && previous.errorMessage != current.errorMessage,
        listener: (context, state) =>
            showAppSnackBar(context, state.errorMessage ?? '', isError: true),
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<SellerOrdersBloc>().add(SellerOrdersStarted(user.id));
            context.read<SellerProductsBloc>().add(SellerProductsStarted(user.id));
          },
          child: Responsive.centerContent(ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _StoreHeader(user: user),
              const SizedBox(height: 14),
              BlocBuilder<SellerOrdersBloc, SellerOrdersState>(
                builder: (context, state) {
                  if (state.isLoading && state.orders.isEmpty) return const LoadingView();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'طلبات جديدة',
                              value: '${state.newOrders.length}',
                              icon: Icons.hourglass_empty,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'قيد التنفيذ',
                              value: '${state.inProgress.length}',
                              icon: Icons.shopping_basket_outlined,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'تم التسليم',
                              value:
                                  '${state.finished.where((order) => order.status == OrderStatus.delivered).length}',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'إجمالي المبيعات',
                              value: Formatters.money(state.revenue),
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              BlocBuilder<SellerProductsBloc, SellerProductsState>(
                builder: (context, state) => _StatCard(
                  label: 'منتجات المتجر',
                  value: '${state.products.length} منتج',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'إجراءات سريعة'),
              AppPrimaryButton(
                label: 'إضافة منتج جديد',
                icon: Icons.add,
                onPressed: () => openProductForm(context),
              ),
              const SizedBox(height: 10),
              AppPrimaryButton(
                outlined: true,
                label: 'تعديل بيانات المتجر وموقعها',
                icon: Icons.edit_location_alt_outlined,
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profileEdit),
              ),
              const SizedBox(height: 20),
            ],
          )),
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            child: AppText(
              user.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(user.fullName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                RoleBadge(role: user.role),
                const SizedBox(height: 6),
                AppText(
                  user.addressText?.isNotEmpty ?? false
                      ? user.addressText!
                      : 'لسه محددتش عنوان المتجر',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                AppText(
                  user.hasLocation
                      ? 'الطلبات بتتوزع على الطيارين حسب أقرب موقع للمتجر'
                      : 'حدّد موقع المتجر من تعديل البيانات علشان توصلك الطلبات الأقرب',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          AppText(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          AppText(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
