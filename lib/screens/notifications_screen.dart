import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

class NotificationProvider with ChangeNotifier {
  final List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  void addNotification(String title, String message) {
    _notifications.insert(
      0,
      NotificationItem(
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
