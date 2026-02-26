import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/hive_boxes.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/dashboard_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/fixed_expenses_screen.dart';
import 'screens/ctrl_center_screen.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so content bleeds under it
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ─── Local Database ────────────────────────────────────────────────────────
  await Hive.initFlutter();
  await HiveBoxes.openAll();

  // ─── Locale (Turkish date/number formatting) ───────────────────────────────
  await initializeDateFormatting('tr_TR', null);

  runApp(
    const ProviderScope(
      child: CtrlApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root App
// ─────────────────────────────────────────────────────────────────────────────

class CtrlApp extends StatelessWidget {
  const CtrlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ctrl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeShell(),
      builder: (context, child) {
        return child!;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell — manages bottom nav + screen switching
// ─────────────────────────────────────────────────────────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  // Use const constructors — IndexedStack keeps all screens alive,
  // so state (scroll position, etc.) is preserved across tab switches.
  static const List<Widget> _screens = [
    DashboardScreen(),
    AccountsScreen(),
    FixedExpensesScreen(),
    CtrlCenterScreen(),
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return; // avoid redundant setState
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        extendBody: true, // content flows behind floating nav bar
        body: Stack(
          children: [
            // ── Ambient glow decorations ──────────────────────────────────
            Positioned(
              top: -120,
              left: -80,
              child: _GlowOrb(
                size: 320,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ),
            Positioned(
              bottom: 60,
              right: -100,
              child: _GlowOrb(
                size: 260,
                color: AppColors.blue.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              top: 300,
              right: -60,
              child: _GlowOrb(
                size: 180,
                color: AppColors.green.withValues(alpha: 0.03),
              ),
            ),

            // ── Main screen content ───────────────────────────────────────
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ],
        ),
        bottomNavigationBar: VipBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient glow orb helper
// ─────────────────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

