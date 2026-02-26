import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'screens/onboarding_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

  try {
    // ─── Local Database ────────────────────────────────────────────────────────
    await Hive.initFlutter();
    await HiveBoxes.openAll();

    // ─── Locale (Turkish date/number formatting) ───────────────────────────────
    await initializeDateFormatting('tr_TR', null);
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Veritabanı Açılış Hatası\n\n$e',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await Hive.deleteFromDisk();
                        SystemNavigator.pop();
                      } catch (_) {
                        SystemNavigator.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Verileri Sıfırla ve Çık', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    FlutterNativeSplash.remove();
    return;
  }

  runApp(
    const ProviderScope(
      child: CtrlApp(),
    ),
  );
  FlutterNativeSplash.remove();
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
      home: const _AppRoot(),
      builder: (context, child) => child!,
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late Future<bool> _onboardingDoneFuture;

  @override
  void initState() {
    super.initState();
    _onboardingDoneFuture = SharedPreferences.getInstance()
        .then((prefs) => prefs.getBool('isOnboardingDone') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingDoneFuture,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(backgroundColor: AppColors.background);
        }
        final done = snap.data ?? false;
        if (!done) {
          return OnboardingScreen(
            onDone: () => setState(() {
              _onboardingDoneFuture = Future.value(true);
            }),
          );
        }
        final String? pin = HiveBoxes.settings.get('appLockPin') as String?;
        return (pin != null && pin.length == 4) ? const AppLockScreen() : const HomeShell();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Lock Screen
// ─────────────────────────────────────────────────────────────────────────────

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _input = "";

  void _onDigit(String digit) {
    if (_input.length < 4) {
      setState(() => _input += digit);
      if (_input.length == 4) {
        final String? truePin = HiveBoxes.settings.get('appLockPin') as String?;
        if (_input == truePin) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
        } else {
          // wrong pin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hatalı PIN!'), backgroundColor: AppColors.red),
          );
          setState(() => _input = "");
        }
      }
    }
  }

  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock_person_rounded, size: 60, color: AppColors.gold.withValues(alpha: 0.8)),
            const SizedBox(height: 20),
            Text('CTRL SECURITY', style: GoogleFonts.poppins(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 4)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _input.length ? AppColors.gold : Colors.transparent,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
              )),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox();
                  if (index == 11) {
                    return InkWell(
                      onTap: _onDelete,
                      borderRadius: BorderRadius.circular(40),
                      child: const Center(child: Icon(Icons.backspace_outlined, color: AppColors.textPrimary)),
                    );
                  }
                  final digit = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onDigit(digit),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassBg,
                      ),
                      child: Center(
                        child: Text(digit, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
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

