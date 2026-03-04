import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/car_expense.dart';
import '../providers/car_expense_provider.dart';
import '../theme/app_colors.dart';

class CarLedgerScreen extends ConsumerStatefulWidget {
  const CarLedgerScreen({super.key});
  @override
  ConsumerState<CarLedgerScreen> createState() => _CarLedgerScreenState();
}

class _CarLedgerScreenState extends ConsumerState<CarLedgerScreen> {
  String _filter = 'Tümü';
  static const _categories = ['Tümü', 'Bakım', 'Yakıt', 'Sigorta', 'Kasko', 'Diğer'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carExpenseProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(carExpenseProvider);
    final total = ref.read(carExpenseProvider.notifier).totalSpent;
    final filtered = _filter == 'Tümü' ? expenses : expenses.where((e) => e.category == _filter).toList();
    final fmt = NumberFormat('#,##0.00', 'tr_TR');

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
        title: Text('Araç Yönetimi', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Summary card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.glassBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_rounded, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toplam Araç Harcaması', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                          Text('${fmt.format(total)} ₺', style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Category chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = _filter == cat;
                return GestureDetector(
                  onTap: () => setState(() => _filter = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.gold : AppColors.glassBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.gold : AppColors.glassBorder),
                    ),
                    child: Text(cat, style: GoogleFonts.poppins(
                      color: sel ? Colors.black : AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Henüz kayıt yok', style: GoogleFonts.poppins(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      return Dismissible(
                        key: Key(e.key.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity( 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.red),
                        ),
                        onDismissed: (_) => ref.read(carExpenseProvider.notifier).delete(e),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.glassBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity( 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_catIcon(e.category), color: AppColors.gold, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.blue.withOpacity( 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(e.category, style: GoogleFonts.poppins(color: AppColors.blue, fontSize: 10)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(DateFormat('dd MMM yyyy', 'tr_TR').format(e.date),
                                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                                      if (e.kilometers != null) ...[
                                        const SizedBox(width: 8),
                                        Text('${e.kilometers!.toStringAsFixed(0)} km',
                                            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 11)),
                                      ],
                                    ]),
                                  ],
                                ),
                              ),
                              Text('${fmt.format(e.amount)} ₺',
                                  style: GoogleFonts.poppins(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    },
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

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Yakıt': return Icons.local_gas_station;
      case 'Sigorta': return Icons.security;
      case 'Kasko': return Icons.shield;
      case 'Bakım': return Icons.build;
      default: return Icons.more_horiz;
    }
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCarExpenseSheet(),
    );
  }
}

class _AddCarExpenseSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddCarExpenseSheet> createState() => _AddCarExpenseSheetState();
}

class _AddCarExpenseSheetState extends ConsumerState<_AddCarExpenseSheet> {
  final _titleC = TextEditingController();
  final _amountC = TextEditingController();
  final _kmC = TextEditingController();
  final _noteC = TextEditingController();
  String _cat = 'Bakım';
  DateTime _date = DateTime.now();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Araç Gideri Ekle', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          _field(_titleC, 'Başlık *'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(_amountC, 'Tutar (₺)', isNum: true)),
            const SizedBox(width: 10),
            Expanded(child: _field(_kmC, 'Kilometre', isNum: true)),
          ]),
          const SizedBox(height: 10),
          // Category chips
          Wrap(
            spacing: 8,
            children: ['Bakım','Yakıt','Sigorta','Kasko','Diğer'].map((c) => GestureDetector(
              onTap: () => setState(() => _cat = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _cat == c ? AppColors.gold : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cat == c ? AppColors.gold : AppColors.glassBorder),
                ),
                child: Text(c, style: GoogleFonts.poppins(color: _cat == c ? Colors.black : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
          _field(_noteC, 'Notlar (İsteğe bağlı)', maxLines: 2),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleC.text.isEmpty || _amountC.text.isEmpty) return;
                final expense = CarExpense(
                  title: _titleC.text.trim(),
                  amount: double.tryParse(_amountC.text.replaceAll(',', '.')) ?? 0,
                  date: _date,
                  category: _cat,
                  kilometers: double.tryParse(_kmC.text.replaceAll(',', '.')),
                  notes: _noteC.text.isEmpty ? null : _noteC.text.trim(),
                );
                ref.read(carExpenseProvider.notifier).add(expense);
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

  Widget _field(TextEditingController c, String hint, {bool isNum = false, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.glassBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.glassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

