import 'package:flutter/material.dart';

// Import semua halaman dan service
import 'login_page.dart';
import 'home_page.dart';
import 'services/auth_service.dart'; // Jangan lupa import kurirnya!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stunt-Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF2563EB)),

      // Kita pakai FutureBuilder buat ngecek token pas aplikasi pertama kali dibuka
      home: FutureBuilder<String?>(
        future: AuthService().getToken(), // Minta tolong kurir ngecek brankas
        builder: (context, snapshot) {
          // 1. Kalau masih ngecek (loading), tampilin muter-muter bentar
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            );
          }

          // 2. Kalau di brankas ternyata ADA tokennya, langsung masuk ke Beranda!
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }

          // 3. Kalau brankasnya kosong (belum login / habis logout), suruh Login dulu.
          return const LoginPage();
        },
      ),
    );
  }
}
