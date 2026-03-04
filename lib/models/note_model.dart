import 'package:hive/hive.dart';
part 'note_model.g.dart';

@HiveType(typeId: 5)
class NoteModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime dateCreated;

  @HiveField(3)
  DateTime dateModified;

  @HiveField(4)
  String color;

  @HiveField(5)
  bool isPinned;

  NoteModel({
    required this.title,
    required this.content,
    required this.dateCreated,
    required this.dateModified,
    this.color = '#1E1E2E',
    this.isPinned = false,
  });
}
