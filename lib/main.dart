import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'data/hive_boxes.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'screens/dashboard_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/fixed_expenses_screen.dart';
import 'screens/ctrl_center_screen.dart';
import 'screens/car_ledger_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/markets_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/app_drawer.dart';
import 'widgets/add_transaction_sheet.dart';
import 'widgets/bounce_tap.dart';
import 'screens/onboarding_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/fixed_expense_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/logo_settings_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/notification_service.dart';
import 'data/services/home_widget_service.dart';
import 'data/services/permission_service.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  try {
    await Hive.initFlutter();
    await HiveBoxes.openAll();
    await initializeDateFormatting('tr_TR', null);
    if (!kIsWeb) {
      await NotificationService.init();
    }
    if (!kIsWeb) {
      await HomeWidgetService.init();
      await HomeWidgetService.syncWidgetData();
    }
    // NOTE: Permissions are requested AFTER onboarding completes (see OnboardingScreen._finish)

    // Init logo settings (loads saved API key from SharedPreferences)
    final logoContainer = ProviderContainer();
    await logoContainer.read(logoSettingsProvider.notifier).init();
    logoContainer.dispose();
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

class CtrlApp extends ConsumerWidget {
  const CtrlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final accent = themeState.variant.accent;

    return MaterialApp(
      title: 'Ctrl',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: AppTheme.lightTheme(accent),
      darkTheme: AppTheme.darkTheme(accent),
      home: const _AppRoot(),
      routes: {
        '/car-ledger':  (_) => const CarLedgerScreen(),
        '/notes':       (_) => const NotesScreen(),
        '/reminders':   (_) => const RemindersScreen(),
        '/markets':     (_) => const MarketsScreen(),
      },
      builder: (context, child) => child!,
    );
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();
  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  late Future<bool> _onboardingDoneFuture;

  @override
  void initState() {
    super.initState();
    _onboardingDoneFuture = SharedPreferences.getInstance()
        .then((prefs) => prefs.getBool('hasSeenOnboarding') ?? prefs.getBool('isOnboardingDone') ?? false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fixedExpenseProvider.notifier).checkUpcomingPayments();
    });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock_person_rounded, size: 60, color: AppColors.gold.withOpacity( 0.8)),
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
                      child: Center(child: Icon(Icons.backspace_outlined, color: Theme.of(context).colorScheme.onSurface)),
                    );
                  }
                  final digit = index == 10 ? '0' : '${index + 1}';
                  return BounceTap(
                    onTap: () => _onDigit(digit),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                      ),
                      child: Center(
                        child: Text(digit, style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w600)),
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

// ─── Home Shell ────────────────────────────────────────────────────────────────

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  // int _currentIndex = 0; // Removed local state

  static const List<Widget> _screens = [
    DashboardScreen(),
    AccountsScreen(),
    FixedExpensesScreen(),
    CtrlCenterScreen(),
  ];

  void _onNavTap(int index) {
    ref.read(navigationProvider.notifier).setIndex(index);
  }

  void _openAdd(int tabIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionSheet(initialTab: tabIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: _GlowOrb(
                size: 320, 
                color: (isDark ? AppColors.gold : Colors.blueAccent).withOpacity(0.06)
              ),
            ),
            Positioned(
              bottom: 60,
              right: -100,
              child: _GlowOrb(
                size: 260, 
                color: (isDark ? AppColors.blue : Colors.purpleAccent).withOpacity(0.04)
              ),
            ),
            Positioned(
              top: 300,
              right: -60,
              child: _GlowOrb(
                size: 180, 
                color: (isDark ? AppColors.green : Colors.orangeAccent).withOpacity(0.03)
              ),
            ),
            IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
          ],
        ),

        bottomNavigationBar: VipBottomNavBar(
          currentIndex: currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

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



