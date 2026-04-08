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
  // final TextEditingController _passwordController = TextEditingController(); // Kita pindah sandi ke menu utamanya

  // Controller Profil Kesehatan (ibu table)
  final TextEditingController _usiaController = TextEditingController();
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
          _usiaController.text = dataIbu['usia_ibu']?.toString() ?? '';
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

  Future<void> _updateProfil() async {
    setState(() => _isSaving = true);
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      Map<String, dynamic> payloadAkun = {
        'name': _nameController.text,
        'email': _emailController.text,
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
          'usia_ibu': int.tryParse(_usiaController.text) ?? 0,
          'tinggi_ibu': double.tryParse(_tinggiController.text) ?? 0,
          'pendidikan_ibu': _pendidikanPilih ?? '',
          'pekerjaan_ibu': _pekerjaanPilih ?? '',
        }),
      );

      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hore! Seluruh Profil Bunda berhasil diperbarui.'), backgroundColor: Colors.green));
      Navigator.pop(context, true); // Kembali & beritahu data berubah
      
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyambung ke server/terjadi kesalahan.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profil Lengkap', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                _buildLabel('Data Login Akun', warna: primaryColor),
                _buildTextField(_nameController, Icons.person_outline, primaryColor, 'Nama Lengkap'),
                const SizedBox(height: 15),
                _buildTextField(_emailController, Icons.email_outlined, primaryColor, 'Alamat Email (Digunakan untuk Login)'),
                
                const SizedBox(height: 30),
                _buildLabel('Data Kesehatan Ibu', warna: Colors.orange),

                _buildTextField(_usiaController, Icons.cake, Colors.orange, 'Usia Saat Ini (Tahun)', type: TextInputType.number),
                const SizedBox(height: 15),
                _buildTextField(_tinggiController, Icons.straighten, Colors.orange, 'Tinggi Badan (Cm)', type: TextInputType.number),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.school, color: Colors.orange),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  value: _pendidikanPilih,
                  hint: const Text('Pendidikan Terakhir'),
                  items: ['SD', 'SMP', 'SMA', 'Diploma', 'S1', 'S2/S3'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _pendidikanPilih = val),
                ),
                const SizedBox(height: 15),
                
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.work, color: Colors.orange),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  value: _pekerjaanPilih,
                  hint: const Text('Pekerjaan Saat Ini'),
                  items: ['Ibu Rumah Tangga', 'Karyawan Swasta', 'PNS / BUMN', 'Wiraswasta', 'Lainnya'].map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _pekerjaanPilih = val),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _updateProfil,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                    label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Semua Perubahan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLabel(String teks, {Color? warna}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Align(alignment: Alignment.centerLeft, child: Text(teks, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: warna))),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, IconData ikon, Color wrn, String hint, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(ikon, color: wrn),
        filled: true, fillColor: Colors.white,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
