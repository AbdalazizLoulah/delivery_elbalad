import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../bloc/delivery_orders_bloc.dart';
import 'courier_dashboard_page.dart';
import 'courier_orders_page.dart';

import '../../../../core/localization/app_text.dart';
/// الشاشة الرئيسية للطيار: لوحة الطلبات / توصيلاتي / حسابي.
class CourierShellPage extends StatelessWidget {
  const CourierShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.role != UserRole.courier) {
      return const Scaffold(
        body: ErrorView(message: 'الصفحة دي مخصصة لحسابات الدليفاري.'),
      );
    }

    return BlocProvider<DeliveryOrdersBloc>(
      create: (_) => di<DeliveryOrdersBloc>()..add(DeliveryDashboardStarted(user)),
      child: const _CourierShellView(),
    );
  }
}

/// نسخة مستقلة من "توصيلاتي" لما المستخدم يفتحها من الملف الشخصي.
class CourierOrdersStandalonePage extends StatelessWidget {
  const CourierOrdersStandalonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.role != UserRole.courier) {
      return const Scaffold(
        body: ErrorView(message: 'الصفحة دي مخصصة لحسابات الدليفاري.'),
      );
    }

    return BlocProvider<DeliveryOrdersBloc>(
      create: (_) => di<DeliveryOrdersBloc>()..add(DeliveryDashboardStarted(user)),
      child: const CourierOrdersPage(),
    );
  }
}

class _CourierShellView extends StatefulWidget {
  const _CourierShellView();

  @override
  State<_CourierShellView> createState() => _CourierShellViewState();
}

class _CourierShellViewState extends State<_CourierShellView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final offeredCount = context.select<DeliveryOrdersBloc, int>((bloc) => bloc.state.offered.length);
    final activeCount = context.select<DeliveryOrdersBloc, int>((bloc) => bloc.state.activeOrders.length);
    final locale = Localizations.localeOf(context);

    // بنزامن حالة الاتاحة والموقع الحالي مع حساب الطيار في الجلسة،
    // علشان مراقب الإشعارات يستخدم نفس البيانات المحدّثة بدل بيانات قديمة.
    return BlocListener<DeliveryOrdersBloc, DeliveryOrdersState>(
      listenWhen: (previous, current) =>
          previous.isAvailable != current.isAvailable ||
          previous.myLocation?.lat != current.myLocation?.lat ||
          previous.myLocation?.lng != current.myLocation?.lng,
      listener: (context, state) {
        final auth = context.read<AuthBloc>();
        final user = auth.state.user;
        if (user == null || user.role != UserRole.courier) return;

        final location = state.myLocation;
        final updated = user.copyWith(
          isAvailable: state.isAvailable,
          lat: location?.lat,
          lng: location?.lng,
        );
        if (updated.isAvailable != user.isAvailable ||
            updated.lat != user.lat ||
            updated.lng != user.lng) {
          auth.add(AuthProfileChanged(updated));
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            CourierDashboardPage(),
            CourierOrdersPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          items: [
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: offeredCount > 0,
                label: AppText('$offeredCount'),
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.delivery_dining_outlined),
              ),
              activeIcon: const Icon(Icons.delivery_dining),
              label: tr('الطلبات', locale: locale),
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: activeCount > 0,
                label: AppText('$activeCount'),
                child: const Icon(Icons.route_outlined),
              ),
              activeIcon: const Icon(Icons.route),
              label: tr('توصيلاتي', locale: locale),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: tr('حسابي', locale: locale),
            ),
          ],
        ),
      ),
    );
  }
}
