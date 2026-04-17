import 'package:flutter/material.dart';
import 'services/anak_service.dart';

class EditAnakPage extends StatefulWidget {
  final Map<String, dynamic> dataAnak; // Data warisan dari beranda
  const EditAnakPage({super.key, required this.dataAnak});

  @override
  State<EditAnakPage> createState() => _EditAnakPageState();
}

class _EditAnakPageState extends State<EditAnakPage> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaAnakController = TextEditingController();
  final TextEditingController _namaOrtuController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();
  final TextEditingController _tglPemeriksaanController =
      TextEditingController();
  final TextEditingController _bbLahirController = TextEditingController();
  final TextEditingController _tbLahirController = TextEditingController();
  final TextEditingController _bbSekarangController = TextEditingController();
  final TextEditingController _tbSekarangController = TextEditingController();

  String? _jenisKelamin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill formulir dengan data lama
    _nikController.text = widget.dataAnak['nik'] ?? '';
    _namaAnakController.text = widget.dataAnak['nama_anak'] ?? '';
    _namaOrtuController.text = widget.dataAnak['nama_ortu'] ?? '';
    _tglLahirController.text = widget.dataAnak['tgl_lahir'] ?? '';
    _tglPemeriksaanController.text = widget.dataAnak['tgl_pemeriksaan'] ?? '';
    _bbLahirController.text = widget.dataAnak['bb_lahir']?.toString() ?? '';
    _tbLahirController.text = widget.dataAnak['tb_lahir']?.toString() ?? '';
    _bbSekarangController.text =
        widget.dataAnak['berat_badan']?.toString() ?? '';
    _tbSekarangController.text =
        widget.dataAnak['tinggi_badan']?.toString() ?? '';

    String? jkLama = widget.dataAnak['jenis_kelamin'];
    if (jkLama == 'Laki-laki' || jkLama == 'Perempuan') {
      _jenisKelamin = jkLama;
    }
  }

  Future<void> _pilihTanggal(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? tanggalDipilih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
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

  void _prosesEdit() async {
    if (_nikController.text.isEmpty ||
        _namaAnakController.text.isEmpty ||
        _namaOrtuController.text.isEmpty ||
        _tglLahirController.text.isEmpty ||
        _jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selesaikan isian wajib ya Bunda!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> dataKirim = {
      'nik': _nikController.text,
      'nama_anak': _namaAnakController.text,
      'nama_ortu': _namaOrtuController.text,
      'jenis_kelamin': _jenisKelamin,
      'tgl_lahir': _tglLahirController.text,
      'tgl_pemeriksaan': _tglPemeriksaanController.text,
      'bb_lahir': double.tryParse(_bbLahirController.text) ?? 0,
      'tb_lahir': double.tryParse(_tbLahirController.text) ?? 0,
      'berat_badan': double.tryParse(_bbSekarangController.text) ?? 0,
      'tinggi_badan': double.tryParse(_tbSekarangController.text) ?? 0,
    };

    // Mengambil ID dari database Mongo, mengantisipasi default key id/ _id
    String idAnak =
        widget.dataAnak['_id']?.toString() ??
        widget.dataAnak['id']?.toString() ??
        '';

    bool sukses = await AnakService().editData(idAnak, dataKirim);

    setState(() => _isLoading = false);

    if (sukses) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data anak berhasil diperbarui!'),
          backgroundColor: Color(0xFFBFDBFE),
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui data, server bermasalah.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Data Anak',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Perbarui informasi anak jika ada perubahan atau kesalahan ketik sebelumnya.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

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

            _buildLabel('Nama Orang Tua (Ibu/Ayah)'),
            _buildTextField(
              _namaOrtuController,
              'Contoh: Siti Aminah',
              TextInputType.name,
            ),

            _buildLabel('Jenis Kelamin'),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
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
              onChanged: (newValue) => setState(() => _jenisKelamin = newValue),
            ),
            const SizedBox(height: 15),

            _buildLabel('Tanggal Lahir'),
            _buildDateTextField(
              _tglLahirController,
              'Pilih Tanggal Lahir Anak',
              context,
            ),

            _buildLabel('Tanggal Terakhir Pemeriksaan (Posyandu)'),
            _buildDateTextField(
              _tglPemeriksaanController,
              'Pilih Tanggal Pemeriksaan',
              context,
            ),

            Row(
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

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _prosesEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
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
      padding: const EdgeInsets.only(bottom: 8.0, top: 15.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
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
        prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF2563EB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
