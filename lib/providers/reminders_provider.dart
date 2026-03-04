import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/reminder_model.dart';
import '../data/services/notification_service.dart';

class RemindersNotifier extends Notifier<List<ReminderModel>> {
  late Box<ReminderModel> _box;

  @override
  List<ReminderModel> build() => [];

  Future<void> init() async {
    _box = Hive.box<ReminderModel>('reminders');
    state = _box.values.toList();
  }

  int generateUniqueId() => DateTime.now().millisecondsSinceEpoch.remainder(100000);

  List<ReminderModel> get upcoming => state
      .where((r) => r.isActive && r.scheduledTime.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  List<ReminderModel> get past => state
      .where((r) => r.scheduledTime.isBefore(DateTime.now()))
      .toList()
    ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

  Future<void> add(ReminderModel reminder) async {
    await _box.add(reminder);
    if (reminder.isActive) await _schedule(reminder);
    state = _box.values.toList();
  }

  Future<void> toggle(ReminderModel reminder) async {
    reminder.isActive = !reminder.isActive;
    await reminder.save();
    if (reminder.isActive) {
      await _schedule(reminder);
    } else {
      await NotificationService.cancel(reminder.notificationId);
    }
    state = List.from(state);
  }

  Future<void> delete(ReminderModel reminder) async {
    await NotificationService.cancel(reminder.notificationId);
    await reminder.delete();
    state = _box.values.toList();
  }

  Future<void> _schedule(ReminderModel r) async {
    if (r.scheduledTime.isBefore(DateTime.now())) return;
    await NotificationService.scheduleReminderNotification(
      id: r.notificationId,
      title: '⏰ ${r.title}',
      body: r.note ?? 'Hatırlatıcınız zamanı geldi!',
      scheduledTime: r.scheduledTime,
    );
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, List<ReminderModel>>(RemindersNotifier.new);
