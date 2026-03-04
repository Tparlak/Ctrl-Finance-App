import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../utils/transaction_grouper.dart';
import '../presentation/widgets/receipt_image_viewer.dart';


// ─── Timeline List Widget ─────────────────────────────────────────────────────

class TimelineTransactionList extends StatelessWidget {
  final Map<String, List<TransactionModel>> grouped;
  final Map<String, dynamic> categoryMap; // id → CategoryModel
  final Map<String, dynamic> accountMap;  // id → Account
  final void Function(TransactionModel)? onTap;
  final void Function(TransactionModel)? onDelete;

  const TimelineTransactionList({
    required this.grouped,
    required this.categoryMap,
    required this.accountMap,
    this.onTap,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateKeys = grouped.keys.toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dateKeys.length,
      itemBuilder: (ctx, i) {
        final key = dateKeys[i];
        final items = grouped[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 16, 16, 8),
              child: Text(
                key,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...items.asMap().entries.map((entry) => _TimelineItem(
                  transaction: entry.value,
                  categoryMap: categoryMap,
                  accountMap: accountMap,
                  isFirst: entry.key == 0,
                  isLast: entry.key == items.length - 1,
                  onTap: onTap,
                  onDelete: onDelete,
                )),
          ],
        );
      },
    );
  }
}

// ─── Single Timeline Item ─────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final TransactionModel transaction;
  final Map<String, dynamic> categoryMap;
  final Map<String, dynamic> accountMap;
  final bool isFirst;
  final bool isLast;
  final void Function(TransactionModel)? onTap;
  final void Function(TransactionModel)? onDelete;

  const _TimelineItem({
    required this.transaction,
    required this.categoryMap,
    required this.accountMap,
    required this.isFirst,
    required this.isLast,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';
    final Color nodeColor = isTransfer
        ? AppColors.blue
        : isExpense
            ? AppColors.red
            : AppColors.green;

    final cat = categoryMap[transaction.categoryId];
    final account = accountMap[transaction.fromAccountId];
    final catName = cat?.name ?? '';
    final accountName = account?.name ?? '';

    return Dismissible(
      key: Key(transaction.id ?? transaction.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.red.withOpacity( 0.15),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
      ),
      onDismissed: (_) => onDelete?.call(transaction),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Timeline column ──────────────────────────────────
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: isFirst
                          ? Colors.transparent
                          : AppColors.glassBorder,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: nodeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: nodeColor.withOpacity( 0.5),
                            blurRadius: 6)
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : AppColors.glassBorder,
                    ),
                  ),
                ],
              ),
            ),
            // ── Transaction card ─────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => onTap?.call(transaction),
                child: Container(
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.glassBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description.isNotEmpty
                                  ? transaction.description
                                  : catName.isNotEmpty
                                      ? catName
                                      : (isTransfer ? 'Transfer' : '—'),
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (accountName.isNotEmpty || catName.isNotEmpty)
                              Text(
                                [accountName, catName]
                                    .where((s) => s.isNotEmpty)
                                    .join(' · '),
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              DateFormat('HH:mm', 'tr_TR').format(transaction.date),
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary.withOpacity( 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (transaction.receiptImagePath != null)
                        GestureDetector(
                          onTap: () => ReceiptImageViewer.show(context, transaction.receiptImagePath!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.glassBorder),
                              image: DecorationImage(
                                image: FileImage(File(transaction.receiptImagePath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        '${isExpense ? '-' : isTransfer ? '⇄' : '+'}'
                        ' ${transaction.amount.toStringAsFixed(2)} '
                        '${accountMap[transaction.fromAccountId]?.currency ?? '₺'}',
                        style: GoogleFonts.poppins(
                          color: nodeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

