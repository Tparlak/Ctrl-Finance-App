import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/note_model.dart';

class NotesNotifier extends Notifier<List<NoteModel>> {
  late Box<NoteModel> _box;

  @override
  List<NoteModel> build() => [];

  Future<void> init() async {
    _box = Hive.box<NoteModel>('notes');
    state = _sorted(_box.values.toList());
  }

  List<NoteModel> _sorted(List<NoteModel> list) {
    return List<NoteModel>.from(list)
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.dateModified.compareTo(a.dateModified);
      });
  }

  Future<void> save(NoteModel note) async {
    note.dateModified = DateTime.now();
    if (note.isInBox) {
      await note.save();
    } else {
      await _box.add(note);
    }
    state = _sorted(_box.values.toList());
  }

  Future<void> delete(NoteModel note) async {
    await note.delete();
    state = _sorted(_box.values.toList());
  }

  Future<void> togglePin(NoteModel note) async {
    note.isPinned = !note.isPinned;
    note.dateModified = DateTime.now();
    await note.save();
    state = _sorted(_box.values.toList());
  }
}

final notesProvider = NotifierProvider<NotesNotifier, List<NoteModel>>(NotesNotifier.new);
