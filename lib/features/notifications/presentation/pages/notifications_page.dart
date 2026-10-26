import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/app_notification.dart';
import '../bloc/notifications_cubit.dart';
import '../../../../core/utils/responsive.dart';

/// مركز الإشعارات: إشعارات الحساب الحالي بس.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(
        body: ErrorView(message: 'لازم تسجل دخول الأول.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppText('الإشعارات'),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state.unreadFor(user.role, user.id) == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => context
                    .read<NotificationsCubit>()
                    .markAllRead(user.role, user.id),
                child: const AppText('تعليم الكل كمقروء'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final items = state.forUser(user.role, user.id);
          if (items.isEmpty) {
            return const EmptyView(
              title: 'مفيش إشعارات',
              subtitle: 'هنوصلك هنا أي تحديث على حالة طلباتك',
              icon: Icons.notifications_none_rounded,
            );
          }

          return Responsive.centerContent(ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _NotificationTile(
                notification: item,
                onTap: () {
                  context
                      .read<NotificationsCubit>()
                      .markAllRead(user.role, user.id);
                  final orderId = item.orderId;
                  if (orderId == null || orderId.isEmpty) return;
                  Navigator.of(context).pushNamed(
                    AppRoutes.orderDetails,
                    arguments: OrderDetailsArgs(orderId: orderId),
                  );
                },
              );
            },
          ));
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFor(notification.role),
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: unread ? null : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppText(
                      Formatters.timeAgo(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AppText(
                  notification.body,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: unread ? null : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsetsDirectional.only(start: 8, top: 6),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(UserRole role) => switch (role) {
        UserRole.buyer => Icons.shopping_bag_outlined,
        UserRole.seller => Icons.storefront_outlined,
        UserRole.courier => Icons.delivery_dining_outlined,
      };
}
