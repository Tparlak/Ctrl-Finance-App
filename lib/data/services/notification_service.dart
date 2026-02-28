import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showUpcomingPaymentNotification({
    required int id,
    required String billName,
    required double amount,
    required String currency,
    required int daysUntilDue,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'upcoming_payments',
      'Yaklaşan Ödemeler',
      channelDescription: 'Yaklaşan fatura bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      id,
      '⚠️ Yaklaşan Ödeme',
      '$billName — ${amount.toStringAsFixed(2)} $currency ($daysUntilDue gün kaldı)',
      const NotificationDetails(android: androidDetails),
    );
  }
}
