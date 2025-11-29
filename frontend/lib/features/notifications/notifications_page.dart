import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:propfi/theme/app_theme.dart';
import 'package:propfi/services/notification_service.dart';

/// Notifications page showing all user notifications
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final notifications = notificationService.notifications;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (notifications.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'read_all') {
                      notificationService.markAllAsRead();
                    } else if (value == 'clear_all') {
                      _showClearConfirmation(context, notificationService);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'read_all',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 20),
                          SizedBox(width: 12),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Clear all',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () =>
                    _showSettingsDialog(context, notificationService),
              ),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(
                      context,
                      notification,
                      notificationService,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    NotificationService service,
  ) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) {
        service.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Would need to implement undo functionality
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            service.markAsRead(notification.id);
          }
          // Handle notification tap - navigate to relevant page
          _handleNotificationTap(context, notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: notification.isRead
                ? null
                : Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Icons.receipt_long;
      case NotificationType.priceAlert:
        return Icons.trending_up;
      case NotificationType.newListing:
        return Icons.home_work;
      case NotificationType.dividendPayout:
        return Icons.payments;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.transaction:
        return Colors.green;
      case NotificationType.priceAlert:
        return Colors.orange;
      case NotificationType.newListing:
        return AppTheme.primaryColor;
      case NotificationType.dividendPayout:
        return Colors.purple;
      case NotificationType.system:
        return Colors.blue;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.transaction:
        // Could navigate to transaction details
        break;
      case NotificationType.newListing:
        // Could navigate to the property listing
        break;
      case NotificationType.priceAlert:
        // Could navigate to the property
        break;
      default:
        break;
    }
  }

  void _showClearConfirmation(
    BuildContext context,
    NotificationService service,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Clear All Notifications',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear all notifications? This cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, NotificationService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSettingSwitch(
                'All Notifications',
                'Enable or disable all notifications',
                service.notificationsEnabled,
                (value) {
                  service.updateSettings(notificationsEnabled: value);
                  setState(() {});
                },
              ),
              const Divider(color: Colors.grey),
              _buildSettingSwitch(
                'Transaction Alerts',
                'Get notified when transactions complete',
                service.transactionAlerts,
                service.notificationsEnabled
                    ? (value) {
                        service.updateSettings(transactionAlerts: value);
                        setState(() {});
                      }
                    : null,
              ),
              _buildSettingSwitch(
                'Price Alerts',
                'Get notified about price changes',
                service.priceAlertEnabled,
                service.notificationsEnabled
                    ? (value) {
                        service.updateSettings(priceAlertEnabled: value);
                        setState(() {});
                      }
                    : null,
              ),
              _buildSettingSwitch(
                'New Listings',
                'Get notified about new properties',
                service.newListingAlerts,
                service.notificationsEnabled
                    ? (value) {
                        service.updateSettings(newListingAlerts: value);
                        setState(() {});
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: onChanged != null ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? AppTheme.primaryColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification bell widget with badge for app bar
class NotificationBell extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBell({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, child) {
        final unreadCount = service.unreadCount;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: onTap,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
