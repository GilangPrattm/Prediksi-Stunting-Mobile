import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
// ⚠️ PERHATIAN: Sesuaikan letak import auth_service ini kalau kamu taruh di dalam folder khusus
import '/services/auth_service.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Siapkan 'Penangkap Ketikan' (Controller)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 2. Siapkan variabel loading dan kurir API
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Fungsi saat tombol login ditekan
  void _prosesLogin() async {
    setState(() {
      _isLoading = true; // Nyalakan efek loading
    });

    // Panggil fungsi login dari AuthService
    bool sukses = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false; // Matikan efek loading
    });

    if (sukses) {
      // Kalau berhasil, pindah ke HomePage dan hapus riwayat halaman (biar ga bisa di-back ke login)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // Kalau gagal, munculkan peringatan (SnackBar) di bawah layar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal! Cek kembali email dan password Bunda.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF009888);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Melengkung
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2), // Warning biru sudah diperbaiki
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Stunt-Check',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Pantau optimal tumbuh kembang si kecil',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Form Login
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selamat Datang!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 30),
                  
                  // Input Email
                  const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController, // Pasang controllernya di sini
                    decoration: InputDecoration(
                      hintText: 'bunda@email.com',
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Password
                  const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController, // Pasang controllernya di sini
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Lupa Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Lupa Password?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      // Kalau lagi loading, tombolnya dimatikan (null) biar ga diklik dua kali
                      onPressed: _isLoading ? null : _prosesLogin, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) // Animasi loading
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Daftar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? ', style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          // Navigasi ke Halaman Register
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()),
                          );
                        },
                        child: const Text('Daftar sekarang', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}