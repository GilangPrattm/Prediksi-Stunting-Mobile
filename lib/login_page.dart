import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config/api_config.dart';
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
  static const Color kSurfaceBright = Color(0xFFF9F9FF);
  static const Color kSurfaceContainer = Color(0xFFEBEDF8);
  static const Color kOnSurface = Color(0xFF181C23);
  static const Color kOnSurfaceVariant = Color(0xFF414753);
  static const Color kOutlineVariant = Color(0xFFC1C6D5);
  static const Color kButtonBg = Color(0xFF005AB5);
  static const Color kError = Color(0xFFBA1A1A);

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
                    if (emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Silakan masukkan email Anda')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateNewPasswordPage(email: emailController.text.trim()),
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
  // LOGO & GREETING
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
          _buildLabel('Alamat Email atau No HP'),
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
            isHidden: _isPasswordHidden,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordHidden = !_isPasswordHidden;
              });
            },
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
  // SIGN UP ROW
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
  // HELPERS (DISAMAKAN DENGAN REGISTER)
  // =========================
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: kOnSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isHidden = true,
    bool hasError = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isHidden : false,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kOnSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: kOutlineVariant.withOpacity(0.9),
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        prefixIcon: Icon(prefixIcon, color: kPrimary, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kPrimary,
                  size: 22,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: kSurfaceBright,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? kError : kOutlineVariant,
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? kError : kPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kError, width: 1.5),
        ),
      ),
    );
  }
}

// ===============================
// CREATE NEW PASSWORD PAGE
// (Diadaptasi dari ubah_sandi_page.dart, 
// tanpa "Kata Sandi Saat Ini")
// ===============================

class CreateNewPasswordPage extends StatefulWidget {
  final String email;
  const CreateNewPasswordPage({super.key, required this.email});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _newPasswordError;
  String? _confirmPasswordError;

  // WARNA (Diambil dari Ubah Sandi Page)
  static const Color _primaryBlue = Color(0xFF1978E5);
  static const Color _bgHitam = Color(0xFF0B1C30);
  static const Color _surfaceBg = Color(0xFFF8F9FF);
  static const Color _outlineColor = Color(0xFF717785);
  static const Color _inputBg = Colors.white;
  static const Color _kError = Color(0xFFBA1A1A);

  // VALIDASI PASSWORD
  String? _checkPasswordStrength(String value) {
    if (value.isEmpty) {
      return 'Kata sandi tidak boleh kosong.';
    }
    if (value.length < 8) {
      return 'Kata sandi minimal 8 karakter.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Harus mengandung minimal 1 huruf besar (A-Z).';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Harus mengandung minimal 1 huruf kecil (a-z).';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Harus mengandung minimal 1 angka (0-9).';
    }
    return null;
  }

  // UPDATE PASSWORD
  Future<void> _perbaruiSandi() async {
    if (_newPasswordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) {
      _showSnackBar('Mohon isi semua kolom kata sandi.', isError: true);
      return;
    }

    final reqError = _checkPasswordStrength(_newPasswordCtrl.text);

    if (reqError != null) {
      setState(() {
        _newPasswordError = reqError;
      });
      return;
    }

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() {
        _confirmPasswordError = 'Konfirmasi kata sandi tidak cocok.';
      });
      return;
    }

    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': _newPasswordCtrl.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Password berhasil diperbarui! Silakan login.', isError: false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else {
        _showSnackBar('Email tidak ditemukan atau terjadi kesalahan.', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Terjadi kesalahan jaringan.', isError: true);
    }
  }

  // SNACKBAR
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? _kError : _primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        backgroundColor: _surfaceBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _bgHitam),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Buat Kata Sandi Baru',
          style: TextStyle(
            color: _bgHitam,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan password baru untuk akun Anda. Pastikan password kuat dan mudah diingat.',
                    style: TextStyle(fontSize: 14, color: _outlineColor),
                  ),
                  const SizedBox(height: 30),

                  // PASSWORD BARU
                  _buildPasswordField(
                    label: 'Kata Sandi Baru',
                    controller: _newPasswordCtrl,
                    hint: 'Masukkan kata sandi baru',
                    isObscure: _obscureNew,
                    hasError: _newPasswordError != null,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        _newPasswordError = _checkPasswordStrength(val);

                        if (_confirmPasswordCtrl.text.isNotEmpty) {
                          _confirmPasswordError =
                              val != _confirmPasswordCtrl.text
                              ? 'Konfirmasi kata sandi tidak cocok.'
                              : null;
                        }
                      });
                    },
                  ),

                  if (_newPasswordError != null) ...[
                    const SizedBox(height: 6),
                    _buildInlineError(_newPasswordError!),
                  ],

                  const SizedBox(height: 10),
                  _buildPasswordRequirements(),
                  const SizedBox(height: 20),

                  // KONFIRMASI
                  _buildPasswordField(
                    label: 'Konfirmasi Kata Sandi Baru',
                    controller: _confirmPasswordCtrl,
                    hint: 'Ulangi kata sandi baru',
                    isObscure: _obscureConfirm,
                    hasError: _confirmPasswordError != null,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        _confirmPasswordError = val != _newPasswordCtrl.text
                            ? 'Konfirmasi kata sandi tidak cocok.'
                            : null;
                      });
                    },
                  ),

                  if (_confirmPasswordError != null) ...[
                    const SizedBox(height: 6),
                    _buildInlineError(_confirmPasswordError!),
                  ],
                ],
              ),
            ),
          ),

          // BUTTON SIMPAN
          Container(
            padding: const EdgeInsets.all(24),
            color: _surfaceBg,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _perbaruiSandi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  elevation: 4,
                  shadowColor: _primaryBlue.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Simpan Kata Sandi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REQUIREMENTS BOX
  Widget _buildPasswordRequirements() {
    final requirements = [
      'Minimal 8 karakter',
      'Minimal 1 huruf besar (A-Z)',
      'Minimal 1 huruf kecil (a-z)',
      'Minimal 1 angka (0-9)',
    ];

    bool isFulfilled(int index) {
      final val = _newPasswordCtrl.text;
      switch (index) {
        case 0:
          return val.length >= 8;
        case 1:
          return val.contains(RegExp(r'[A-Z]'));
        case 2:
          return val.contains(RegExp(r'[a-z]'));
        case 3:
          return val.contains(RegExp(r'[0-9]'));
        default:
          return false;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: _primaryBlue, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Kata sandi harus memenuhi:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(requirements.length, (i) {
            final ok = isFulfilled(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: ok ? Colors.green : _outlineColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    requirements[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: ok
                          ? Colors.green
                          : _bgHitam.withOpacity(0.65),
                      fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // INLINE ERROR
  Widget _buildInlineError(String message) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: _kError, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: _kError,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // PASSWORD FIELD
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required bool hasError,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _outlineColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          onChanged: onChanged,
          style: const TextStyle(color: _bgHitam, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _kError : Colors.grey.shade300,
                width: hasError ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _kError : _primaryBlue,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _outlineColor,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}