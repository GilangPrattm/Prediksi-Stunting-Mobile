import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import '/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _rememberMe = false;

  final AuthService _authService = AuthService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // COLORS
  static const Color kPrimary = Color(0xFF006A63);
  static const Color kBackground = Color(0xFFF8FAFA);
  static const Color kSurface = Color(0xFFFFFFFF);
  static const Color kSurfaceContainer = Color(0xFFECEEEE);
  static const Color kOnSurface = Color(0xFF191C1D);
  static const Color kOnSurfaceVariant = Color(0xFF3D4947);
  static const Color kOutlineVariant = Color(0xFFBDC9C6);
  static const Color kButtonBg = Color(0xFF0056B3);

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

  // LOGIN
  void _prosesLogin() async {
    setState(() => _isLoading = true);

    bool sukses = await _authService.login(
      _identifierController.text,
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
          content: const Text('Login gagal! Cek kembali email dan password.'),

          backgroundColor: Colors.red.shade400,

          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // FORGOT PASSWORD
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,

      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 1,
        centerTitle: true,

        title: const Text(
          'Stunt Check',

          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),

      body: FadeTransition(
        opacity: _fadeAnim,

        child: SlideTransition(
          position: _slideAnim,

          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),

            child: Column(
              children: [
                _buildLogo(),

                const SizedBox(height: 28),

                _buildGreeting(),

                const SizedBox(height: 28),

                _buildFormCard(),

                const SizedBox(height: 20),

                _buildSignUpRow(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LOGO
  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kSurface,

          border: Border.all(color: kSurfaceContainer, width: 4),

          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DB6AC).withValues(alpha: 0.18),

              blurRadius: 24,

              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: ClipOval(
          child: Image.asset(
            'assets/images/Logo_Stunt.png',

            fit: BoxFit.cover,

            errorBuilder: (_, __, ___) =>
                const Icon(Icons.child_care_rounded, size: 60, color: kPrimary),
          ),
        ),
      ),
    );
  }

  // GREETING
  Widget _buildGreeting() {
    return Column(
      children: [
        const Text(
          'Halo, Bunda!',

          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kOnSurface,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Selamat Datang Kembali\nPantau tumbuh kembang si kecil dengan\nmudah menggunakan Stunt Check',

          textAlign: TextAlign.center,

          style: TextStyle(
            fontSize: 14,
            height: 1.6,

            color: kOnSurfaceVariant.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // FORM CARD
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: kOutlineVariant.withValues(alpha: 0.5)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DB6AC).withValues(alpha: 0.08),

            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      padding: const EdgeInsets.all(20),

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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,

                    child: Checkbox(
                      value: _rememberMe,

                      activeColor: kPrimary,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),

                      side: BorderSide(color: kOutlineVariant),

                      onChanged: (v) {
                        setState(() {
                          _rememberMe = v ?? false;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Ingat saya',

                    style: TextStyle(fontSize: 13, color: kOnSurfaceVariant),
                  ),
                ],
              ),

              GestureDetector(
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
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,

            child: ElevatedButton(
              onPressed: _isLoading ? null : _prosesLogin,

              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonBg,

                disabledBackgroundColor: kButtonBg.withValues(alpha: 0.6),

                elevation: 3,

                shadowColor: kButtonBg.withValues(alpha: 0.35),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,

                      child: CircularProgressIndicator(
                        color: Colors.white,

                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Masuk',

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // SIGN UP
  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Text(
          'Belum punya akun? ',

          style: TextStyle(fontSize: 14, color: kOnSurfaceVariant),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,

              PageRouteBuilder(
                pageBuilder: (_, a, __) => const RegisterPage(),

                transitionsBuilder: (_, a, __, child) =>
                    FadeTransition(opacity: a, child: child),

                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },

          child: const Text(
            'Buat di sini',

            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // LABEL
  Widget _buildLabel(String text) {
    return Text(
      text,

      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: kOnSurfaceVariant,
      ),
    );
  }

  // TEXTFIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,

      obscureText: isPassword ? _isPasswordHidden : false,

      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: kOnSurface,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: TextStyle(
          color: kOutlineVariant.withValues(alpha: 0.9),

          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),

        prefixIcon: Icon(prefixIcon, color: kOutlineVariant, size: 22),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,

                  color: kOutlineVariant,
                  size: 22,
                ),

                onPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              )
            : null,

        filled: true,
        fillColor: kBackground,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: BorderSide(color: kOutlineVariant, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),

          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
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
      backgroundColor: const Color(0xFFF8FAFA),

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

              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Masukkan password baru untuk akun Anda.',

              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),

            const SizedBox(height: 40),

            // PASSWORD BARU
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

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(
                    color: Color(0xFF0056B3),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // KONFIRMASI PASSWORD
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

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(
                    color: Color(0xFF0056B3),
                    width: 2,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // BUTTON SIMPAN PASSWORD
            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton(
                onPressed: () {
                  // VALIDASI
                  if (_passwordController.text.isEmpty ||
                      _confirmPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua field harus diisi')),
                    );
                    return;
                  }

                  // PASSWORD TIDAK COCOK
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password tidak cocok')),
                    );
                    return;
                  }

                  // SUKSES
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password berhasil diperbarui'),
                    ),
                  );

                  // KEMBALI KE LOGIN
                  Navigator.pushAndRemoveUntil(
                    context,

                    MaterialPageRoute(builder: (_) => const LoginPage()),

                    (route) => false,
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0056B3),

                  elevation: 0,

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
