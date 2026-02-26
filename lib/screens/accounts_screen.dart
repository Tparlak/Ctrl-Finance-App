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
      floatingActionButton: _AddAccountFab(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HESAPLAR',
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '${accounts.length} hesap',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
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
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ─── Floating Action Button — Add Account ─────────────────────────────────────

class _AddAccountFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddAccountSheet(context, ref),
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Hesap Ekle',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3), width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Hesap',
                  style: GoogleFonts.poppins(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Hesap adı (örn: Akbank)',
                    hintStyle: GoogleFonts.poppins(
                        color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final name = ctrl.text.trim();
                      if (name.isNotEmpty) {
                        ref.read(accountProvider.notifier).addAccount(name);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      'KAYDET',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Account Card with Swipe-to-Edit ─────────────────────────────────────────

class _AccountCard extends ConsumerStatefulWidget {
  final Account account;
  const _AccountCard({required this.account});

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _isEditing = false;
  bool _isConfirmingDelete = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _enterEditing() => setState(() {
        _isEditing = true;
        _isConfirmingDelete = false;
      });

  void _cancelEditing() => setState(() {
        _isEditing = false;
        _isConfirmingDelete = false;
        _nameCtrl.text = widget.account.name;
      });

  void _saveRename() {
    final newName = _nameCtrl.text.trim();
    if (newName.isNotEmpty) {
      ref
          .read(accountProvider.notifier)
          .renameAccount(widget.account.id, newName);
    }
    setState(() => _isEditing = false);
  }

  void _confirmDelete() => setState(() => _isConfirmingDelete = true);

  void _doDelete() {
    ref.read(accountProvider.notifier).deleteAccount(widget.account.id);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe right-to-left to enter edit mode
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -200 &&
            !_isEditing) {
          _enterEditing();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _isConfirmingDelete
            ? _DeleteConfirmView(
                accountName: widget.account.name,
                onConfirm: _doDelete,
                onCancel: _cancelEditing,
              )
            : _isEditing
                ? _EditModeView(
                    nameCtrl: _nameCtrl,
                    onSave: _saveRename,
                    onDelete: _confirmDelete,
                    onCancel: _cancelEditing,
                  )
                : _NormalView(account: widget.account, onSwipe: _enterEditing),
      ),
    );
  }
}

// ── Normal View ───────────────────────────────────────────────────────────────

class _NormalView extends StatelessWidget {
  final Account account;
  final VoidCallback onSwipe;
  const _NormalView({required this.account, required this.onSwipe});

  @override
  Widget build(BuildContext context) {
    final isPositive = account.currentBalance >= 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AccountDetailScreen(account: account)),
      ),
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
                    'Kaydırmak için sola kaydır',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 11),
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

// ── Edit Mode View ────────────────────────────────────────────────────────────

class _EditModeView extends StatelessWidget {
  final TextEditingController nameCtrl;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  const _EditModeView(
      {required this.nameCtrl,
      required this.onSave,
      required this.onDelete,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: nameCtrl,
              autofocus: true,
              style: GoogleFonts.poppins(
                  color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.gold, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.glassBg,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ActionBtn(
              icon: Icons.check_rounded,
              color: AppColors.green,
              onTap: onSave),
          _ActionBtn(
              icon: Icons.delete_outline_rounded,
              color: AppColors.red,
              onTap: onDelete),
          _ActionBtn(
              icon: Icons.close_rounded,
              color: AppColors.textSecondary,
              onTap: onCancel),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ── Delete Confirm View ───────────────────────────────────────────────────────

class _DeleteConfirmView extends StatelessWidget {
  final String accountName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _DeleteConfirmView(
      {required this.accountName,
      required this.onConfirm,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$accountName silinsin mi?',
              style: GoogleFonts.poppins(
                color: AppColors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ActionBtn(
              icon: Icons.delete_forever_rounded,
              color: AppColors.red,
              onTap: onConfirm),
          _ActionBtn(
              icon: Icons.close_rounded,
              color: AppColors.textSecondary,
              onTap: onCancel),
        ],
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
