import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../providers/reminders_provider.dart';
import '../theme/app_colors.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});
  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(remindersProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(remindersProvider.notifier);
    final upcoming = notifier.upcoming;
    final past = notifier.past;
    // watch for rebuild
    ref.watch(remindersProvider);

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
        title: Text('Hatırlatıcılar', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        children: [
          if (upcoming.isNotEmpty) ...[
            _sectionHeader('YAKLAŞAN', AppColors.green),
            ...upcoming.map((r) => _ReminderTile(r, notifier)),
          ],
          if (past.isNotEmpty) ...[
            _sectionHeader('GEÇMİŞ', AppColors.textSecondary),
            ...past.map((r) => _ReminderTile(r, notifier)),
          ],
          if (upcoming.isEmpty && past.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(children: [
                  Icon(Icons.alarm_outlined, size: 64, color: AppColors.textSecondary.withOpacity( 0.4)),
                  const SizedBox(height: 12),
                  Text('Henüz hatırlatıcı yok', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label, style: GoogleFonts.poppins(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderSheet(),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  final ReminderModel r;
  final RemindersNotifier notifier;
  const _ReminderTile(this.r, this.notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');
    return Dismissible(
      key: Key(r.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity( 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      onDismissed: (_) {
        notifier.delete(r);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hatırlatıcı silindi', style: GoogleFonts.poppins()),
            action: SnackBarAction(label: 'Geri Al', textColor: AppColors.gold, onPressed: () {}),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.alarm_rounded, color: r.isActive ? AppColors.gold : AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(fmt.format(r.scheduledTime), style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                  if (r.note != null)
                    Text(r.note!, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Switch(
              value: r.isActive,
              onChanged: (_) => notifier.toggle(r),
              activeColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleC = TextEditingController();
  final _noteC = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _repeat = 'Yok';

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: kb),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF15161B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Hatırlatıcı Ekle', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleC,
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
            decoration: _inputDeco('Başlık *'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _DateTile(label: DateFormat('dd MMM yyyy', 'tr_TR').format(_date), icon: Icons.calendar_today_outlined, onTap: () async {
              final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365*5)));
              if (p != null) setState(() => _date = p);
            })),
            const SizedBox(width: 10),
            Expanded(child: _DateTile(label: _time.format(context), icon: Icons.access_time_rounded, onTap: () async {
              final p = await showTimePicker(context: context, initialTime: _time,
                builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!));
              if (p != null) setState(() => _time = p);
            })),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _repeat,
            dropdownColor: const Color(0xFF1E1E2E),
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
            decoration: _inputDeco('Tekrar'),
            items: ['Yok','Günlük','Haftalık','Aylık'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _repeat = v!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _noteC,
            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 2,
            decoration: _inputDeco('Not (İsteğe bağlı)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleC.text.isEmpty) return;
                final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
                final notifier = ref.read(remindersProvider.notifier);
                final reminder = ReminderModel(
                  title: _titleC.text.trim(),
                  scheduledTime: scheduled,
                  notificationId: notifier.generateUniqueId(),
                  isRepeating: _repeat != 'Yok',
                  repeatInterval: _repeat != 'Yok' ? _repeat.toLowerCase() : null,
                  note: _noteC.text.isEmpty ? null : _noteC.text.trim(),
                );
                notifier.add(reminder);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Kaydet', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
    filled: true,
    fillColor: AppColors.glassBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class _DateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.gold, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13)),
        ]),
      ),
    );
  }
}

