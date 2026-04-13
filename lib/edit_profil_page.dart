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
  final TextEditingController _teleponController = TextEditingController(); // Dummy UI only
  final TextEditingController _tinggiController = TextEditingController();
  String? _pendidikanPilih;
  String? _pekerjaanPilih;

  bool _isLoading = true;
  bool _isSaving = false;

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
      final responseAkun = await http.get(Uri.parse('$_baseUrl/profil'), headers: {'Authorization': 'Bearer $token'});
      final responseIbu = await http.get(Uri.parse('$_baseUrl/profil-ibu'), headers: {'Authorization': 'Bearer $token'});

      if (responseAkun.statusCode == 200) {
        final dataAkun = jsonDecode(responseAkun.body)['data'];
        setState(() {
          _nameController.text = dataAkun['name'] ?? '';
          _emailController.text = dataAkun['email'] ?? '';
        });
      }

      if (responseIbu.statusCode == 200) {
        final dataIbu = jsonDecode(responseIbu.body)['data'];
        setState(() {
          int usia = dataIbu['usia_ibu'] ?? 0;
          if (usia > 0) {
             int birthYear = DateTime.now().year - usia;
             _tglLahirController.text = "$birthYear-01-01"; // Estimasi Tgl Lahir
          }
          _tinggiController.text = dataIbu['tinggi_ibu']?.toString() ?? '';
          _pendidikanPilih = dataIbu['pendidikan_ibu'];
          _pekerjaanPilih = dataIbu['pekerjaan_ibu'];
        });
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D9488),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _tglLahirController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateProfil() async {
    setState(() => _isSaving = true);
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    int calculatedUsia = 0;
    if (_tglLahirController.text.isNotEmpty) {
      DateTime dob = DateTime.parse(_tglLahirController.text);
      DateTime now = DateTime.now();
      calculatedUsia = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        calculatedUsia--;
      }
    }

    try {
      Map<String, dynamic> payloadAkun = {
        'name': _nameController.text,
        'email': _emailController.text, // Email biasanya dikunci dari Backend juga, tapi kita sertakan
      };

      await http.put(
        Uri.parse('$_baseUrl/profil'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(payloadAkun),
      );

      await http.post(
        Uri.parse('$_baseUrl/profil-ibu'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'usia_ibu': calculatedUsia,
          'tinggi_ibu': double.tryParse(_tinggiController.text) ?? 0,
          'pendidikan_ibu': _pendidikanPilih ?? '',
          'pekerjaan_ibu': _pekerjaanPilih ?? '',
        }),
      );

      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hore! Seluruh Profil Bunda berhasil diperbarui.'), backgroundColor: Colors.green));
      Navigator.pop(context, true); 
      
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyambung ke server/terjadi kesalahan.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D9488); // Teal Color

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Profil Ibu', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade400, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Pastikan data Bunda valid agar rekomendasi MPASI & AI lebih akurat!', style: TextStyle(color: Colors.blue, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Container Berbayang
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      _buildInputGroup('Nama Lengkap', _nameController, Icons.person_outline, false),
                      _buildInputGroup('Alamat Email', _emailController, Icons.email_outlined, true),
                      _buildInputGroup('Nomor Telepon', _teleponController, Icons.phone_outlined, false, type: TextInputType.phone),
                      
                      // Tanggal Lahir (Dihitung ke Usia di background)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Lahir', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _tglLahirController,
                              readOnly: true,
                              onTap: _pilihTanggal,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_month, color: primaryColor),
                                filled: true, fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      _buildInputGroup('Tinggi Badan (cm)', _tinggiController, Icons.straighten_outlined, false, type: TextInputType.number),
                      
                      // Dropdown Pendidikan
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pendidikan Terakhir', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.school_outlined, color: primaryColor),
                                filled: true, fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              value: _pendidikanPilih,
                              hint: const Text('Pilih Pendidikan'),
                              items: ['SD', 'SMP', 'SMA', 'Diploma', 'S1', 'S2/S3'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                              onChanged: (val) => setState(() => _pendidikanPilih = val),
                            ),
                          ],
                        ),
                      ),

                      // Dropdown Pekerjaan
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pekerjaan Saat Ini', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.work_outline, color: primaryColor),
                                filled: true, fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              value: _pekerjaanPilih,
                              hint: const Text('Pilih Pekerjaan'),
                              items: ['Ibu Rumah Tangga', 'Karyawan Swasta', 'PNS / BUMN', 'Wiraswasta', 'Lainnya'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
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
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildInputGroup(String label, TextEditingController ctrl, IconData icon, bool isReadOnly, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            readOnly: isReadOnly,
            style: TextStyle(color: isReadOnly ? Colors.grey.shade500 : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey.shade400 : const Color(0xFF0D9488)),
              filled: true, 
              fillColor: isReadOnly ? Colors.grey.shade200 : Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
