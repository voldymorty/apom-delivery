import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery/config/api_config.dart';
import 'package:delivery/models/notification_model.dart';
import 'package:delivery/utils/auth_client.dart';

class NotificationRepository {
  Future<NotificationModel> getNotifications({int page = 1, int limit = 20}) async {
    final url = ApiConfig.getNotificationsUrl(page: page, limit: limit);
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
    return notificationModelFromJson(response.body);
  }

  Future<int> getUnreadCount() async {
    final url = ApiConfig.getUnreadCountUrl();
    final response = await AuthClient.getWithAuth(url);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to get unread count: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    return data['data']?['unread_count'] ?? 0;
  }

  Future<void> markAsRead(int id) async {
    final url = ApiConfig.getMarkReadUrl(id);
    final response = await AuthClient.putWithAuth(url, '{}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to mark notification as read: ${response.statusCode}');
    }
  }

  Future<void> markAllAsRead() async {
    final url = ApiConfig.getMarkAllReadUrl();
    final response = await AuthClient.putWithAuth(url, '{}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).getUnreadCount();
});

final notificationsProvider = FutureProvider.family<NotificationModel, int>((ref, page) async {
  return ref.watch(notificationRepositoryProvider).getNotifications(page: page);
});
