import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/utils/role_ui.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../../notifications/presentation/bloc/notifications_cubit.dart';
import '../bloc/profile_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// ملف المستخدم (مشتري / بائع / دليفاري) مع العنوانين وتسجيل الخروج.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return BlocProvider(
      create: (_) => di<ProfileBloc>()..add(ProfileStarted(user)),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          current.saved && !previous.saved ||
          (current.errorMessage != null && previous.errorMessage != current.errorMessage),
      listener: (context, state) {
        if (state.errorMessage != null) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        final user = state.displayUser;
        if (user == null) return const LoadingView();

        return Scaffold(
          appBar: AppBar(
            title: const AppText('ملفي الشخصي'),
            automaticallyImplyLeading: false,
            actions: [
              BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, notifications) {
                  final unread = notifications.unreadFor(user.role, user.id);
                  return IconButton(
                    tooltip: trOf(context, 'الإشعارات'),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: AppText('$unread'),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.notifications),
                  );
                },
              ),
              IconButton(
                tooltip: trOf(context, 'تعديل البيانات'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profileEdit),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              if (state.user != null) {
                context.read<ProfileBloc>().add(ProfileStarted(state.user!));
              }
            },
            child: Responsive.centerContent(ListView(
              padding: const EdgeInsets.all(14),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: user.roleColor.withValues(alpha: 0.15),
                        child: AppText(
                          user.initials,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: user.roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(user.fullName,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            RoleBadge(role: user.role),
                            const SizedBox(height: 6),
                            AppText(user.email,
                                style: const TextStyle(
                                    fontSize: 12.5, color: AppColors.textSecondary)),
                            if (user.phone.isNotEmpty)
                              AppText(user.phone,
                                  style: const TextStyle(
                                      fontSize: 12.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (user.role != UserRole.buyer)
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accent),
                        const SizedBox(width: 8),
                        const AppText('تقييمك',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        RatingStars(rating: user.rating, count: user.ratingsCount),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (user.role == UserRole.courier) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText('حالة الاستلام',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        AppText(
                          user.isAvailable
                              ? 'متاح لاستلام الطلبات القريبة'
                              : 'غير متاح حاليًا',
                          style: TextStyle(
                            color: user.isAvailable ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const AppText(
                          'تقدر تغيّر حالتك من لوحة الطلبات في التاب الأول.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (user.role == UserRole.seller) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText('موقع المتجر', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        AppText(
                          user.hasLocation
                              ? '${user.lat!.toStringAsFixed(4)}, ${user.lng!.toStringAsFixed(4)}'
                              : 'لسه محددتش موقع المتجر',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const AppText(
                          'موقع المتجر بيحدد مصاريف الدليفاري ويحدد أقرب طيار لطلباتك.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                BlocBuilder<NotificationsCubit, NotificationsState>(
                  builder: (context, notifications) {
                    final unread = notifications.unreadFor(user.role, user.id);
                    return _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'الإشعارات',
                      subtitle: unread > 0
                          ? '$unread إشعار جديد'
                          : 'تحديثات حالة الطلبات',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.notifications),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'الإعدادات',
                  subtitle: 'المظهر واللغة',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                _MenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'عناويني',
                  subtitle: state.addresses.isEmpty
                      ? 'ضيف عنوان للتوصيل'
                      : '${state.addresses.length} عنوان محفوظ',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.addresses),
                ),
                if (user.role == UserRole.buyer)
                  _MenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'طلباتي',
                    subtitle: 'تابع طلباتك الحالية والسابقة',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.buyerOrders),
                  ),
                if (user.role == UserRole.seller) ...[
                  _MenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'منتجاتي',
                    subtitle: 'إدارة المنتجات والأسعار',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.sellerProducts),
                  ),
                  _MenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'طلبات المتجر',
                    subtitle: 'استلم وجهّز الطلبات',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.sellerOrders),
                  ),
                ],
                if (user.role == UserRole.courier)
                  _MenuTile(
                    icon: Icons.delivery_dining,
                    title: 'توصيلاتي',
                    subtitle: 'الطلبات الحالية والمكتملة وأرباحك',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.courierOrders),
                  ),
                const SizedBox(height: 8),
                if (AppConfig.isDemoMode)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: DemoCredentialsCard(),
                  ),
                AppPrimaryButton(
                  outlined: true,
                  label: 'تسجيل الخروج',
                  icon: Icons.logout,
                  onPressed: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
                ),
                const SizedBox(height: 10),
                Center(
                  child: AppText(
                    '${AppConfig.appName} • إصدار ${AppConfig.appVersion}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            )),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  AppText(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// بيساعد الطبقات العليا تعرض وقت آخر تحديث للبروفايل.
String lastUpdatedLabel(DateTime? value) =>
    value == null ? '' : 'آخر تحديث ${Formatters.timeAgo(value)}';
