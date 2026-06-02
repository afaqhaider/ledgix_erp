import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationCenterScreen extends StatefulWidget {
  final AppUser user;
  const NotificationCenterScreen({super.key, required this.user});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                _notificationService.markAllAsRead(widget.user.uid),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: _getNotificationIcon(notification.type),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.message),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, hh:mm a',
                      ).format(notification.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                tileColor: notification.isRead
                    ? null
                    : Colors.blue.withValues(alpha: 0.05),
                onTap: () {
                  if (!notification.isRead) {
                    _notificationService.markAsRead(
                      widget.user.uid,
                      notification.id,
                    );
                  }
                  // TODO: Navigate to related document
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
        return const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.fact_check, color: Colors.white),
        );
      case NotificationType.invoice:
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.receipt, color: Colors.white),
        );
      case NotificationType.payment:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.payments, color: Colors.white),
        );
      case NotificationType.system:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.info, color: Colors.white),
        );
    }
  }
}
