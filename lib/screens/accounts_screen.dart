import 'dart:io';
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
import '../widgets/timeline_transaction_list.dart';
import '../utils/transaction_grouper.dart';
import '../widgets/add_transaction_sheet.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';



class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);

    // ── Net Durum hesaplama ──────────────────────────────────────────────────
    double totalAssets = 0;
    double totalDebts = 0;
    for (final a in accounts) {
      if (a.type == 'CREDIT_CARD') {
        totalDebts += a.currentBalance.abs();
      } else {
        totalAssets += a.currentBalance;
      }
    }
    final netWorth = totalAssets - totalDebts;
    final assetRatio =
        (totalAssets + totalDebts) > 0 ? totalAssets / (totalAssets + totalDebts) : 1.0;

    // ── Gruplandırma ─────────────────────────────────────────────────────────
    final cash = accounts.where((a) => a.type == 'CASH').toList();
    final banks = accounts
        .where((a) => a.type == 'BANK' || a.type == 'SAVINGS')
        .toList();
    final cards =
        accounts.where((a) => a.type == 'CREDIT_CARD').toList();

    // Flat sliver items list: type = 'header' | 'account' | 'addBtn'
    final List<Map<String, dynamic>> items = [];

    void addGroup(String label, Color color, List group) {
      if (group.isEmpty) return;
      items.add({'type': 'header', 'label': label, 'color': color});
      for (final a in group) {
        items.add({'type': 'account', 'account': a});
      }
    }

    addGroup('NAKİT', AppColors.green, cash);
    addGroup('BANKA HESAPLARI', AppColors.blue, banks);
    addGroup('KREDİ KARTLARI', AppColors.red, cards);
    items.add({'type': 'addBtn'});

    return Stack(
      children: [
        CustomScrollView(
        slivers: [
          // ── Başlık ─────────────────────────────────────────────────────────
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

          // ── Net Durum Glassmorphism Kartı ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET DURUM',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // ── Mini bar ────────────────────────────────────────
                        SizedBox(
                          width: 12,
                          height: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Background (debt)
                                Container(
                                  color:
                                      AppColors.red.withOpacity( 0.25),
                                ),
                                // Asset portion
                                FractionallySizedBox(
                                  heightFactor: assetRatio.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.greenGradient,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // ── Sayılar ─────────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NetRow(
                                label: 'Varlıklar',
                                amount: totalAssets,
                                color: AppColors.green,
                                icon: Icons.account_balance_rounded,
                              ),
                              const SizedBox(height: 8),
                              _NetRow(
                                label: 'Borçlar',
                                amount: -totalDebts,
                                color: AppColors.red,
                                icon: Icons.credit_card_rounded,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                    color: AppColors.glassBorder, height: 1),
                              ),
                              _NetRow(
                                label: 'Net Durum',
                                amount: netWorth,
                                color: AppColors.gold,
                                icon: Icons.auto_graph_rounded,
                                large: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Gruplu Hesap Listesi ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];

                  if (item['type'] == 'header') {
                    return _GroupHeader(
                      label: item['label'] as String,
                      color: item['color'] as Color,
                    );
                  }

                  if (item['type'] == 'addBtn') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: _AddAccountButton(),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AccountCard(account: item['account'] as Account),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      // Menu Button
      Positioned(
        top: 10,
        left: 10,
        child: SafeArea(
          child: Builder(
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
        ),
      ),
    ],
  );
}
}

// ─── Group Header ──────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Net Row ───────────────────────────────────────────────────────────────

class _NetRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool large;

  const _NetRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmtAbs =
        NumberFormat('#,##0.00', 'tr_TR').format(amount.abs());
    final sign = amount < 0 ? '-' : '';
    return Row(
      children: [
        Icon(icon, color: color, size: large ? 16 : 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: large ? 12 : 11,
            ),
          ),
        ),
        Text(
          '$sign$fmtAbs ₺',
          style: GoogleFonts.poppins(
            color: color,
            fontSize: large ? 14 : 12,
            fontWeight: large ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}



// ─── Add Account Button (Inline) ───────────────────────────────────────────

class _AddAccountButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () => _showAddAccountSheet(context, ref),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppColors.gold.withOpacity( 0.6), width: 1.5),
        backgroundColor: AppColors.gold.withOpacity( 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded, color: AppColors.gold),
          const SizedBox(width: 8),
          Text(
            'HESAP EKLE',
            style: GoogleFonts.poppins(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    String selectedType = 'BANK';
    bool includedInTotal = true;
    String selectedCurrency = '₺';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.gold.withOpacity( 0.3), width: 1),
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
                              color: AppColors.gold.withOpacity( 0.3)),
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
                    const SizedBox(height: 16),
                    // Type selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.glassBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withOpacity( 0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          style: GoogleFonts.poppins(color: AppColors.textPrimary),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gold),
                          items: const [
                            DropdownMenuItem(value: 'BANK', child: Text('Banka Hesabı')),
                            DropdownMenuItem(value: 'CASH', child: Text('Nakit Kasa')),
                            DropdownMenuItem(value: 'CREDIT_CARD', child: Text('Kredi Kartı')),
                            DropdownMenuItem(value: 'SAVINGS', child: Text('Birikim Hesabı (Savings)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Currency picker
                    Text(
                      'Para Birimi',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['₺', '\$', '€', '₿', 'Gram'].map((c) => ChoiceChip(
                        label: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: selectedCurrency == c ? AppColors.gold : AppColors.textPrimary)),
                        selected: selectedCurrency == c,
                        selectedColor: AppColors.gold.withOpacity( 0.15),
                        backgroundColor: AppColors.glassBg,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: selectedCurrency == c ? AppColors.gold : AppColors.glassBorder,
                        ),
                        onSelected: (_) => setSheetState(() => selectedCurrency = c),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Included in Total switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.gold,
                      title: Text(
                        'Ana Bakiyeye Dahil Et',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Bu hesabın bakiyesi genel toplama yansısın mı?',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      value: includedInTotal,
                      onChanged: (val) {
                        setSheetState(() => includedInTotal = val);
                      },
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
                            ref.read(accountProvider.notifier).addAccount(
                                  name: name,
                                  type: selectedType,
                                  isIncludedInTotal: includedInTotal,
                                  currency: selectedCurrency,
                                );
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
          .updateAccountSettings(widget.account.id, name: newName);
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'CASH': return 'Nakit Kasa';
      case 'CREDIT_CARD': return 'Kredi Kartı';
      case 'SAVINGS': return 'Birikim Hesabı';
      default: return 'Banka Hesabı';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = account.currentBalance >= 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AccountDetailScreen(account: account)),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Row(
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
                  account.name.isNotEmpty ? account.name.substring(0, 1).toUpperCase() : 'A',
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
                  Row(
                    children: [
                      Text(
                        _getTypeLabel(account.type),
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (!account.isIncludedInTotal) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.visibility_off_rounded,
                            color: AppColors.textSecondary, size: 12),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${NumberFormat('#,##0.00', 'tr_TR').format(account.currentBalance)} ${account.currency}',
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
        // Menu Button
        Positioned(
          top: 10,
          left: 10,
          child: SafeArea(
            child: Builder(
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
              ),
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
                      color: AppColors.gold.withOpacity( 0.4)),
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
          color: color.withOpacity( 0.15),
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
                        '${NumberFormat('#,##0.00', 'tr_TR').format(account.currentBalance)} ${account.currency}',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TimelineTransactionList(
                  grouped: TransactionGrouper.groupByDate(txList),
                  categoryMap: {for (final c in (ref.watch(categoryProvider) as List<CategoryModel>)) c.id: c},
                  accountMap: {for (final a in (accounts as List<Account>)) a.id: a},
                  onDelete: (tx) => ref.read(transactionProvider.notifier).deleteTransaction(tx.id!),
                  onTap: (tx) {
                    // Show edit sheet
                  },
                ),
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

    final account =
        accounts.where((a) => a.id == tx.fromAccountId).firstOrNull;
    final String currencySymbol = account?.currency ?? '₺';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity( 0.15),
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
            '$prefix ${NumberFormat('#,##0.00', 'tr_TR').format(tx.amount)} $currencySymbol',
            style: GoogleFonts.poppins(
                color: color, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

