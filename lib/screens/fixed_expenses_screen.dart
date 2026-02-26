import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/fixed_expense_provider.dart';
import '../providers/account_provider.dart';
import '../models/fixed_expense.dart';
import '../widgets/glass_card.dart';

final _currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final _dateFmt = DateFormat('dd MMM', 'tr_TR');

class FixedExpensesScreen extends ConsumerWidget {
  const FixedExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(fixedExpenseProvider);
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'tr_TR').format(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SABİT GİDERLER',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (expenses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_outlined,
                        color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Bu ay için sabit gider yok.\n+ butonuna basarak ekleyin.',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FixedExpenseCard(expense: expenses[i]),
                  ),
                  childCount: expenses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: Text('Sabit Gider Ekle',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final installmentCtrl = TextEditingController(text: '2');
    DateTime arrivalDate = DateTime.now();
    DateTime dueDate = DateTime.now().add(const Duration(days: 10));
    bool isRecurring = false;
    String recurringType = 'MONTHLY'; // or 'INSTALLMENT'

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1B22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Sabit Gider Ekle',
              style: GoogleFonts.poppins(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Başlık (Kira, D-Smart…)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Tutar (₺)'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.gold,
                  title: Text('Her Ay Otomatik Ekle',
                      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13)),
                  value: isRecurring,
                  onChanged: (val) => setState(() => isRecurring = val),
                ),
                if (isRecurring) ...[
                  Row(
                    children: [
                      Radio<String>(
                        value: 'MONTHLY',
                        groupValue: recurringType,
                        activeColor: AppColors.gold,
                        onChanged: (val) => setState(() => recurringType = val!),
                      ),
                      Text('Sürekli (Abonelik)', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                      Radio<String>(
                        value: 'INSTALLMENT',
                        groupValue: recurringType,
                        activeColor: AppColors.gold,
                        onChanged: (val) => setState(() => recurringType = val!),
                      ),
                      Text('Taksit', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  if (recurringType == 'INSTALLMENT')
                    TextField(
                      controller: installmentCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Toplam Taksit Sayısı (örn: 6)'),
                    ),
                  const SizedBox(height: 10),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Fatura Geliş: ${_dateFmt.format(arrivalDate)}',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.gold, size: 18),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: arrivalDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (p != null) setState(() => arrivalDate = p);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Son Ödeme: ${_dateFmt.format(dueDate)}',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                  trailing: const Icon(Icons.event_outlined, color: AppColors.red, size: 18),
                  onTap: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (p != null) setState(() => dueDate = p);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                if (titleCtrl.text.isEmpty || amount == null) return;
                
                int totalInst = 1;
                if (isRecurring && recurringType == 'INSTALLMENT') {
                  totalInst = int.tryParse(installmentCtrl.text) ?? 1;
                }

                await ref.read(fixedExpenseProvider.notifier).addExpense(
                      title: titleCtrl.text.trim(),
                      amount: amount,
                      billArrivalDate: arrivalDate,
                      dueDate: dueDate,
                      isRecurring: isRecurring,
                      recurringType: recurringType,
                      totalInstallments: totalInst,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background),
              child: Text('Ekle',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedExpenseCard extends ConsumerWidget {
  final FixedExpense expense;
  const _FixedExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = expense.isPaid;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.green.withValues(alpha: 0.15)
                      : AppColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_outline : Icons.receipt_long_outlined,
                  color: isPaid ? AppColors.green : AppColors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isPaid
                              ? 'Ödendi${expense.paymentDate != null ? ' • ${_dateFmt.format(expense.paymentDate!)}' : ''}'
                              : 'Bekliyor',
                          style: GoogleFonts.poppins(
                            color: isPaid ? AppColors.green : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (expense.isRecurring) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              expense.recurringType == 'INSTALLMENT' 
                                ? 'TAKSİT ${expense.currentInstallment}/${expense.totalInstallments}'
                                : 'TEKRARLANAN',
                              style: GoogleFonts.poppins(
                                color: AppColors.blue,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _currencyFmt.format(expense.amount),
                style: GoogleFonts.poppins(
                  color: isPaid ? AppColors.green : AppColors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fatura: ${_dateFmt.format(expense.billArrivalDate)}',
                  color: AppColors.textSecondary),
              const SizedBox(width: 8),
              _InfoChip(
                  icon: Icons.event_outlined,
                  label: 'Son: ${_dateFmt.format(expense.dueDate)}',
                  color: AppColors.red),
            ],
          ),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showPayDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  '✓ ÖDENDİ OLARAK İŞARETLE',
                  style: GoogleFonts.poppins(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPayDialog(BuildContext context, WidgetRef ref) async {
    final accounts = ref.read(accountProvider);
    String? selectedAccountId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1B22),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hangi Hesaptan Ödendi?',
              style: GoogleFonts.poppins(color: AppColors.textPrimary)),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: accounts.map((a) {
              final sel = selectedAccountId == a.id;
              return GestureDetector(
                onTap: () => setState(() => selectedAccountId = a.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : AppColors.glassBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppColors.gold : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(a.name,
                      style: GoogleFonts.poppins(
                          color:
                              sel ? AppColors.gold : AppColors.textSecondary,
                          fontWeight: sel
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal',
                  style:
                      GoogleFonts.poppins(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedAccountId == null) return;
                await ref
                    .read(fixedExpenseProvider.notifier)
                    .markAsPaid(expense.id, selectedAccountId!);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.black),
              child: Text('Onayla',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.poppins(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
