import 'package:hive/hive.dart';
part 'reminder_model.g.dart';

@HiveType(typeId: 6)
class ReminderModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime scheduledTime;

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  bool isRepeating;

  @HiveField(4)
  String? repeatInterval;

  @HiveField(5)
  String? note;

  @HiveField(6)
  int notificationId;

  ReminderModel({
    required this.title,
    required this.scheduledTime,
    this.isActive = true,
    this.isRepeating = false,
    this.repeatInterval,
    this.note,
    required this.notificationId,
  });
}
