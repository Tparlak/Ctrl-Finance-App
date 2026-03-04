import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../theme/app_colors.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notlarım', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: notes.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sticky_note_2_outlined, size: 64, color: AppColors.textSecondary.withOpacity( 0.5)),
                const SizedBox(height: 12),
                Text('Henüz not yok', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ))
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildGrid(context, notes),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _openEditor(context, null),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<NoteModel> notes) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = (constraints.maxWidth - 12) / 2;
        return SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: notes.map((note) => SizedBox(
              width: w,
              child: _NoteCard(
                note: note,
                onTap: () => _openEditor(context, note),
                onPin: () => ref.read(notesProvider.notifier).togglePin(note),
                onDelete: () => ref.read(notesProvider.notifier).delete(note),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  void _openEditor(BuildContext context, NoteModel? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _NoteEditor(note: existing)),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteCard({required this.note, required this.onTap, required this.onPin, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(int.parse(note.color.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity( 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty)
              Text(
                note.title,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.content,
                style: GoogleFonts.poppins(color: Colors.white.withOpacity( 0.75), fontSize: 12),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM', 'tr_TR').format(note.dateModified),
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity( 0.5), fontSize: 10),
                ),
                if (note.isPinned)
                  Icon(Icons.push_pin_rounded, size: 14, color: Colors.white.withOpacity( 0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: AppColors.gold),
              title: Text(note.isPinned ? 'Sabiti Kaldır' : 'Sabitle',
                  style: GoogleFonts.poppins(color: AppColors.textPrimary)),
              onTap: () { Navigator.pop(context); onPin(); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
              title: Text('Sil', style: GoogleFonts.poppins(color: AppColors.red)),
              onTap: () { Navigator.pop(context); onDelete(); },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditor extends ConsumerStatefulWidget {
  final NoteModel? note;
  const _NoteEditor({this.note});
  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _titleC;
  late final TextEditingController _contentC;
  late String _color;
  late NoteModel _working;

  static const _palette = ['#1E1E2E','#1A1A2E','#16213E','#0F3460','#1B1B2F','#2C2C54'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _working = widget.note ?? NoteModel(title: '', content: '', dateCreated: now, dateModified: now);
    _titleC = TextEditingController(text: _working.title);
    _contentC = TextEditingController(text: _working.content);
    _color = _working.color;
  }

  @override
  void dispose() {
    _titleC.dispose();
    _contentC.dispose();
    super.dispose();
  }

  void _save() {
    _working.title = _titleC.text.trim();
    _working.content = _contentC.text;
    _working.color = _color;
    ref.read(notesProvider.notifier).save(_working);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) => _save(),
      child: Scaffold(
        backgroundColor: Color(int.parse(_color.replaceFirst('#', '0xFF'))),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () { _save(); Navigator.pop(context); },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette_outlined, color: Colors.white),
              onPressed: () => _showColorPicker(context),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () { _save(); Navigator.pop(context); },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              TextField(
                controller: _titleC,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: 'Başlık',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _contentC,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity( 0.85), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Not al...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _palette.map((c) => GestureDetector(
            onTap: () { setState(() => _color = c); Navigator.pop(context); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
                border: Border.all(color: _color == c ? Colors.white : Colors.transparent, width: 2),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

