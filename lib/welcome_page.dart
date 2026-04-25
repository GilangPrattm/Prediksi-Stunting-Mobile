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

  // Warna Tema (Match Laravel Landing Page)
  final Color kPrimary = const Color(0xFF10B981); // Emerald 500
  final Color kPrimaryDark = const Color(0xFF1E3A8A); // Blue 900
  final Color kBackground = const Color(0xFFF8FAFC); // Slate 50
  final Color kTextLight = const Color(0xFF64748B); // Slate 500
  final Color kCardBg = const Color(0xFFFFFFFF); // White for illustration

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Selamat Datang\ndi Stunt-Check",
      "text": "Pantau tumbuh kembang si kecil dengan mudah dan praktis di genggaman Anda.",
      "icon": "Icons.child_care"
    },
    {
      "title": "Prediksi Cerdas\ndengan AI",
      "text": "Ketahui potensi stunting pada anak Anda menggunakan teknologi AI yang akurat.",
      "icon": "Icons.analytics"
    },
    {
      "title": "Catat & Pantau\nRiwayat Gizi",
      "text": "Simpan riwayat pengukuran dan pantau nutrisi anak secara berkala.",
      "icon": "Icons.history"
    },
  ];

  IconData _getIconData(String name) {
    switch (name) {
      case "Icons.child_care": return Icons.child_care;
      case "Icons.analytics": return Icons.analytics;
      case "Icons.history": return Icons.history;
      default: return Icons.star;
    }
  }

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
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
      backgroundColor: kPrimaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section - Page Indicator & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index: index),
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: onboardingData[index]["title"]!,
                  text: onboardingData[index]["text"]!,
                  iconData: _getIconData(onboardingData[index]["icon"]!),
                  kPrimary: kPrimary,
                  kCardBg: kCardBg,
                ),
              ),
            ),

            // Bottom Section - Next/Start Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == onboardingData.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? "Mulai Sekarang" : "Lanjut \u2192",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedContainer buildDot({int? index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 4,
      width: _currentPage == index ? 24 : 12,
      decoration: BoxDecoration(
        color: _currentPage == index ? kPrimary : Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.title,
    required this.text,
    required this.iconData,
    required this.kPrimary,
    required this.kCardBg,
  });

  final String title, text;
  final IconData iconData;
  final Color kPrimary, kCardBg;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Title & Description (Top)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Illustration Placeholder (Bottom)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: kCardBg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white12, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative background elements
                Positioned(
                  top: 50,
                  right: 40,
                  child: Icon(Icons.star, color: kPrimary.withOpacity(0.5), size: 40),
                ),
                Positioned(
                  bottom: 80,
                  left: 30,
                  child: Icon(Icons.lens, color: Colors.blueAccent.withOpacity(0.3), size: 60),
                ),
                // Main Icon
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(iconData, size: 80, color: const Color(0xFF1E293B)),
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
