import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../data/notification_service.dart';
import '../../data/order_status_watcher.dart';
import '../bloc/notifications_cubit.dart';

/// بيشغّل مراقبة حالة الطلبات حسب المستخدم الحالي، ويعرض إشعار فوري
/// (SnackBar) لما يوصل إشعار جديد موجه للمستخدم الحالي.
class OrderNotificationWatcher extends StatefulWidget {
  const OrderNotificationWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<OrderNotificationWatcher> createState() => _OrderNotificationWatcherState();
}

class _OrderNotificationWatcherState extends State<OrderNotificationWatcher> {
  OrderStatusWatcher? _watcher;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    _watcher = OrderStatusWatcher(
      buyerOrders: di<OrderRepository>(),
      sellerOrders: di<SellerOrderRepository>(),
      courierOrders: di<CourierOrderRepository>(),
      notifications: di<NotificationsCubit>(),
      service: di<NotificationService>(),
    );
    _startForCurrentUser();
  }

  @override
  void dispose() {
    _watcher?.stop();
    super.dispose();
  }

  void _startForCurrentUser() {
    final user = context.read<AuthBloc>().state.user;
    _activeUserId = user?.id;
    if (user == null) {
      _watcher?.stop();
      return;
    }
    _watcher?.start(user);
  }

  /// عند الخروج أو تبديل الحساب: بنوقف المراقبة ونمسح إشعارات النظام
  /// القديمة علشان ما تظهرش لحساب تاني على نفس الجهاز.
  void _handleAccountChange() {
    _watcher?.stop();
    di<NotificationService>().cancelAll();
    context.read<NotificationsCubit>().consumeLastAdded();
    _startForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user?.id != current.user?.id ||
          previous.user?.isAvailable != current.user?.isAvailable ||
          previous.user?.lat != current.user?.lat ||
          previous.user?.lng != current.user?.lng,
      listener: (context, state) {
        final current = state.user;
        final currentId = current?.id;
        final accountChanged = _activeUserId != null && _activeUserId != currentId;
        if (current == null || accountChanged) {
          _handleAccountChange();
        } else if (_activeUserId == currentId) {
          // نفس الحساب: بنحدّث الاتاحة/الموقع بس من غير ما نعيد الاشتراكات.
          _watcher?.updateUser(current);
        } else {
          _startForCurrentUser();
        }
      },
      child: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: (previous, current) =>
            current.lastAdded != null && previous.lastAdded != current.lastAdded,
        listener: (context, state) {
          final notification = state.lastAdded;
          if (notification == null) return;
          final user = context.read<AuthBloc>().state.user;
          final isOwner = user != null &&
              notification.role == user.role &&
              notification.recipientId == user.id;
          if (isOwner) {
            showAppSnackBar(
              context,
              '${notification.title} — ${notification.body}',
              isSuccess: true,
            );
          }
          context.read<NotificationsCubit>().consumeLastAdded();
        },
        child: widget.child,
      ),
    );
  }
}
