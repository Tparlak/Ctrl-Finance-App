import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_transaction_sheet.dart';

class VipBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const VipBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final accent = themeState.variant.accent;
    final accentGradient = themeState.variant.gradient;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xCC0B0C10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Ana Sayfa',
                  selected: currentIndex == 0,
                  accent: accent,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Hesaplar',
                  selected: currentIndex == 1,
                  accent: accent,
                  onTap: () => onTap(1),
                ),
                // Action Buttons
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      // INCOME Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => showAddTransactionSheet(context, initialTab: 0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF43E97B),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF43E97B).withOpacity( 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.add_rounded, color: Colors.black, size: 24),
                            ),
                          ),
                        ),
                      ),
                      // EXPENSE Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => showAddTransactionSheet(context, initialTab: 1),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6584),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6584).withOpacity( 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.remove_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Giderler',
                  selected: currentIndex == 2,
                  accent: accent,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.hub_rounded,
                  label: 'Ctrl',
                  selected: currentIndex == 3,
                  accent: accent,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 9.5,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


