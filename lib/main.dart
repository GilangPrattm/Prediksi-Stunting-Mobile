import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Import semua halaman dan service
import 'welcome_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'services/auth_service.dart'; // Jangan lupa import kurirnya!
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, dynamic>> _checkInitialState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    String? token = prefs.getString('token');
    return {
      'has_seen_onboarding': hasSeenOnboarding,
      'token': token,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stunt-Check',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: FutureBuilder<Map<String, dynamic>>(
        future: _checkInitialState(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            );
          }

          if (snapshot.hasData) {
            bool hasSeenOnboarding = snapshot.data!['has_seen_onboarding'];
            String? token = snapshot.data!['token'];

            if (!hasSeenOnboarding) {
              return const WelcomePage();
            }

            if (token != null) {
              return const HomePage();
            }
          }

          return const LoginPage();
        },
      ),
    );
  }
}
