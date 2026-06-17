import 'dart:convert';

NotificationModel notificationModelFromJson(String str) =>
    NotificationModel.fromJson(json.decode(str) as Map<String, dynamic>);

String notificationModelToJson(NotificationModel data) => json.encode(data.toJson());

class NotificationModel {
  final bool success;
  final NotificationData data;

  NotificationModel({required this.success, required this.data});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      success: json["success"] == true,
      data: NotificationData.fromJson((json["data"] ?? const {}) as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data.toJson(),
      };
}

class NotificationData {
  final List<NotificationItem> notifications;
  final NotificationPagination? pagination;

  NotificationData({required this.notifications, required this.pagination});

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    final rawList = json["notifications"] as List<dynamic>? ?? [];
    final paginationValue = json["pagination"];

    return NotificationData(
      notifications: rawList
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(),
      pagination: paginationValue is Map<String, dynamic>
          ? NotificationPagination.fromJson(paginationValue)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "notifications": notifications.map((x) => x.toJson()).toList(),
        "pagination": pagination?.toJson(),
      };
}

class NotificationItem {
  final int notificationId;
  final String type;
  final String title;
  final String message;
  final String? referenceType;
  final int? referenceId;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final String priority;
  final DateTime createdAt;

  NotificationItem({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceType,
    this.referenceId,
    this.actionUrl,
    required this.isRead,
    this.readAt,
    required this.priority,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: _asInt(json["notification_id"]),
      type: _asString(json["type"]),
      title: _asString(json["title"]),
      message: _asString(json["message"]),
      referenceType: _asNullableString(json["reference_type"]),
      referenceId: _asNullableInt(json["reference_id"]),
      actionUrl: _asNullableString(json["action_url"]),
      isRead: json["is_read"] == true,
      readAt: json["read_at"] != null ? DateTime.tryParse(json["read_at"].toString()) : null,
      priority: _asString(json["priority"] ?? "medium"),
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        "notification_id": notificationId,
        "type": type,
        "title": title,
        "message": message,
        "reference_type": referenceType,
        "reference_id": referenceId,
        "action_url": actionUrl,
        "is_read": isRead,
        "read_at": readAt?.toIso8601String(),
        "priority": priority,
        "created_at": createdAt.toIso8601String(),
      };

  NotificationItem copyWith({
    int? notificationId,
    String? type,
    String? title,
    String? message,
    String? referenceType,
    int? referenceId,
    String? actionUrl,
    bool? isRead,
    DateTime? readAt,
    String? priority,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      notificationId: notificationId ?? this.notificationId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  NotificationPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) => NotificationPagination(
        total: _asInt(json["total"]),
        page: _asInt(json["page"]),
        limit: _asInt(json["limit"]),
        totalPages: _asInt(json["total_pages"]),
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "page": page,
        "limit": limit,
        "total_pages": totalPages,
      };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String _asString(dynamic value) => (value ?? '').toString();

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
