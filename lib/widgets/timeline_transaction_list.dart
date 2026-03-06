import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../presentation/widgets/receipt_image_viewer.dart';
import '../presentation/widgets/logo_widget.dart';
import '../widgets/bounce_tap.dart';


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
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...items.asMap().entries.map((entry) => _EntranceItem(
                  key: ValueKey(entry.value.id),
                  child: _TimelineItem(
                    transaction: entry.value,
                    categoryMap: categoryMap,
                    accountMap: accountMap,
                    isFirst: entry.key == 0,
                    isLast: entry.key == items.length - 1,
                    onTap: onTap,
                    onDelete: onDelete,
                  ),
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
      key: Key(transaction.id),
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
                          : Theme.of(context).dividerTheme.color,
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
                          : Theme.of(context).dividerTheme.color,
                    ),
                  ),
                ],
              ),
            ),
            // ── Transaction card ─────────────────────────────────
            Expanded(
              child: BounceTap(
                onTap: () => onTap?.call(transaction),
                child: Container(
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      // ── Brand logo or category icon ───────────────────────
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: LogoWidget(
                          description: transaction.description.isNotEmpty
                              ? transaction.description
                              : catName,
                          fallbackIcon: isTransfer
                              ? Icons.swap_horiz_rounded
                              : isExpense
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                          fallbackColor: nodeColor,
                          size: 36,
                          iconSize: 18,
                        ),
                      ),
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              DateFormat('HH:mm', 'tr_TR').format(transaction.date),
                              style: GoogleFonts.poppins(
                                color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withOpacity(0.6),
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
                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
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

class _EntranceItem extends StatefulWidget {
  final Widget child;
  const _EntranceItem({required this.child, super.key});

  @override
  State<_EntranceItem> createState() => _EntranceItemState();
}

class _EntranceItemState extends State<_EntranceItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppColors.kVipDuration * 1.5,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppColors.kVipCurve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SizeTransition(
        sizeFactor: _animation,
        axisAlignment: -1.0,
        child: widget.child,
      ),
    );
  }
}


