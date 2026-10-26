import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/localization/app_localization.dart';

/// إشعارات النظام (Notification bar) — اختيارية وبتشتغل لو الأذونات متاحة.
class NotificationService {
  NotificationService();

  static const String _channelId = 'order_updates';
  static const String _channelName = 'تحديثات الطلبات';
  static const String _channelDescription = 'إشعارات بتوصل لما حالة الطلب تتغير';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _ready = false;

  bool get isReady => _ready;

  /// تهيئة الإشعارات + طلب الإذن (أندرويد 13+).
  Future<void> init() async {
    if (_ready) return;
    if (kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings: settings);

      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      _ready = true;
    } catch (error) {
      debugPrint('تعذر تجهيز الإشعارات: $error');
      _ready = false;
    }
  }

  /// إلغاء كل الإشعارات المعروضة (بيتنده عند تسجيل الخروج).
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('تعذر إلغاء الإشعارات: $error');
    }
  }

  /// عرض إشعار في شريط الإشعارات.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: tr(title),
        body: tr(body),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    } catch (error) {
      debugPrint('تعذر عرض الإشعار: $error');
    }
  }
}
