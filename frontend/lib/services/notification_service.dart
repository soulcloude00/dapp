import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Types of notifications
enum NotificationType {
  transaction,    // Transaction confirmations
  priceAlert,     // Price change alerts
  newListing,     // New property listings
  dividendPayout, // Dividend payouts
  system,         // System notifications
}

/// Notification model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl,
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'actionUrl': actionUrl,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'],
    type: NotificationType.values.firstWhere((e) => e.name == json['type']),
    title: json['title'],
    message: json['message'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
    actionUrl: json['actionUrl'],
    data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
  );
}

/// Price alert configuration
class PriceAlert {
  final String propertyId;
  final String propertyName;
  final double targetPrice;
  final bool isAbove; // true = alert when above, false = alert when below
  final bool isActive;

  PriceAlert({
    required this.propertyId,
    required this.propertyName,
    required this.targetPrice,
    required this.isAbove,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'propertyName': propertyName,
    'targetPrice': targetPrice,
    'isAbove': isAbove,
    'isActive': isActive,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
    propertyId: json['propertyId'],
    propertyName: json['propertyName'],
    targetPrice: (json['targetPrice'] as num).toDouble(),
    isAbove: json['isAbove'],
    isActive: json['isActive'] ?? true,
  );
}

/// Notification service for managing alerts and notifications
class NotificationService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<PriceAlert> _priceAlerts = [];
  bool _notificationsEnabled = true;
  bool _transactionAlerts = true;
  bool _priceAlertEnabled = true;
  bool _newListingAlerts = true;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  List<PriceAlert> get priceAlerts => _priceAlerts;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get transactionAlerts => _transactionAlerts;
  bool get priceAlertEnabled => _priceAlertEnabled;
  bool get newListingAlerts => _newListingAlerts;

  NotificationService() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load notifications
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    _notifications = notificationsJson.map((json) {
      try {
        return AppNotification.fromJson(jsonDecode(json));
      } catch (e) {
        return null;
      }
    }).whereType<AppNotification>().toList();

    // Load price alerts
    final alertsJson = prefs.getStringList('priceAlerts') ?? [];
    _priceAlerts = alertsJson.map((json) {
      try {
        return PriceAlert.fromJson(jsonDecode(json));
      } catch (e) {
        return null;
      }
    }).whereType<PriceAlert>().toList();

    // Load settings
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _transactionAlerts = prefs.getBool('transactionAlerts') ?? true;
    _priceAlertEnabled = prefs.getBool('priceAlertEnabled') ?? true;
    _newListingAlerts = prefs.getBool('newListingAlerts') ?? true;

    // Sort by timestamp (newest first)
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('notifications', json);
  }

  Future<void> _savePriceAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _priceAlerts.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('priceAlerts', json);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('transactionAlerts', _transactionAlerts);
    await prefs.setBool('priceAlertEnabled', _priceAlertEnabled);
    await prefs.setBool('newListingAlerts', _newListingAlerts);
  }

  /// Add a new notification
  Future<void> addNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    if (!_notificationsEnabled) return;

    // Check if specific notification type is enabled
    switch (type) {
      case NotificationType.transaction:
        if (!_transactionAlerts) return;
        break;
      case NotificationType.priceAlert:
        if (!_priceAlertEnabled) return;
        break;
      case NotificationType.newListing:
        if (!_newListingAlerts) return;
        break;
      default:
        break;
    }

    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      actionUrl: actionUrl,
      data: data,
    );

    _notifications.insert(0, notification);
    
    // Keep only last 100 notifications
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }

    await _saveNotifications();
    notifyListeners();
  }

  /// Add transaction notification
  Future<void> notifyTransaction({
    required String txHash,
    required String propertyName,
    required int fractions,
    required double amount,
    required bool isBuy,
  }) async {
    await addNotification(
      type: NotificationType.transaction,
      title: isBuy ? 'Purchase Successful!' : 'Sale Successful!',
      message: '${isBuy ? 'Bought' : 'Sold'} $fractions fractions of $propertyName for ${amount.toStringAsFixed(0)} ₳',
      data: {
        'txHash': txHash,
        'propertyName': propertyName,
        'fractions': fractions,
        'amount': amount,
      },
    );
  }

  /// Add new listing notification
  Future<void> notifyNewListing({
    required String propertyId,
    required String propertyName,
    required String location,
    required double price,
  }) async {
    await addNotification(
      type: NotificationType.newListing,
      title: 'New Property Listed!',
      message: '$propertyName in $location is now available for ${price.toStringAsFixed(0)} ₳',
      data: {
        'propertyId': propertyId,
        'propertyName': propertyName,
        'location': location,
        'price': price,
      },
    );
  }

  /// Add price alert notification
  Future<void> notifyPriceChange({
    required String propertyId,
    required String propertyName,
    required double oldPrice,
    required double newPrice,
  }) async {
    final isIncrease = newPrice > oldPrice;
    final changePercent = ((newPrice - oldPrice) / oldPrice * 100).abs();
    
    await addNotification(
      type: NotificationType.priceAlert,
      title: '${isIncrease ? '📈' : '📉'} Price ${isIncrease ? 'Increased' : 'Decreased'}',
      message: '$propertyName ${isIncrease ? 'up' : 'down'} ${changePercent.toStringAsFixed(1)}% to ${newPrice.toStringAsFixed(0)} ₳',
      data: {
        'propertyId': propertyId,
        'oldPrice': oldPrice,
        'newPrice': newPrice,
      },
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
    notifyListeners();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  /// Add a price alert
  Future<void> addPriceAlert({
    required String propertyId,
    required String propertyName,
    required double targetPrice,
    required bool isAbove,
  }) async {
    _priceAlerts.add(PriceAlert(
      propertyId: propertyId,
      propertyName: propertyName,
      targetPrice: targetPrice,
      isAbove: isAbove,
    ));
    await _savePriceAlerts();
    notifyListeners();
  }

  /// Remove a price alert
  Future<void> removePriceAlert(String propertyId) async {
    _priceAlerts.removeWhere((a) => a.propertyId == propertyId);
    await _savePriceAlerts();
    notifyListeners();
  }

  /// Update notification settings
  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? transactionAlerts,
    bool? priceAlertEnabled,
    bool? newListingAlerts,
  }) async {
    if (notificationsEnabled != null) _notificationsEnabled = notificationsEnabled;
    if (transactionAlerts != null) _transactionAlerts = transactionAlerts;
    if (priceAlertEnabled != null) _priceAlertEnabled = priceAlertEnabled;
    if (newListingAlerts != null) _newListingAlerts = newListingAlerts;
    await _saveSettings();
    notifyListeners();
  }
}
