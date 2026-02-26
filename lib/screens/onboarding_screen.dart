import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

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
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingDone', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
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
                  colors: [Colors.transparent, AppColors.background],
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
                          color: active ? accent : AppColors.textSecondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Button
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _page < _slides.length - 1 ? 'İLERLE' : 'BAŞLA',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_page < _slides.length - 1)
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'Atla',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
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

class _OnboardSlide {
  final String image;
  final String title;
  final String subtitle;
  final Color accent;
  const _OnboardSlide({required this.image, required this.title, required this.subtitle, required this.accent});
}

class _SlideWidget extends StatelessWidget {
  final _OnboardSlide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 200),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Image in dark glass card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: slide.accent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accent.withValues(alpha: 0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      slide.image,
                      fit: BoxFit.contain,
                      color: Colors.transparent,
                      colorBlendMode: BlendMode.dstIn,
                    ),
                  ),
                ),
                // Bottom gradient fade into black
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
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
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
