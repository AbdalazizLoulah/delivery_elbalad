import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/app_notification.dart';

/// حالة الإشعارات: قائمة + آخر إشعار جديد (عشان نعرضه كـ SnackBar).
class NotificationsState extends Equatable {
  const NotificationsState({this.items = const [], this.lastAdded});

  final List<AppNotification> items;

  /// آخر إشعار اتضاف (بيتعرض مرة واحدة بس).
  final AppNotification? lastAdded;

  int get unreadCount => items.where((item) => !item.isRead).length;

  /// إشعارات حساب معيّن بس (الدور + معرّف المستلم).
  ///
  /// الفلترة بالـ recipientId هي اللي بتمنع إشعارات حساب تاني تظهر على نفس الجهاز.
  List<AppNotification> forUser(UserRole role, String userId) => items
      .where((item) => item.role == role && item.recipientId == userId)
      .toList();

  int unreadFor(UserRole role, String userId) =>
      forUser(role, userId).where((item) => !item.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? items,
    AppNotification? lastAdded,
    bool clearLastAdded = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      lastAdded: clearLastAdded ? null : (lastAdded ?? this.lastAdded),
    );
  }

  @override
  List<Object?> get props => [items, lastAdded?.id];
}

/// بيسجّل إشعارات التطبيق وبيحفظها بين الجلسات.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._preferences) : super(_read(_preferences));

  static const String _storageKey = 'app_notifications';
  static const int _maxItems = 60;

  final SharedPreferences _preferences;

  static NotificationsState _read(SharedPreferences preferences) {
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const NotificationsState();
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      return NotificationsState(items: items);
    } catch (_) {
      return const NotificationsState();
    }
  }

  /// إضافة إشعار جديد (بيتجاهل المكرر بنفس الـ id).
  void push(AppNotification notification) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.id == notification.id);
    if (index >= 0) {
      items[index] = notification;
    } else {
      items.insert(0, notification);
    }
    final trimmed = items.take(_maxItems).toList();
    emit(state.copyWith(items: trimmed, lastAdded: notification));
    _persist(trimmed);
  }

  /// تعليم كل إشعارات حساب معيّن كمقروءة.
  void markAllRead(UserRole role, String userId) {
    final items = state.items
        .map((item) => item.role == role && item.recipientId == userId
            ? item.copyWith(isRead: true)
            : item)
        .toList();
    emit(state.copyWith(items: items));
    _persist(items);
  }

  void clear() {
    emit(state.copyWith(items: const [], clearLastAdded: true));
    _persist(const []);
  }

  /// استهلاك "آخر إشعار" بعد ما يتعرض.
  void consumeLastAdded() {
    if (state.lastAdded == null) return;
    emit(state.copyWith(clearLastAdded: true));
  }

  void _persist(List<AppNotification> items) {
    _preferences.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
