import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/glass_card.dart';
import '../widgets/add_transaction_sheet.dart';



class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(balancesByCurrencyProvider);
    // Summary cards: ALL-TIME totals
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpense = ref.watch(totalExpenseProvider);
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final accounts = ref.watch(accountProvider);

    final recent = transactions.take(30).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'ANLIK BAKİYE',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.goldGradient.createShader(bounds),
                    child: balances.isEmpty || balances.length == 1
                        ? Text(
                            balances.isEmpty ? '0,00 ₺' : '${NumberFormat('#,##0.00', 'tr_TR').format(balances.values.first)} ${balances.keys.first}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: balances.entries.map((e) => Text(
                              '${NumberFormat('#,##0.00', 'tr_TR').format(e.value)} ${e.key}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            )).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'TOPLAM GELİR',
                          amount: totalIncome,
                          gradient: AppColors.greenGradient,
                          icon: Icons.arrow_downward_rounded,
                          glowColor: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'TOPLAM GİDER',
                          amount: totalExpense,
                          gradient: AppColors.redGradient,
                          icon: Icons.arrow_upward_rounded,
                          glowColor: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Son İşlemler',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${transactions.length} işlem',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (recent.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz işlem yok.\nSağ alttaki + butonundan başlayın.',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) {
                  final tx = recent[idx];
                  return Dismissible(
                    key: Key(tx.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Icon(Icons.edit_outlined, color: AppColors.blue),
                    ),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        // Delete
                        return await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('İşlemi Sil?', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
                            content: Text('Bu işlem kalıcı olarak silinecek.', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('VAZGEÇ', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
                                child: Text('SİL', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Edit
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddTransactionSheet(existingTransaction: tx),
                          );
                        }
                        return false;
                      }
                    },
                    onDismissed: (_) {
                      ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _TransactionTile(
                        tx: tx,
                        accounts: accounts,
                        categories: categories,
                      ),
                    ),
                  );
                },
                childCount: recent.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final LinearGradient gradient;
  final IconData icon;
  final Color glowColor;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.gradient,
    required this.icon,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                  Text(
                    currencyFmt.format(amount),
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final List accounts;
  final List categories;

  const _TransactionTile(
      {required this.tx, required this.accounts, required this.categories});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.type == 'transfer';
    final color = isIncome
        ? AppColors.green
        : isTransfer
            ? AppColors.blue
            : AppColors.red;
    final prefix = isIncome ? '+' : isTransfer ? '⇄' : '-';
    final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull;
    final account =
        accounts.where((a) => a.id == tx.fromAccountId).firstOrNull;
    final String currencySymbol = account?.currency ?? '₺';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: cat != null
                ? Icon(
                    IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: color,
                    size: 20,
                  )
                : Icon(
                    isTransfer
                        ? Icons.swap_horiz_rounded
                        : isIncome
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                    color: color,
                    size: 20,
                  ),
          ),
          if (tx.receiptImagePath != null) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(tx.receiptImagePath!),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty
                      ? tx.description
                      : (cat?.name ?? (isTransfer ? 'Transfer' : 'İşlem')),
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${account?.name ?? ''} • ${DateFormat('dd MMM', 'tr_TR').format(tx.date)}',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$prefix ${NumberFormat('#,##0.00', 'tr_TR').format(tx.amount)} $currencySymbol',
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
