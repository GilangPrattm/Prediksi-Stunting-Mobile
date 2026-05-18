import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

class UbahSandiPage extends StatefulWidget {
  final String namaLengkap;
  final String email;

  const UbahSandiPage({
    super.key,
    required this.namaLengkap,
    required this.email,
  });

  @override
  State<UbahSandiPage> createState() => _UbahSandiPageState();
}

class _UbahSandiPageState extends State<UbahSandiPage> {
  final TextEditingController _currentPasswordCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // --- TEMA WARNA ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _inputBg = Colors.white;

  Future<void> _perbaruiSandi() async {
    // Validasi lokal
    if (_currentPasswordCtrl.text.isEmpty ||
        _newPasswordCtrl.text.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty) {
      _showSnackBar('Mohon isi semua kolom kata sandi.', isError: true);
      return;
    }

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      _showSnackBar('Konfirmasi kata sandi baru tidak cocok.', isError: true);
      return;
    }

    if (_newPasswordCtrl.text.length < 8) {
      _showSnackBar('Kata sandi baru minimal 8 karakter.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/profil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': widget.namaLengkap,
          'email': widget.email,
          'password': _newPasswordCtrl.text,
          // Catatan: Jika backend kamu butuh kata sandi lama untuk divalidasi,
          // kamu bisa menambahkannya di sini, contoh: 'current_password': _currentPasswordCtrl.text
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        _showSnackBar('Kata sandi berhasil diperbarui!', isError: false);
        Navigator.pop(context); // Kembali ke halaman profil
      } else {
        _showSnackBar('Gagal memperbarui sandi. Cek kembali data Anda.', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan jaringan.', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : _primaryBlue,
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
          icon: Icon(Icons.arrow_back, color: _bgHitam),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ubah Kata Sandi',
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordField(
                    label: 'Kata Sandi Saat Ini',
                    controller: _currentPasswordCtrl,
                    hint: 'Masukkan kata sandi saat ini',
                    isObscure: _obscureCurrent,
                    onToggleVisibility: () {
                      setState(() => _obscureCurrent = !_obscureCurrent);
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildPasswordField(
                    label: 'Kata Sandi Baru',
                    controller: _newPasswordCtrl,
                    hint: 'Masukkan kata sandi baru',
                    isObscure: _obscureNew,
                    onToggleVisibility: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(
                    label: 'Konfirmasi Kata Sandi Baru',
                    controller: _confirmPasswordCtrl,
                    hint: 'Ulangi kata sandi baru',
                    isObscure: _obscureConfirm,
                    onToggleVisibility: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCE9FF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _primaryBlue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Kata sandi harus terdiri dari minimal 8 karakter, mengandung setidaknya satu huruf besar, satu huruf kecil, dan satu angka untuk keamanan optimal.',
                            style: TextStyle(
                              color: _bgHitam.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceBg,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _perbaruiSandi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  shadowColor: _primaryBlue.withOpacity(0.4),
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
                        'Perbarui Kata Sandi',
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _outlineColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: TextStyle(color: _bgHitam, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryBlue, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _outlineColor,
                size: 22,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}