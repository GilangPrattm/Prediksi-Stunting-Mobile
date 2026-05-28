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

  String? _newPasswordError;
  String? _confirmPasswordError;

  // WARNA
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
    if (_currentPasswordCtrl.text.isEmpty ||
        _newPasswordCtrl.text.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty) {
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

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('token');

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
          'current_password': _currentPasswordCtrl.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        _showSnackBar('Kata sandi berhasil diperbarui!', isError: false);

        Navigator.pop(context);
      } else {
        String serverMsg = 'Gagal memperbarui sandi.';

        try {
          final body = jsonDecode(response.body);

          if (body['message'] != null) {
            serverMsg = body['message'];
          }
        } catch (_) {}

        _showSnackBar(serverMsg, isError: true);
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

  // BUILD
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PASSWORD LAMA
                  _buildPasswordField(
                    label: 'Kata Sandi Saat Ini',
                    controller: _currentPasswordCtrl,
                    hint: 'Masukkan kata sandi saat ini',
                    isObscure: _obscureCurrent,
                    hasError: false,
                    onToggleVisibility: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

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

          // BUTTON
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
                  shadowColor: _primaryBlue.withValues(alpha: 0.4),
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
                          : _bgHitam.withValues(alpha: 0.65),
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
