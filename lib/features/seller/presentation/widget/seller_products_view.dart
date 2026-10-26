import 'package:delivery_elbalad/core/widgets/app_snack_bar.dart';
import 'package:delivery_elbalad/core/widgets/feedback_widgets.dart';
import 'package:delivery_elbalad/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:delivery_elbalad/features/seller/presentation/bloc/seller_products_bloc.dart';
import 'package:delivery_elbalad/features/seller/presentation/pages/seller_products_page.dart';
import 'package:delivery_elbalad/features/seller/presentation/widget/seller_product_tile.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
class SellerProductsView extends StatelessWidget {
  const SellerProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText('منتجاتي'),
        actions: [
          IconButton(
            tooltip: trOf(context, 'إضافة منتج'),
            icon: const Icon(Icons.add),
            onPressed: () => openProductForm(context),
          ),
        ],
      ),
      body: BlocConsumer<SellerProductsBloc, SellerProductsState>(
        listenWhen: (previous, current) =>
            (current.savedProductId != null && previous.savedProductId != current.savedProductId) ||
            (current.errorMessage != null && previous.errorMessage != current.errorMessage),
        listener: (context, state) {
          if (state.errorMessage != null) {
            showAppSnackBar(context, state.errorMessage!, isError: true);
          } else if (state.savedProductId != null) {
            showAppSnackBar(context, 'اتحفظ المنتج ✅', isSuccess: true);
          }
        },
        builder: (context, state) {
          if (state.isLoading) return const LoadingView();
          if (state.products.isEmpty) {
            return EmptyView(
              title: 'مفيش منتجات لسه',
              subtitle: 'ضيف أول منتج وابدأ تستقبل طلبات من العملاء',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'إضافة منتج',
              onAction: () => openProductForm(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final user = context.read<AuthBloc>().state.user;
              if (user != null) {
                context.read<SellerProductsBloc>().add(SellerProductsStarted(user.id));
              }
            },
            child: Responsive.centerContent(ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = state.products[index];
                return SellerProductTile(product: product);
              },
            )),
          );
        },
      ),
    );
  }
}
