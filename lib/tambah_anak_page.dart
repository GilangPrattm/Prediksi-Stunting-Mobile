import 'package:flutter/material.dart';
import 'services/anak_service.dart';

class TambahAnakPage extends StatefulWidget {
  const TambahAnakPage({super.key});

  @override
  State<TambahAnakPage> createState() => _TambahAnakPageState();
}

class _TambahAnakPageState extends State<TambahAnakPage> {
  // Controller untuk menangkap inputan sesuai Model Anak.php
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaAnakController = TextEditingController();
  final TextEditingController _namaOrtuController = TextEditingController(
    text: 'Terisi otomatis',
  );
  final TextEditingController _tglLahirController = TextEditingController();
  final TextEditingController _tglPemeriksaanController =
      TextEditingController();
  final TextEditingController _bbLahirController = TextEditingController();
  final TextEditingController _tbLahirController = TextEditingController();
  final TextEditingController _bbSekarangController = TextEditingController();
  final TextEditingController _tbSekarangController = TextEditingController();

  String? _jenisKelamin; // Untuk dropdown Laki-laki / Perempuan
  bool _isLoading = false; // Variabel penanda efek loading

  // Fungsi Bantuan Untuk Memilih Tanggal Pakai Google Kalender Popup
  Future<void> _pilihTanggal(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? tanggalDipilih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Paling mundur tahun 2000
      lastDate: DateTime.now(), // Tidak bisa milih tanggal masa depan
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBFDBFE), // Warna header kalendernya Light Blue
              onPrimary: Color(0xFF1E293B),
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (tanggalDipilih != null) {
      setState(() {
        controller.text =
            "${tanggalDipilih.year}-${tanggalDipilih.month.toString().padLeft(2, '0')}-${tanggalDipilih.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Fungsi Utama untuk Menyimpan Data ke Laravel
  void _prosesSimpan() async {
    // Validasi ketat: Cegah user nyimpan kalau ada isian wajib yang kosong
    if (_nikController.text.isEmpty ||
        _namaAnakController.text.isEmpty ||
        _tglLahirController.text.isEmpty ||
        _jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selesaikan isian Identitas Anak seperti NIK, Nama, Tanggal Lahir, & Jenis Kelamin ya Bunda!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> dataKirim = {
      'nik': _nikController.text,
      'nama_anak': _namaAnakController.text,
      'nama_ortu': _namaOrtuController.text == 'Terisi otomatis'
          ? ''
          : _namaOrtuController.text,
      'jenis_kelamin': _jenisKelamin,
      'tgl_lahir': _tglLahirController.text,
      'tgl_pemeriksaan': _tglPemeriksaanController.text,
      'bb_lahir': double.tryParse(_bbLahirController.text) ?? 0,
      'tb_lahir': double.tryParse(_tbLahirController.text) ?? 0,
      'berat_badan': double.tryParse(_bbSekarangController.text) ?? 0,
      'tinggi_badan': double.tryParse(_tbSekarangController.text) ?? 0,
    };

    // Panggil kurir AnakService untuk bawa data ke Laravel
    bool sukses = await AnakService().simpanData(dataKirim);

    setState(() => _isLoading = false);

    if (sukses) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data anak sukses ditambahkan!'),
          backgroundColor: Color(0xFFBFDBFE),
        ),
      );
      // Tutup halaman ini dan kembali ke HomePage
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data, pastikan server merespons.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFBFDBFE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tambah Data Anak',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kotak Informasi
                  Container(
                    margin: const EdgeInsets.only(bottom: 25),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF1E293B)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pastikan data disalin dengan benar dari Buku KIA ya Bunda agar Kila AI bisa memantau.',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CARD 1: IDENTITAS ANAK
                  const Text(
                    '1. Identitas Anak',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('NIK Anak'),
                        _buildTextField(
                          _nikController,
                          'Contoh: 3509xxxxxxxxxxxx',
                          TextInputType.number,
                        ),

                        _buildLabel('Nama Lengkap Anak'),
                        _buildTextField(
                          _namaAnakController,
                          'Contoh: Budi Kusuma',
                          TextInputType.name,
                        ),

                        _buildLabel('Nama Orang Tua'),
                        _buildReadOnlyField(
                          _namaOrtuController,
                          Icons.person_outline,
                        ),

                        _buildLabel('Jenis Kelamin'),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(
                              Icons.wc,
                              color: Color(0xFF1E293B),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          hint: const Text('Pilih Jenis Kelamin'),
                          initialValue: _jenisKelamin,
                          items: ['Laki-laki', 'Perempuan'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) =>
                              setState(() => _jenisKelamin = newValue),
                        ),

                        _buildLabel('Tanggal Lahir'),
                        _buildDateTextField(
                          _tglLahirController,
                          'Pilih Tanggal Lahir',
                          context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // CARD 2: DATA KELAHIRAN
                  const Text(
                    '2. Data Kelahiran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('BB Lahir (kg)'),
                              _buildTextField(
                                _bbLahirController,
                                'Misal: 3.2',
                                TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('TB Lahir (cm)'),
                              _buildTextField(
                                _tbLahirController,
                                'Misal: 49',
                                TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // CARD 3: PEMERIKSAAN TERAKHIR
                  const Text(
                    '3. Pemeriksaan Terakhir di Posyandu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tanggal Terakhir Periksa'),
                        _buildDateTextField(
                          _tglPemeriksaanController,
                          'Pilih Tanggal',
                          context,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('BB Saat Ini (kg)'),
                                  _buildTextField(
                                    _bbSekarangController,
                                    'Misal: 10.5',
                                    TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('TB Saat Ini (cm)'),
                                  _buildTextField(
                                    _tbSekarangController,
                                    'Misal: 82',
                                    TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Fixed Bottom Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _prosesSimpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF1E293B))
                    : const Text(
                        'Simpan Data Anak',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Bantuan
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 15.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType type,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: TextStyle(color: Colors.grey.shade500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1E293B)),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDateTextField(
    TextEditingController controller,
    String hint,
    BuildContext context,
  ) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pilihTanggal(context, controller),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF1E293B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
