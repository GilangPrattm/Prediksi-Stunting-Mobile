import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/anak_service.dart';
import 'config/api_config.dart';

class TambahAnakPage extends StatefulWidget {
  const TambahAnakPage({super.key});

  @override
  State<TambahAnakPage> createState() => _TambahAnakPageState();
}

class _TambahAnakPageState extends State<TambahAnakPage> {
  // --- STATE UNTUK 2 TAMPILAN (STEPPER) ---
  int _currentStep = 1; // 1 = Form Ibu, 2 = Form Anak
  bool _isLoading = false;

  // --- TEMA WARNA SESUAI DESAIN ---
  final Color _bgSurface = const Color(0xFFF8F9FF);
  final Color _cardBg = const Color(0xFFFFFFFF);
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _textMain = const Color(0xFF0B1C30);
  final Color _textOutline = const Color(0xFF717785);
  final Color _inputBg = const Color(0xFFF8F9FF); // surface-bright

  // ==========================================
  // CONTROLLER FORM IBU
  // ==========================================
  final TextEditingController _namaIbuController = TextEditingController();
  final TextEditingController _emailIbuController = TextEditingController();
  final TextEditingController _telpIbuController = TextEditingController();
  final TextEditingController _tglLahirIbuController = TextEditingController();
  final TextEditingController _tbIbuController = TextEditingController();
  String? _pendidikanIbu;
  String? _pekerjaanIbu;

  // ==========================================
  // CONTROLLER FORM ANAK
  // ==========================================
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _namaAnakController = TextEditingController();
  final TextEditingController _tglLahirAnakController = TextEditingController();
  final TextEditingController _tglPemeriksaanController =
      TextEditingController();
  final TextEditingController _tbLahirController = TextEditingController();
  final TextEditingController _tbSekarangController = TextEditingController();
  String? _jenisKelaminAnak;

  @override
  void initState() {
    super.initState();
    _fetchDataIbuAwal();
  }

  // Mengambil data awal user (jika ada) untuk pre-fill
  Future<void> _fetchDataIbuAwal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (mounted) {
          setState(() {
            _namaIbuController.text = data['name'] ?? '';
            _emailIbuController.text = data['email'] ?? '';
            _telpIbuController.text = data['no_hp'] ?? '';
          });
        }
      }
    } catch (e) {
      print("Gagal fetch data awal: $e");
    }
  }

  // Fungsi Pemilihan Tanggal Global (Bisa dipakai Ibu & Anak)
  Future<void> _pilihTanggal(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? tanggalDipilih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              onSurface: _textMain,
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

  // Lanjut dari Form Ibu ke Form Anak
  void _lanjutKeDataAnak() {
    if (_namaIbuController.text.isEmpty ||
        _tglLahirIbuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mohon lengkapi Nama dan Tanggal Lahir Bunda terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _currentStep = 2; // Pindah ke layar 2
    });
  }

  // Kembali dari Form Anak ke Form Ibu
  void _kembaliKeDataIbu() {
    setState(() {
      _currentStep = 1;
    });
  }

  // Fungsi Final: Simpan Semua Data (Fokus utamanya simpan anak dari kodemu sebelumnya)
  void _prosesSimpanFinal() async {
    if (_nikController.text.isEmpty ||
        _namaAnakController.text.isEmpty ||
        _tglLahirAnakController.text.isEmpty ||
        _jenisKelaminAnak == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selesaikan isian Identitas Anak secara lengkap ya Bunda!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    int calculatedUsiaIbu = 0;
    if (_tglLahirIbuController.text.isNotEmpty) {
      try {
        DateTime dob = DateTime.parse(_tglLahirIbuController.text);
        DateTime now = DateTime.now();
        calculatedUsiaIbu = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calculatedUsiaIbu--;
        }
      } catch (e) {
        print("Error parsing tgl lahir ibu: $e");
      }
    }

    // STEP 1: Simpan data ibu ke collection profil_ibus
    Map<String, dynamic> dataKirimIbu = {
      'nama_ibu': _namaIbuController.text,
      'usia_ibu': calculatedUsiaIbu,
      'tinggi_ibu': double.tryParse(_tbIbuController.text) ?? 0,
      'pendidikan_ibu': _pendidikanIbu ?? '',
      'pekerjaan_ibu': _pekerjaanIbu ?? '',
    };

    bool suksesSimpanIbu = await AnakService().simpanDataIbu(dataKirimIbu);

    if (!suksesSimpanIbu) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data ibu. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // STEP 2: Jika data ibu sukses, simpan data anak
    Map<String, dynamic> dataKirimAnak = {
      'nik': _nikController.text,
      'nama_anak': _namaAnakController.text,
      'nama_ortu': _namaIbuController.text, // Diambil dari inputan form Ibu
      'jenis_kelamin': _jenisKelaminAnak,
      'tgl_lahir': _tglLahirAnakController.text,
      'tgl_pemeriksaan': _tglPemeriksaanController.text,
      'tb_lahir': double.tryParse(_tbLahirController.text) ?? 0,
      'tinggi_badan': double.tryParse(_tbSekarangController.text) ?? 0,
    };

    bool sukses = await AnakService().simpanData(dataKirimAnak);

    setState(() => _isLoading = false);

    if (sukses) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Kembali ke Home
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSurface,
      appBar: AppBar(
        backgroundColor: _bgSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textMain),
          onPressed: () {
            if (_currentStep == 2) {
              _kembaliKeDataIbu(); // Jika di step 2, back button kembali ke step 1
            } else {
              Navigator.pop(context); // Jika di step 1, keluar halaman
            }
          },
        ),
        title: Text(
          _currentStep == 1 ? 'Lengkapi Data Ibu' : 'Lengkapi Data Anak',
          style: TextStyle(
            color: _textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // INDICATOR STEPPER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Langkah $_currentStep dari 2',
                  style: TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      height: 8,
                      width: _currentStep >= 1 ? 32 : 16,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1
                            ? _primaryBlue
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 8,
                      width: _currentStep == 2 ? 32 : 16,
                      decoration: BoxDecoration(
                        color: _currentStep == 2
                            ? _primaryBlue
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              // AnimatedSwitcher untuk transisi halus antara Form Ibu dan Form Anak
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 1 ? _buildFormIbu() : _buildFormAnak(),
              ),
            ),
          ),

          // BOTTOM BUTTON
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgSurface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_currentStep == 1
                          ? _lanjutKeDataAnak
                          : _prosesSimpanFinal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 1
                                ? 'Lanjut ke Data Anak'
                                : 'Simpan Semua Data',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_currentStep == 1) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET TAMPILAN 1: FORM IBU
  // ==========================================
  Widget _buildFormIbu() {
    return Column(
      key: const ValueKey('form_ibu'),
      children: [
        _buildInfoBanner(
          'Pastikan data Bunda valid agar rekomendasi MPASI & AI lebih akurat!',
          Icons.info_outline,
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nama Lengkap'),
              _buildCustomTextField(
                _namaIbuController,
                'Masukkan nama lengkap',
                Icons.person_outline,
              ),

              _buildLabel('Alamat Email'),
              _buildCustomTextField(
                _emailIbuController,
                'Email',
                Icons.mail_outline,
                isReadOnly: true,
              ),

              _buildLabel('Nomor Telepon'),
              _buildCustomTextField(
                _telpIbuController,
                'Contoh: 08123456789',
                Icons.call_outlined,
                inputType: TextInputType.phone,
                isReadOnly: true,
              ),

              _buildLabel('Tanggal Lahir'),
              _buildDateTextField(
                _tglLahirIbuController,
                'Pilih Tanggal',
                context,
              ),

              _buildLabel('Tinggi Badan (cm)'),
              _buildCustomTextField(
                _tbIbuController,
                'Masukkan tinggi badan',
                Icons.straighten,
                inputType: TextInputType.number,
              ),

              _buildLabel('Pendidikan Terakhir'),
              _buildCustomDropdown(
                value: _pendidikanIbu,
                hint: 'Pilih Pendidikan',
                icon: Icons.school_outlined,
                items: ['SMA/Sederajat', 'D3', 'S1', 'S2', 'Lainnya'],
                onChanged: (val) => setState(() => _pendidikanIbu = val),
              ),

              _buildLabel('Pekerjaan Saat Ini'),
              _buildCustomDropdown(
                value: _pekerjaanIbu,
                hint: 'Pilih Pekerjaan',
                icon: Icons.work_outline,
                items: [
                  'Ibu Rumah Tangga',
                  'Karyawan Swasta',
                  'PNS',
                  'Wirausaha',
                  'Lainnya',
                ],
                onChanged: (val) => setState(() => _pekerjaanIbu = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET TAMPILAN 2: FORM ANAK
  // ==========================================
  Widget _buildFormAnak() {
    return Column(
      key: const ValueKey('form_anak'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          'Pastikan data disalin dengan benar dari Buku KIA ya Bunda agar Kila AI bisa memantau.',
          Icons.stars,
        ),
        const SizedBox(height: 20),

        // SECTION 1: IDENTITAS ANAK
        Text(
          '1. Identitas Anak',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _textMain,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _primaryBlue.withOpacity(0.05), blurRadius: 15),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('NIK Anak'),
              _buildCustomTextField(
                _nikController,
                'Contoh: 3509xxxxxxxxxxxx',
                Icons.badge_outlined,
                inputType: TextInputType.number,
              ),

              _buildLabel('Nama Lengkap Anak'),
              _buildCustomTextField(
                _namaAnakController,
                'Contoh: Budi Kusuma',
                Icons.child_care,
              ),

              _buildLabel('Jenis Kelamin'),
              _buildCustomDropdown(
                value: _jenisKelaminAnak,
                hint: 'Pilih Jenis Kelamin',
                icon: Icons.wc_outlined,
                items: ['Laki-laki', 'Perempuan'],
                onChanged: (val) => setState(() => _jenisKelaminAnak = val),
              ),

              _buildLabel('Tanggal Lahir'),
              _buildDateTextField(
                _tglLahirAnakController,
                'Pilih Tanggal Lahir',
                context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION 2: DATA KELAHIRAN
        Text(
          '2. Data Kelahiran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _textMain,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _primaryBlue.withOpacity(0.05), blurRadius: 15),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TB Lahir (cm)'),
                    _buildCustomTextField(
                      _tbLahirController,
                      'Misal: 49',
                      Icons.height_outlined,
                      inputType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION 3: PEMERIKSAAN POSYANDU
        Text(
          '3. Pemeriksaan Terakhir di Posyandu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _textMain,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _primaryBlue.withOpacity(0.05), blurRadius: 15),
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
                        _buildLabel('TB Saat Ini (cm)'),
                        _buildCustomTextField(
                          _tbSekarangController,
                          'Misal: 82',
                          Icons.straighten_outlined,
                          inputType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET REUSABLE (Agar Kode Rapi & Bersih)
  // ==========================================

  Widget _buildInfoBanner(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE9FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _textMain, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 16.0),
      child: Text(
        text,
        style: TextStyle(
          color: _textOutline,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isReadOnly = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: inputType,
      style: TextStyle(
        color: isReadOnly ? _textOutline : _textMain,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(
          icon,
          color: isReadOnly ? _textOutline : _primaryBlue.withOpacity(0.7),
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
      style: TextStyle(color: _textMain, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(
          Icons.calendar_today_outlined,
          color: _primaryBlue.withOpacity(0.7),
          size: 22,
        ),
        filled: true,
        fillColor: _inputBg,
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
    );
  }

  Widget _buildCustomDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primaryBlue.withOpacity(0.7), size: 22),
        filled: true,
        fillColor: _inputBg,
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
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      style: TextStyle(color: _textMain, fontSize: 14),
      items: items.map((String val) {
        return DropdownMenuItem<String>(value: val, child: Text(val));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
