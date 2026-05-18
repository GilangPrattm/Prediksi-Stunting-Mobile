import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final String _baseUrl = ApiConfig.baseUrl;

  // Controller Akun (users table)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controller Profil Kesehatan (ibu table)
  final TextEditingController _tglLahirController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _tinggiController = TextEditingController();
  String? _pendidikanPilih;
  String? _pekerjaanPilih;

  bool _isLoading = true;
  bool _isSaving = false;

  // --- WARNA TEMA KONSISTEN ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _inputBg = const Color(0xFFF8F9FF);

  @override
  void initState() {
    super.initState();
    _fetchKombinasiProfil();
  }

  // Tarik Data Akun sekaligus Data Kesehatan
  Future<void> _fetchKombinasiProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final responseAkun = await http.get(
        Uri.parse('$_baseUrl/profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final responseIbu = await http.get(
        Uri.parse('$_baseUrl/profil-ibu'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (responseAkun.statusCode == 200) {
        final dataAkun = jsonDecode(responseAkun.body)['data'];
        setState(() {
          _nameController.text = dataAkun['name'] ?? '';
          _emailController.text = dataAkun['email'] ?? '';
          _teleponController.text = dataAkun['telepon'] ?? '';
        });
      }

      if (responseIbu.statusCode == 200) {
        final dataIbu = jsonDecode(responseIbu.body);
        if (dataIbu is List && dataIbu.isNotEmpty) {
          final firstIbu = dataIbu[0];
          setState(() {
            int usia = firstIbu['usia_ibu'] ?? 0;
            if (usia > 0) {
              int birthYear = DateTime.now().year - usia;
              _tglLahirController.text = "01/01/$birthYear";
            }
            _tinggiController.text = firstIbu['tinggi_ibu']?.toString() ?? '';
            _pendidikanPilih = firstIbu['pendidikan_ibu'];
            _pekerjaanPilih = firstIbu['pekerjaan_ibu'];
          });
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pilihTanggal() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              onSurface: _bgHitam,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _tglLahirController.text =
            "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
      });
    }
  }

  Future<void> _updateProfil() async {
    setState(() => _isSaving = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    int calculatedUsia = 0;
    if (_tglLahirController.text.isNotEmpty) {
      List<String> parts = _tglLahirController.text.split('/');
      if (parts.length == 3) {
        DateTime dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        DateTime now = DateTime.now();
        calculatedUsia = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calculatedUsia--;
        }
      }
    }

    try {
      Map<String, dynamic> payloadAkun = {
        'name': _nameController.text,
        'email': _emailController.text,
        'telepon': _teleponController.text,
      };

      await http.put(
        Uri.parse('$_baseUrl/profil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payloadAkun),
      );

      await http.post(
        Uri.parse('$_baseUrl/profil-ibu'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usia_ibu': calculatedUsia,
          'tinggi_ibu': double.tryParse(_tinggiController.text) ?? 0,
          'pendidikan_ibu': _pendidikanPilih ?? '',
          'pekerjaan_ibu': _pekerjaanPilih ?? '',
        }),
      );

      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hore! Seluruh Profil Bunda berhasil diperbarui.', style: TextStyle(color: Colors.white)),
          backgroundColor: _primaryBlue,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyambung ke server/terjadi kesalahan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        title: Text(
          'Edit Profil Ibu',
          style: TextStyle(
            color: _bgHitam,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceBg,
        iconTheme: IconThemeData(color: _bgHitam),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
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
                        Icon(Icons.info_outline, color: _primaryBlue, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan data Bunda valid agar rekomendasi MPASI & AI lebih akurat!',
                            style: TextStyle(color: _primaryBlue.withOpacity(0.9), fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Container Berbayang
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInputGroup(
                          'Nama Lengkap',
                          _nameController,
                          Icons.person_outline,
                          false,
                          hint: 'Masukkan nama lengkap',
                        ),
                        _buildInputGroup(
                          'Alamat Email',
                          _emailController,
                          Icons.email_outlined,
                          true, // Email biasanya tidak bisa diubah langsung
                          hint: 'Email Bunda',
                        ),
                        _buildInputGroup(
                          'Nomor Telepon',
                          _teleponController,
                          Icons.phone_outlined,
                          false,
                          type: TextInputType.phone,
                          hint: 'Contoh: 08123456789',
                        ),

                        // Tanggal Lahir (Dihitung ke Usia di background)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tanggal Lahir'),
                              TextFormField(
                                controller: _tglLahirController,
                                readOnly: true,
                                onTap: _pilihTanggal,
                                style: TextStyle(color: _bgHitam, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Pilih Tanggal',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  prefixIcon: Icon(Icons.calendar_today_outlined, color: _primaryBlue.withOpacity(0.7), size: 22),
                                  filled: true,
                                  fillColor: _inputBg,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryBlue, width: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildInputGroup(
                          'Tinggi Badan (cm)',
                          _tinggiController,
                          Icons.straighten_outlined,
                          false,
                          type: TextInputType.number,
                          hint: 'Masukkan tinggi badan',
                        ),

                        // Dropdown Pendidikan
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Pendidikan Terakhir'),
                              DropdownButtonFormField<String>(
                                value: _pendidikanPilih,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.school_outlined, color: _primaryBlue.withOpacity(0.7), size: 22),
                                  filled: true,
                                  fillColor: _inputBg,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryBlue, width: 1.5)),
                                ),
                                hint: Text('Pilih Pendidikan', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                style: TextStyle(color: _bgHitam, fontSize: 14),
                                items: ['SD', 'SMP', 'SMA', 'Diploma', 'S1', 'S2/S3'].map((String val) {
                                  return DropdownMenuItem(value: val, child: Text(val));
                                }).toList(),
                                onChanged: (val) => setState(() => _pendidikanPilih = val),
                              ),
                            ],
                          ),
                        ),

                        // Dropdown Pekerjaan
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Pekerjaan Saat Ini'),
                              DropdownButtonFormField<String>(
                                value: _pekerjaanPilih,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.work_outline, color: _primaryBlue.withOpacity(0.7), size: 22),
                                  filled: true,
                                  fillColor: _inputBg,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryBlue, width: 1.5)),
                                ),
                                hint: Text('Pilih Pekerjaan', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                style: TextStyle(color: _bgHitam, fontSize: 14),
                                items: ['Ibu Rumah Tangga', 'Karyawan Swasta', 'PNS / BUMN', 'Wiraswasta', 'Lainnya'].map((String val) {
                                  return DropdownMenuItem(value: val, child: Text(val));
                                }).toList(),
                                onChanged: (val) => setState(() => _pekerjaanPilih = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(
          color: _outlineColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInputGroup(
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool isReadOnly, {
    TextInputType type = TextInputType.text,
    String hint = '',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            readOnly: isReadOnly,
            style: TextStyle(
              color: isReadOnly ? _outlineColor : _bgHitam,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(
                icon,
                color: isReadOnly ? Colors.grey.shade400 : _primaryBlue.withOpacity(0.7),
                size: 22,
              ),
              filled: true,
              fillColor: isReadOnly ? Colors.grey.shade100 : _inputBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryBlue, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}