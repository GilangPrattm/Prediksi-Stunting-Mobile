import 'package:flutter/material.dart';
import '/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  String? _passwordReqError;
  String? _passwordMatchError;

  final AuthService _authService = AuthService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const Color kPrimary = Color(0xFF005AB5);
  static const Color kBackground = Color(0xFFF9F9FF);
  static const Color kSurface = Color(0xFFFFFFFF);
  static const Color kSurfaceBright = Color(0xFFF9F9FF);
  static const Color kSurfaceContainer = Color(0xFFEBEDF8);
  static const Color kOnSurface = Color(0xFF181C23);
  static const Color kOnSurfaceVariant = Color(0xFF414753);
  static const Color kOutlineVariant = Color(0xFFC1C6D5);
  static const Color kError = Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // ── Validasi Password (Real-time) ──────────────────────────────
  String? _checkPasswordStrength(String value) {
    if (value.isEmpty) return 'Password tidak boleh kosong.';
    if (value.length < 8) return 'Password minimal 8 karakter.';
    if (!value.contains(RegExp(r'[A-Z]')))
      return 'Password harus mengandung huruf besar.';
    if (!value.contains(RegExp(r'[0-9]')))
      return 'Password harus mengandung angka.';
    return null;
  }

  // ── Ekstrak pesan error dari response backend ──────────────────
  // Menangani berbagai format response:
  //   {"success": false, "message": "..."}
  //   {"status": "error", "message": "..."}
  //   {"errors": {"email": ["..."], "phone": ["..."]}}
  String _extractErrorMessage(Map<String, dynamic> respons) {
    // 1. Cek key 'message' langsung
    if (respons['message'] != null &&
        respons['message'].toString().trim().isNotEmpty) {
      return respons['message'].toString();
    }

    // 2. Cek key 'error' (singular)
    if (respons['error'] != null &&
        respons['error'].toString().trim().isNotEmpty) {
      return respons['error'].toString();
    }

    // 3. Cek nested validation errors (Laravel style)
    //    {"errors": {"email": ["The email has already been taken."]}}
    final errors = respons['errors'];
    if (errors is Map && errors.isNotEmpty) {
      // Prioritaskan field email dan phone karena paling relevan untuk duplikat
      for (final key in ['email', 'no_hp', 'phone', 'name', 'password']) {
        final fieldErrors = errors[key];
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          return _translateLaravelMessage(fieldErrors.first.toString());
        }
      }
      // Fallback: ambil error pertama dari field manapun
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return _translateLaravelMessage(first.first.toString());
      }
    }

    // 4. Fallback default
    return 'Pendaftaran gagal. Silakan coba lagi.';
  }

  // ── Terjemahan pesan error Laravel ke Bahasa Indonesia ─────────
  String _translateLaravelMessage(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('already been taken') ||
        lower.contains('already exists')) {
      if (lower.contains('email')) return 'Email ini sudah terdaftar.';
      if (lower.contains('phone') || lower.contains('no_hp')) {
        return 'Nomor HP ini sudah terdaftar.';
      }
      return 'Data ini sudah terdaftar.';
    }
    if (lower.contains('invalid') && lower.contains('email')) {
      return 'Format email tidak valid.';
    }
    if (lower.contains('required')) return 'Kolom ini wajib diisi.';
    if (lower.contains('min') && lower.contains('8')) {
      return 'Password minimal 8 karakter.';
    }
    // Kembalikan pesan asli jika tidak dikenali
    return msg;
  }

  // ── Proses Daftar ──────────────────────────────────────────────
  void _prosesDaftar() async {
    // Validasi field kosong
    if (_nameController.text.trim().isEmpty ||
        _noHpController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      _showSnackBar('Semua kolom harus diisi!', isError: true);
      return;
    }

    // Validasi kekuatan password
    final reqError = _checkPasswordStrength(_passwordController.text);
    if (reqError != null) {
      setState(() => _passwordReqError = reqError);
      return;
    }

    // Validasi kecocokan password
    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() => _passwordMatchError = 'Password tidak cocok.');
      return;
    }

    setState(() {
      _passwordReqError = null;
      _passwordMatchError = null;
      _isLoading = true;
    });

    try {
      final respons = await _authService.register(
        _nameController.text.trim(),
        _noHpController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _passwordConfirmController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Debug: uncomment baris di bawah untuk melihat response di console
      // debugPrint('REGISTER RESPONSE: $respons');

      final bool isSuccess =
          respons['success'] == true || respons['status'] == 'success';

      if (isSuccess) {
        final msg = respons['message']?.toString() ?? 'Pendaftaran berhasil!';
        _showSnackBar(msg, isError: false);
        Navigator.pop(context);
      } else {
        _showSnackBar(_extractErrorMessage(respons), isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan koneksi. Coba lagi.', isError: true);
      debugPrint('REGISTER ERROR: $e');
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    // Tutup SnackBar sebelumnya agar tidak menumpuk
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFBA1A1A)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7E3FF), Color(0xFFFFFFFF)],
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
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF005AB5).withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),

                          _buildLabel('Nama Lengkap'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Masukkan nama lengkap Anda',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('No HP'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _noHpController,
                            hint: 'Contoh: 081234567890',
                            prefixIcon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Email'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'email@contoh.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Minimal 8 karakter',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isHidden: _isPasswordHidden,
                            hasError: _passwordReqError != null,
                            onVisibilityToggle: () => setState(
                              () => _isPasswordHidden = !_isPasswordHidden,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _passwordReqError = _checkPasswordStrength(val);
                                if (_passwordConfirmController
                                    .text
                                    .isNotEmpty) {
                                  _passwordMatchError =
                                      (val != _passwordConfirmController.text)
                                      ? 'Password tidak cocok.'
                                      : null;
                                }
                              });
                            },
                          ),
                          if (_passwordReqError != null) ...[
                            const SizedBox(height: 8),
                            _buildInlineError(_passwordReqError!),
                          ],
                          const SizedBox(height: 16),

                          _buildLabel('Konfirmasi Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordConfirmController,
                            hint: 'Ulangi password Anda',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isHidden: _isConfirmPasswordHidden,
                            hasError: _passwordMatchError != null,
                            onVisibilityToggle: () => setState(
                              () => _isConfirmPasswordHidden =
                                  !_isConfirmPasswordHidden,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _passwordMatchError =
                                    (val != _passwordController.text)
                                    ? 'Password tidak cocok.'
                                    : null;
                              });
                            },
                          ),
                          if (_passwordMatchError != null) ...[
                            const SizedBox(height: 8),
                            _buildInlineError(_passwordMatchError!),
                          ],

                          const SizedBox(height: 28),

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _prosesDaftar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                disabledBackgroundColor: kPrimary.withOpacity(
                                  0.6,
                                ),
                                elevation: 3,
                                shadowColor: kPrimary.withOpacity(0.35),
                                shape: const StadiumBorder(),
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
                                      'Daftar Sekarang',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kOnSurfaceVariant,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Masuk di sini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kSurfaceContainer,
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Image.asset(
              'assets/images/Logo_Stunt.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.child_care_rounded,
                size: 52,
                color: kPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mari pantau tumbuh kembang si kecil\nbersama Stunt-Check.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: kOnSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
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

  Widget _buildInlineError(String message) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: kError, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: kError,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isHidden : false,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: kOnSurface,
      ),
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
                  isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kPrimary,
                  size: 22,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: kSurfaceBright,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? kError : kOutlineVariant,
            width: hasError ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hasError ? kError : kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kError, width: 1.5),
        ),
      ),
    );
  }
}
