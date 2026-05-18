import 'package:flutter/material.dart';
import '/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController            = TextEditingController();
  final TextEditingController _noHpController            = TextEditingController();
  final TextEditingController _emailController           = TextEditingController();
  final TextEditingController _passwordController        = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  bool _isLoading               = false;
  bool _isPasswordHidden        = true;
  bool _isConfirmPasswordHidden = true;
  String? _passwordError;

  final AuthService _authService = AuthService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset>  _slideAnim;

  // ── Warna dari HTML (register theme – blue) ──────────────────
  static const Color kPrimary          = Color(0xFF005AB5); // primary
  static const Color kBackground       = Color(0xFFF9F9FF); // background
  static const Color kSurface          = Color(0xFFFFFFFF); // surface-container-lowest
  static const Color kSurfaceBright    = Color(0xFFF9F9FF); // surface-bright
  static const Color kSurfaceContainer = Color(0xFFEBEDF8); // surface-container
  static const Color kOnSurface        = Color(0xFF181C23); // on-surface
  static const Color kOnSurfaceVariant = Color(0xFF414753); // on-surface-variant
  static const Color kOutlineVariant   = Color(0xFFC1C6D5); // outline-variant
  static const Color kError            = Color(0xFFBA1A1A); // error

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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

  // ── Logic ──────────────────────────────────────────────────────
  void _prosesDaftar() async {
    if (_nameController.text.isEmpty ||
        _noHpController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      _showSnackBar('Semua kolom harus diisi!', isError: true);
      return;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() => _passwordError = 'Password tidak cocok.');
      return;
    }
    setState(() => _passwordError = null);

    setState(() => _isLoading = true);
    var respons = await _authService.register(
      _nameController.text,
      _noHpController.text,
      _emailController.text,
      _passwordController.text,
      _passwordConfirmController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (respons['success'] == true) {
      _showSnackBar(respons['message'], isError: false);
      Navigator.pop(context);
    } else {
      _showSnackBar(respons['message'] ?? 'Gagal mendaftar!', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Container(
        // Gradient background: primary-fixed (#D7E3FF) → white
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
                          // ── Header ────────────────────────────
                          _buildHeader(),
                          const SizedBox(height: 28),

                          // ── Form Fields ───────────────────────
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
                            onVisibilityToggle: () =>
                                setState(() => _isPasswordHidden = !_isPasswordHidden),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Konfirmasi Password'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordConfirmController,
                            hint: 'Ulangi password Anda',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isHidden: _isConfirmPasswordHidden,
                            hasError: _passwordError != null,
                            onVisibilityToggle: () => setState(
                                () => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                          ),

                          // Password error
                          if (_passwordError != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: kError, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _passwordError!,
                                  style: const TextStyle(
                                    color: kError,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 28),

                          // ── Daftar Button ─────────────────────
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _prosesDaftar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                disabledBackgroundColor: kPrimary.withOpacity(0.6),
                                elevation: 3,
                                shadowColor: kPrimary.withOpacity(0.35),
                                shape: const StadiumBorder(),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
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

                          // ── Sign In Link ──────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                    fontSize: 14, color: kOnSurfaceVariant),
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

  // ── HEADER ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo circle
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
        Text(
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

  // ── HELPERS ───────────────────────────────────────────────────
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isHidden : false,
      keyboardType: keyboardType,
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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