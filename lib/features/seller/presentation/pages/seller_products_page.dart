import 'package:delivery_elbalad/features/seller/presentation/widget/seller_product_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../catalog/domain/entities/product.dart';
import '../bloc/seller_products_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// بيفتح شاشة إضافة/تعديل المنتج، وبعد الرجوع بيبعت الناتج للبلوك للحفظ.
Future<void> openProductForm(BuildContext context, {Product? product}) async {
  final result = await Navigator.of(context).pushNamed(
    AppRoutes.sellerProductForm,
    arguments: ProductFormArgs(product: product),
  );
  if (result is Product && context.mounted) {
    context.read<SellerProductsBloc>().add(SellerProductSaved(result));
  }
}

/// صفحة منتجات البائع (إضافة / تعديل / حذف).
class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => SellerProductsPageState();
}

class SellerProductsPageState extends State<SellerProductsPage> {
  SellerProductsBloc? _bloc;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      _bloc = di<SellerProductsBloc>()..add(SellerProductsStarted(user.id));
    }
  }

  /// بنعيد تحميل المنتجات من البيانات (بعد الإضافة من تاب تاني أو شراء عميل).
  void refresh() {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    final current = _bloc;
    if (current != null) {
      current.add(SellerProductsStarted(user.id));
      return;
    }
    final fresh = di<SellerProductsBloc>()..add(SellerProductsStarted(user.id));
    setState(() => _bloc = fresh);
  }

  @override
  void dispose() {
    _bloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    final bloc = _bloc;
    if (bloc == null) return const Scaffold(body: LoadingView());
    return BlocProvider.value(value: bloc, child: const _SellerProductsView());
  }
}

class _SellerProductsView extends StatelessWidget {
  const _SellerProductsView();

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth > 720 ? 40.0 : 12.0;
                return Responsive.centerContent(ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 12),
                  itemCount: state.products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return SellerProductTile(product: product);
                  },
                ));
              },
            ),
          );
        },
      ),
    );
  }
}
