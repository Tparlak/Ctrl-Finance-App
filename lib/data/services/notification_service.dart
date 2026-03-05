import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

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

    await requestPermissions();
    await _initTimeZone();
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      // General notification permission (Android 13+)
      await androidPlugin?.requestNotificationsPermission();
      
      // Exact alarm permission (Android 12+)
      // This is critical for reminders to fire at the exact minute
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  static Future<void> _initTimeZone() async {
    if (_tzInitialized) return;
    try {
      tz_data.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _tzInitialized = true;
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
        _tzInitialized = true;
      } catch (__) {}
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
    await _initTimeZone();
    if (!_tzInitialized) return;

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    // If time is in the past, don't schedule
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id, 
      title, 
      body, 
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders', 
          'Hatırlatıcılar',
          channelDescription: 'Kişisel hatırlatıcı bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          fullScreenIntent: true, // Wake up screen if possible
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> testImmediateNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Kanalı',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _plugin.show(
      9999,
      'Test Bildirimi',
      'Bildirim sistemi çalışıyor!',
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel(int id) async => _plugin.cancel(id);
}

