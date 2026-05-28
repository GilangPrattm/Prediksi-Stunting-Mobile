import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _identifierController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordHidden = true;

  late AnimationController _animController;

  late Animation<double> _fadeAnim;

  late Animation<Offset> _slideAnim;

  // =========================
  // COLORS
  // =========================

  static const Color kPrimary = Color(0xFF005AB5);

  static const Color kBackground = Color(0xFFF9F9FF);

  static const Color kSurface = Color(0xFFFFFFFF);

  static const Color kSurfaceContainer = Color(0xFFEBEDF8);

  static const Color kOnSurface = Color(0xFF181C23);

  static const Color kOnSurfaceVariant = Color(0xFF414753);

  static const Color kOutlineVariant = Color(0xFFC1C6D5);

  static const Color kButtonBg = Color(0xFF005AB5);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();

    _identifierController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  // =========================
  // LOGIN
  // =========================

  final AuthService _authService = AuthService();

  void _prosesLogin() async {
    if (_identifierController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email/No HP dan password harus diisi'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool sukses = await _authService.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (sukses) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomePage(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email/Nomor HP atau Password salah'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================

  void _showForgotPasswordSheet() {
    final TextEditingController emailController = TextEditingController();

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),

          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 6,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,

                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Lupa Kata Sandi',

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                'Masukkan email Anda untuk membuat password baru.',

                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: emailController,

                decoration: InputDecoration(
                  hintText: 'Masukkan email',

                  prefixIcon: const Icon(Icons.email_outlined),

                  filled: true,

                  fillColor: const Color(0xFFF1F5F9),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (_) => const CreateNewPasswordPage(),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonBg,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    'Lanjut',

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,

      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        centerTitle: true,

        title: const Text(
          'Stunt Check',

          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kPrimary,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,

            colors: [Color(0xFFD7E3FF), Colors.white],
          ),
        ),

        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,

            child: SlideTransition(
              position: _slideAnim,

              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),

                child: Column(
                  children: [
                    _buildLogo(),

                    const SizedBox(height: 28),

                    _buildGreeting(),

                    const SizedBox(height: 28),

                    _buildFormCard(),

                    const SizedBox(height: 20),

                    _buildSignUpRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // LOGO
  // =========================

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          color: Colors.white,

          border: Border.all(color: kSurfaceContainer, width: 4),

          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.18),

              blurRadius: 24,

              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: ClipOval(
          child: Image.asset('assets/images/Logo_Stunt.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  // =========================
  // GREETING
  // =========================

  Widget _buildGreeting() {
    return Column(
      children: [
        const Text(
          'Halo, Bunda!',

          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kOnSurface,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Selamat Datang Kembali\nPantau tumbuh kembang si kecil dengan\nmudah menggunakan Stunt Check',

          textAlign: TextAlign.center,

          style: TextStyle(
            fontSize: 14,
            height: 1.6,

            color: kOnSurfaceVariant.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // =========================
  // FORM CARD
  // =========================

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.08),

            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          _buildLabel('Alamat Email'),

          const SizedBox(height: 6),

          _buildTextField(
            controller: _identifierController,

            hint: 'email@contoh.com',

            prefixIcon: Icons.mail_outline_rounded,
          ),

          const SizedBox(height: 16),

          _buildLabel('Kata Sandi'),

          const SizedBox(height: 6),

          _buildTextField(
            controller: _passwordController,

            hint: '••••••••',

            prefixIcon: Icons.lock_outline_rounded,

            isPassword: true,
          ),

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerRight,

            child: GestureDetector(
              onTap: _showForgotPasswordSheet,

              child: const Text(
                'Lupa kata sandi?',

                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,

            child: ElevatedButton(
              onPressed: _isLoading ? null : _prosesLogin,

              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonBg,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Masuk',

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // SIGN UP
  // =========================

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        const Text('Belum punya akun? '),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,

              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          },

          child: const Text(
            'Buat di sini',

            style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // =========================
  // LABEL
  // =========================

  Widget _buildLabel(String text) {
    return Text(
      text,

      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  // =========================
  // TEXTFIELD
  // =========================

  Widget _buildTextField({
    required TextEditingController controller,

    required String hint,

    required IconData prefixIcon,

    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,

      obscureText: isPassword ? _isPasswordHidden : false,

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(prefixIcon),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                ),

                onPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              )
            : null,

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ===============================
// CREATE NEW PASSWORD PAGE
// ===============================

class CreateNewPasswordPage extends StatefulWidget {
  const CreateNewPasswordPage({super.key});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 20),

            const Text(
              'Buat Password\nBaru',

              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            const Text('Masukkan password baru untuk akun Anda.'),

            const SizedBox(height: 40),

            TextField(
              controller: _passwordController,

              obscureText: _hidePassword,

              decoration: InputDecoration(
                hintText: 'Password baru',

                prefixIcon: const Icon(Icons.lock_outline),

                suffixIcon: IconButton(
                  icon: Icon(
                    _hidePassword ? Icons.visibility_off : Icons.visibility,
                  ),

                  onPressed: () {
                    setState(() {
                      _hidePassword = !_hidePassword;
                    });
                  },
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _confirmPasswordController,

              obscureText: _hidePassword,

              decoration: InputDecoration(
                hintText: 'Konfirmasi password',

                prefixIcon: const Icon(Icons.lock_outline),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton(
                onPressed: () async {
                  if (_passwordController.text.isEmpty ||
                      _confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua field harus diisi')),
                    );

                    return;
                  }

                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password tidak cocok')),
                    );

                    return;
                  }

                  // SIMPAN PASSWORD BARU
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();

                  await prefs.setString(
                    'new_password',
                    _passwordController.text,
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password berhasil diperbarui'),
                    ),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,

                    MaterialPageRoute(builder: (_) => const LoginPage()),

                    (route) => false,
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005AB5),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: const Text(
                  'Simpan Password',

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
