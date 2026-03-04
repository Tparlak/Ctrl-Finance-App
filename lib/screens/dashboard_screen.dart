import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/add_transaction_sheet.dart';
import '../providers/analytics_provider.dart';
import '../providers/fixed_expense_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/monthly_pie_chart.dart';
import '../widgets/upcoming_payment_banner.dart';
import '../utils/transaction_grouper.dart';
import '../widgets/timeline_transaction_list.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(balancesByCurrencyProvider);
    final totalIncome = ref.watch(currentMonthIncomeProvider);
    final totalExpense = ref.watch(currentMonthExpenseProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(categoryProvider);
    final accounts = ref.watch(accountProvider);
    final upcomingCount =
        ref.watch(fixedExpenseProvider.notifier).upcomingExpenseCount;
    final marketState = ref.watch(marketProvider);
    final marketItems = marketState.items;

    final recent = transactions.take(30).toList();
    final grouped = TransactionGrouper.groupByDate(recent);

    final categoryMap = {for (final c in categories) c.id: c};
    final accountMap = {for (final a in accounts) a.id: a};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: const Icon(Icons.menu_rounded, color: AppColors.gold, size: 22),
                                ),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (upcomingCount > 0) ...[
                        UpcomingPaymentBanner(
                          count: upcomingCount,
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        'TOPLAM BAKIYE',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 12,
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
                                balances.isEmpty
                                    ? '0,00 ₺'
                                    : '${NumberFormat('#,##0.00', 'tr_TR').format(balances.values.first)} ${balances.keys.first}',
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
                                children: balances.entries
                                    .map((e) => Text(
                                          '${NumberFormat('#,##0.00', 'tr_TR').format(e.value)} ${e.key}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ))
                                    .toList(),
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
                      if (marketItems.isNotEmpty) ...[
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            itemCount: marketItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final item = marketItems[i];
                              final rateStr = item.code == 'BTC' || item.code == 'ETH'
                                  ? NumberFormat('#,###', 'tr_TR').format(item.rateInTRY)
                                  : item.rateInTRY.toStringAsFixed(item.code == 'XAU' || item.code == 'XAG' ? 2 : 4);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Text(
                                  '${item.code}  $rateStr ₺',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Aylık Dağılım',
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const _MonthFilterSelector(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          final pieData = ref.watch(analyticsProvider);
                          return MonthlyPieChart(data: pieData);
                        },
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: recent.isEmpty
                      ? Column(
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                color: AppColors.textSecondary, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz işlem yok.\nAşağıdaki GELİR veya GİDER butonu ile başlayın.',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : TimelineTransactionList(
                          grouped: grouped,
                          categoryMap: categoryMap,
                          accountMap: accountMap,
                          onDelete: (tx) {
                            ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
                          },
                          onTap: (tx) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => AddTransactionSheet(existingTransaction: tx),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
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
    final currencyFmt = NumberFormat('#,##0.00', 'tr_TR');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.12),
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

class _MonthFilterSelector extends ConsumerWidget {
  const _MonthFilterSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthStr = DateFormat('MMMM yyyy', 'tr_TR').format(selectedMonth);

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month - 1);
          },
        ),
        Text(
          monthStr,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          onPressed: () {
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(selectedMonth.year, selectedMonth.month + 1);
          },
        ),
      ],
    );
  }
}
