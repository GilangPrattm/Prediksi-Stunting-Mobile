import 'package:flutter/material.dart';
// PASTIKAN letak import anak_service.dart ini sudah benar sesuai folder proyekmu ya!
import 'services/anak_service.dart'; 

class TambahAnakPage extends StatefulWidget {
  const TambahAnakPage({super.key});

  @override
  State<TambahAnakPage> createState() => _TambahAnakPageState();
}

class _TambahAnakPageState extends State<TambahAnakPage> {
  // 1. Controller untuk menangkap inputan sesuai Model Anak.php
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaAnakController = TextEditingController();
  final TextEditingController _namaOrtuController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();
  final TextEditingController _bbLahirController = TextEditingController();
  final TextEditingController _tbLahirController = TextEditingController();
  final TextEditingController _bbSekarangController = TextEditingController();
  final TextEditingController _tbSekarangController = TextEditingController();
  
  String? _jenisKelamin; // Untuk dropdown Laki-laki / Perempuan
  bool _isLoading = false; // Variabel penanda efek loading

  // 2. Fungsi Utama untuk Menyimpan Data ke Laravel
  void _prosesSimpan() async {
    // Validasi singkat: Cegah user nyimpan kalau nama anak atau jenis kelamin kosong
    if (_namaAnakController.text.isEmpty || _jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama anak dan Jenis Kelamin wajib diisi Bunda!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true); // Nyalakan animasi muter-muter

    // Bungkus data sesuai nama kolom di Model Anak.php Laravel-mu
    Map<String, dynamic> dataKirim = {
      'nik': _nikController.text,
      'nama_anak': _namaAnakController.text,
      'nama_ortu': _namaOrtuController.text,
      'jenis_kelamin': _jenisKelamin,
      'tgl_lahir': _tglLahirController.text,
      // Konversi string ke angka desimal (double). Kalau dikosongin sama user, otomatis jadi 0
      'bb_lahir': double.tryParse(_bbLahirController.text) ?? 0,
      'tb_lahir': double.tryParse(_tbLahirController.text) ?? 0,
      'berat_badan': double.tryParse(_bbSekarangController.text) ?? 0,
      'tinggi_badan': double.tryParse(_tbSekarangController.text) ?? 0,
    };

    // Panggil kurir AnakService untuk bawa data ke Laravel
    bool sukses = await AnakService().simpanData(dataKirim);

    setState(() => _isLoading = false); // Matikan animasi muter-muter

    if (sukses) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data anak berhasil disimpan!'), backgroundColor: Colors.green),
      );
      // Tutup halaman ini dan kembali ke HomePage
      Navigator.pop(context); 
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan data, pastikan server Laravel menyala.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF009888);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tambah Data Anak', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotak Informasi
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(child: Text('Pastikan data yang diisi sesuai dengan buku KIA ya Bunda.', style: TextStyle(color: Colors.blue, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Form Inputan
            _buildLabel('NIK Anak'),
            _buildTextField(_nikController, 'Contoh: 3509xxxxxxxxxxxx', TextInputType.number),
            
            _buildLabel('Nama Lengkap Anak'),
            _buildTextField(_namaAnakController, 'Contoh: Budi Kusuma', TextInputType.name),

            _buildLabel('Nama Orang Tua (Ibu/Ayah)'),
            _buildTextField(_namaOrtuController, 'Contoh: Siti Aminah', TextInputType.name),

            _buildLabel('Jenis Kelamin'),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              hint: const Text('Pilih Jenis Kelamin'),
              value: _jenisKelamin,
              items: ['Laki-laki', 'Perempuan'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) {
                setState(() => _jenisKelamin = newValue);
              },
            ),
            const SizedBox(height: 15),

            _buildLabel('Tanggal Lahir (YYYY-MM-DD)'),
            _buildTextField(_tglLahirController, 'Contoh: 2023-05-14', TextInputType.datetime),

            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('BB Lahir (kg)'),
                    _buildTextField(_bbLahirController, 'Misal: 3.2', TextInputType.number),
                  ],
                )),
                const SizedBox(width: 15),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TB Lahir (cm)'),
                    _buildTextField(_tbLahirController, 'Misal: 49', TextInputType.number),
                  ],
                )),
              ],
            ),

            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('BB Saat Ini (kg)'),
                    _buildTextField(_bbSekarangController, 'Misal: 10.5', TextInputType.number),
                  ],
                )),
                const SizedBox(width: 15),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TB Saat Ini (cm)'),
                    _buildTextField(_tbSekarangController, 'Misal: 82', TextInputType.number),
                  ],
                )),
              ],
            ),

            const SizedBox(height: 30),
            
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                // Tombol mati kalau lagi loading
                onPressed: _isLoading ? null : _prosesSimpan, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan Data Anak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Bantuan biar kodingan UI nggak kepanjangan
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 15.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}