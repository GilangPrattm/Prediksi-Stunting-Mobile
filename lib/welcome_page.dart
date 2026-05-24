import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ===========================
  // PREMIUM BLUE PALETTE
  // ===========================

  final Color kPrimary = const Color(0xFF3B82F6);
  final Color kPrimaryLight = const Color(0xFF60A5FA);
  final Color kPrimaryDark = const Color(0xFF1E3A8A);
  final Color kBackground = const Color(0xFFF4F8FF);
  final Color kCardBg = const Color(0xFFFFFFFF);
  final Color kTextLight = const Color(0xFF64748B);

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Selamat Datang\ndi Stunt-Check",
      "text":
          "Pantau tumbuh kembang si kecil dengan mudah dan praktis di genggaman Anda.",
      "icon": "Icons.child_care",
    },
    {
      "title": "Prediksi Cerdas\ndengan AI",
      "text":
          "Ketahui potensi stunting pada anak Anda menggunakan teknologi AI yang akurat.",
      "icon": "Icons.analytics",
    },
    {
      "title": "Catat & Pantau\nRiwayat Gizi",
      "text":
          "Simpan riwayat pengukuran dan pantau nutrisi anak secara berkala.",
      "icon": "Icons.history",
    },
  ];

  IconData _getIconData(String name) {
    switch (name) {
      case "Icons.child_care":
        return Icons.family_restroom_rounded;
      case "Icons.analytics":
        return Icons.analytics;
      case "Icons.history":
        return Icons.history;
      default:
        return Icons.star;
    }
  }

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF4FF), Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // ===========================
              // TOP SECTION
              // ===========================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: List.generate(
                        onboardingData.length,
                        (index) => buildDot(index: index),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),

                        borderRadius: BorderRadius.circular(16),

                        border: Border.all(color: Colors.white, width: 1.5),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.05),

                            blurRadius: 10,
                          ),
                        ],
                      ),

                      child: TextButton(
                        onPressed: _completeOnboarding,

                        child: Text(
                          "Lewati",

                          style: TextStyle(
                            color: kPrimaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===========================
              // PAGEVIEW CONTENT
              // ===========================
              Expanded(
                child: PageView.builder(
                  controller: _pageController,

                  itemCount: onboardingData.length,

                  onPageChanged: (value) {
                    setState(() {
                      _currentPage = value;
                    });
                  },

                  itemBuilder: (context, index) {
                    return OnboardingContent(
                      title: onboardingData[index]["title"]!,

                      text: onboardingData[index]["text"]!,

                      iconData: _getIconData(onboardingData[index]["icon"]!),

                      kPrimary: kPrimary,
                      kPrimaryDark: kPrimaryDark,
                      kTextLight: kTextLight,
                    );
                  },
                ),
              ),

              // ===========================
              // BUTTON
              // ===========================
              Padding(
                padding: const EdgeInsets.all(24),

                child: SizedBox(
                  width: double.infinity,
                  height: 62,

                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),

                          curve: Curves.easeInOut,
                        );
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: EdgeInsets.zero,

                      backgroundColor: Colors.transparent,

                      shadowColor: Colors.transparent,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),

                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),

                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withValues(alpha: 0.35),

                            blurRadius: 20,

                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: Container(
                        alignment: Alignment.center,

                        child: Text(
                          _currentPage == onboardingData.length - 1
                              ? "Mulai Sekarang"
                              : "Lanjut →",

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================
  // DOT INDICATOR
  // ===========================

  AnimatedContainer buildDot({int? index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),

      margin: const EdgeInsets.only(right: 8),

      height: 8,

      width: _currentPage == index ? 30 : 10,

      decoration: BoxDecoration(
        gradient: _currentPage == index
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
              )
            : null,

        color: _currentPage == index
            ? null
            : Colors.blueGrey.withValues(alpha: 0.2),

        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ===========================
// ONBOARDING CONTENT
// ===========================

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.title,
    required this.text,
    required this.iconData,
    required this.kPrimary,
    required this.kPrimaryDark,
    required this.kTextLight,
  });

  final String title;
  final String text;
  final IconData iconData;

  final Color kPrimary;
  final Color kPrimaryDark;
  final Color kTextLight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        // ===========================
        // TITLE
        // ===========================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Text(
                title,

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryDark,
                  height: 1.15,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                text,

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  color: kTextLight,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // ===========================
        // PREMIUM CARD
        // ===========================
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),

            width: double.infinity,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),

              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [
                  Colors.white.withValues(alpha: 0.95),

                  const Color(0xFFEAF4FF),
                ],
              ),

              border: Border.all(color: Colors.white, width: 2),

              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.08),

                  blurRadius: 30,
                  spreadRadius: 4,

                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Stack(
              alignment: Alignment.center,

              children: [
                // BLUR CIRCLE
                Positioned(
                  top: 40,
                  left: 30,

                  child: Container(
                    width: 120,
                    height: 120,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: kPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 50,
                  right: 30,

                  child: Container(
                    width: 90,
                    height: 90,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: Colors.cyan.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // HEART ICON
                Positioned(
                  top: 50,
                  right: 40,

                  child: Container(
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.08),

                          blurRadius: 15,
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                      size: 26,
                    ),
                  ),
                ),

                // DOTS DECORATION
                Positioned(
                  bottom: 90,
                  left: 35,

                  child: Column(
                    children: List.generate(
                      4,
                      (i) => Row(
                        children: List.generate(
                          4,
                          (j) => Container(
                            margin: const EdgeInsets.all(4),

                            width: 5,
                            height: 5,

                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.25),

                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // MAIN ICON
                Container(
                  padding: const EdgeInsets.all(42),

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.3),

                        blurRadius: 35,
                        spreadRadius: 5,
                      ),
                    ],
                  ),

                  child: Icon(iconData, size: 90, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
