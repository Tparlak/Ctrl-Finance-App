import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

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

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    if (!_tzInitialized) {
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
        _tzInitialized = true;
      } catch (_) {}
    }
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

  static Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_tzInitialized) return;
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id, title, body, tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders', 'Hatırlatıcılar',
          channelDescription: 'Kişisel hatırlatıcı bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int id) async => _plugin.cancel(id);
}

