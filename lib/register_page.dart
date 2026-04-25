import 'package:flutter/material.dart';
import 'home_page.dart';
import '/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  final AuthService _authService = AuthService();

  // Warna Tema (Match Laravel Landing Page)
  final Color kTopBg = const Color(0xFF1E3A8A); // Blue 900
  final Color kBottomBg = const Color(0xFFF8FAFC); // Slate 50
  final Color kButtonBg = const Color(0xFF10B981); // Emerald 500
  final Color kTextDark = const Color(0xFF1E293B); 
  final Color kTextLight = const Color(0xFF64748B);

  // Variable to show local error if passwords don't match
  String? _passwordError;

  void _prosesDaftar() async {
    // Validasi lokal
    if (_nameController.text.isEmpty ||
        _noHpController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      _showErrorSnackBar('Semua kolom harus diisi!');
      return;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() {
        _passwordError = 'ERROR: Password do not match!';
      });
      return;
    } else {
      setState(() {
        _passwordError = null;
      });
    }

    setState(() => _isLoading = true);

    var respons = await _authService.register(
      _nameController.text,
      _noHpController.text,
      _emailController.text,
      _passwordController.text,
      _passwordConfirmController.text,
    );

    setState(() => _isLoading = false);

    if (respons['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respons['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Kembali ke halaman Login
    } else {
      if (!mounted) return;
      _showErrorSnackBar(respons['message'] ?? 'Gagal mendaftar!');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTopBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section (Dark Header)
            Container(
              height: MediaQuery.of(context).size.height * 0.20,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.child_care, color: Color(0xFF06B6D4), size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign Up For Free!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Section (Light Form)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: kBottomBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      _buildInputField(
                        label: 'Full Name',
                        hint: 'Enter your full name...',
                        icon: Icons.person_outline,
                        controller: _nameController,
                      ),
                      const SizedBox(height: 16),
                      
                      // Nomor HP
                      _buildInputField(
                        label: 'Nomor Handphone',
                        hint: '081234567890',
                        icon: Icons.phone_android,
                        controller: _noHpController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      _buildInputField(
                        label: 'Email Address',
                        hint: 'Enter your email address...',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),
                      
                      // Password
                      _buildInputField(
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        isHidden: _isPasswordHidden,
                        onVisibilityToggle: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                      ),
                      const SizedBox(height: 16),

                      // Password Confirmation
                      _buildInputField(
                        label: 'Password Confirmation',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        controller: _passwordConfirmController,
                        isPassword: true,
                        isHidden: _isConfirmPasswordHidden,
                        onVisibilityToggle: () => setState(() => _isConfirmPasswordHidden = !_isConfirmPasswordHidden),
                        hasError: _passwordError != null,
                      ),
                      
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(_passwordError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                      
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _prosesDaftar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Sign Up \u2192', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ', style: TextStyle(color: kTextLight)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Sign In.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isHidden = true,
    VoidCallback? onVisibilityToggle,
    bool hasError = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hasError ? Colors.red.shade300 : Colors.transparent, width: hasError ? 1.5 : 0),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword ? isHidden : false,
            keyboardType: keyboardType,
            style: TextStyle(color: kTextDark, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: Colors.grey.shade700, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade700, size: 22),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
