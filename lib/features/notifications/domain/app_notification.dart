import 'package:equatable/equatable.dart';

import '../../auth/domain/entities/app_user.dart';

/// إشعار داخل التطبيق (عن حالة طلب أو حدث مهم).
///
/// النص بيتخزّن بالعربي زي ما هو في الكود، والترجمة بتحصل وقت العرض
/// عشان الإشعارات القديمة تفضل باللغة اللي المستخدم مختارها.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.role,
    required this.title,
    required this.body,
    required this.createdAt,
    this.orderId,
    this.recipientId,
    this.isRead = false,
  });

  /// معرّف فريد (بمنع التكرار).
  final String id;

  /// الدور اللي الإشعار موجه ليه (مشتري / بائع / طيار).
  final UserRole role;

  final String title;
  final String body;
  final DateTime createdAt;

  /// الطلب المرتبط بالإشعار (لو موجود).
  final String? orderId;

  /// المستخدم المستلم (لو معروف).
  final String? recipientId;

  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        role: role,
        title: title,
        body: body,
        createdAt: createdAt,
        orderId: orderId,
        recipientId: recipientId,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'orderId': orderId,
        'recipientId': recipientId,
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      role: UserRole.fromApi(json['role'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      orderId: json['orderId'] as String?,
      recipientId: json['recipientId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, role, title, body, createdAt, orderId, recipientId, isRead];
}
