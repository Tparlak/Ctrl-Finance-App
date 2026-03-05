import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/permission_service.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  final _nameCtrl = TextEditingController();

  // Avatar pulse animation for slide 4
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  final _slides = const [
    _OnboardSlide(
      image: 'assets/onboarding_1.png',
      title: 'Akıllı Taksit Motoru',
      subtitle: 'Kredi kartı taksitlerini aylara bölerek her ödemeyi otomatik takip et.',
      accent: Color(0xFFE5A93C),
    ),
    _OnboardSlide(
      image: 'assets/onboarding_2.png',
      title: 'VIP Güvenlik',
      subtitle: '4 haneli PIN kilidi ile uygulamana yalnızca sen eriş.',
      accent: Color(0xFF00B4FF),
    ),
    _OnboardSlide(
      image: 'assets/onboarding_3.png',
      title: 'Hesap Yönetimi',
      subtitle: 'Tüm banka hesaplarını, kredi kartlarını ve tasarruflarını tek ekranda gör.',
      accent: Color(0xFF00E676),
    ),
    _OnboardSlide(
      image: 'assets/onboarding_4.png',
      title: 'Tanışalım!',
      subtitle: 'Size nasıl hitap etmemizi istersiniz?',
      accent: AppColors.gold,
      isNameInput: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // If on last slide and name is empty, warn
    if (_page == _slides.length - 1 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen isminizi giriniz.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    await prefs.setBool('isOnboardingDone', true);
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      await prefs.setString('userName', name);
    }
    try {
      await PermissionService.requestInitialPermissions();
    } catch (_) {}
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final slide = _slides[i];
              if (slide.isNameInput) {
                return _NameSlideWidget(
                  slide: slide,
                  nameCtrl: _nameCtrl,
                  pulseAnimation: _pulse,
                );
              }
              return _SlideWidget(slide: slide);
            },
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor],
                ),
              ),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      final accent = _slides[_page].accent;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? accent
                              : (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
                                  .withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_page < _slides.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_page].accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _page < _slides.length - 1 ? 'İLERLE' : 'BAŞLA',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_page < _slides.length - 1)
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'Atla',
                        style: GoogleFonts.poppins(
                            color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _OnboardSlide {
  final String image;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isNameInput;
  const _OnboardSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.isNameInput = false,
  });
}

// ── Regular slide widget (slides 1-3) ─────────────────────────────────────────

class _SlideWidget extends StatelessWidget {
  final _OnboardSlide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final imgHeight = screenH * 0.42;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: imgHeight,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: slide.accent.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accent.withOpacity(0.20),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      slide.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: imgHeight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: imgHeight * 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              slide.title,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              slide.subtitle,
              style: GoogleFonts.poppins(
                color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withOpacity(0.55),
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

// ── Slide 4 — Name Input (matches card style of other slides) ─────────────────

class _NameSlideWidget extends StatelessWidget {
  final _OnboardSlide slide;
  final TextEditingController nameCtrl;
  final Animation<double> pulseAnimation;

  const _NameSlideWidget({
    required this.slide,
    required this.nameCtrl,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final cardHeight = screenH * 0.42;
    final accent = slide.accent;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),

          // ── Title ──────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              slide.title,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              slide.subtitle,
              style: GoogleFonts.poppins(
                color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
                    .withOpacity(0.55),
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Name TextField ─────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: nameCtrl,
              autofocus: false,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Adınızı girin…',
                hintStyle: GoogleFonts.poppins(
                  color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
                      .withOpacity(0.4),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: accent.withOpacity(0.06),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accent.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
                prefixIcon: Icon(Icons.person_outline_rounded, color: accent.withOpacity(0.7)),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Image box (Matches other slides) ────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: accent.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.20),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      slide.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: cardHeight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: cardHeight * 0.35,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dynamic keyboard padding
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
        ],
      ),
    );

  }
}
