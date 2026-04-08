import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import '/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  final AuthService _authService = AuthService();

  // Warna Tema (Asklepios Style)
  final Color kPrimary = const Color(0xFF0D9488); // Premium Teal
  final Color kBackground = const Color(0xFFF8FAFC); // Slate 50
  final Color kTextDark = const Color(0xFF1E293B); // Slate 800
  final Color kTextLight = const Color(0xFF64748B); // Slate 500

  void _prosesLogin() async {
    setState(() => _isLoading = true);

    bool sukses = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (sukses) {
      if (!mounted) return;
      // Navigasi dengan animasi Fade yang smooth
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login gagal! Cek kembali email dan password Bunda.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
            // Animasi Fade & Slide Up saat halaman diload
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Judul
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.monitor_heart_outlined, color: kPrimary, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Selamat Datang,\nBunda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextDark, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mari pantau tumbuh kembang\nsi kecil bersama Stunt-Check.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: kTextLight, height: 1.4),
                  ),
                  const SizedBox(height: 40),

                  // Form Container (Clean Card Look)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          label: 'Email Address',
                          hint: 'bunda@email.com',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Tombol Login
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _prosesLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Masuk Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum punya akun? ', style: TextStyle(color: kTextLight)),
                      GestureDetector(
                        onTap: () {
                          // Navigasi dengan animasi fade
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        child: Text('Daftar di sini', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function untuk membuat input yang rapi (UI Clean)
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: kTextDark, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _isPasswordHidden : false,
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500, size: 22),
                    onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                  )
                : null,
            filled: true,
            fillColor: kBackground, // Abu-abu sangat muda
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
