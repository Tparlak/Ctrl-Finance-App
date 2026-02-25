import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/account.dart';
import '../models/transaction_model.dart';
import '../widgets/glass_card.dart';

final _currencyFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Text(
                'HESAPLAR',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final account = accounts[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AccountCard(account: account),
                  );
                },
                childCount: accounts.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPositive = account.currentBalance >= 0;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountDetailScreen(account: account),
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isPositive
                    ? AppColors.greenGradient
                    : AppColors.redGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  account.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hesap',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFmt.format(account.currentBalance),
                  style: GoogleFonts.poppins(
                    color: isPositive ? AppColors.green : AppColors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class AccountDetailScreen extends ConsumerWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txNotifier = ref.watch(transactionProvider.notifier);
    final txList = txNotifier.forAccount(account.id);
    final accounts = ref.watch(accountProvider);
    // Refresh when transactions change
    ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(account.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                child: Column(
                  children: [
                    Text(
                      'Güncel Bakiye',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.goldGradient.createShader(b),
                      child: Text(
                        _currencyFmt.format(account.currentBalance),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (txList.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'Bu hesaba ait işlem yok.',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final tx = txList[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _TxTile(tx: tx, accounts: accounts),
                  );
                },
                childCount: txList.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final List accounts;
  const _TxTile({required this.tx, required this.accounts});

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

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTransfer
                  ? Icons.swap_horiz_rounded
                  : isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : tx.type,
                  style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('dd MMM yyyy', 'tr_TR').format(tx.date),
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$prefix${_currencyFmt.format(tx.amount)}',
            style: GoogleFonts.poppins(
                color: color, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
