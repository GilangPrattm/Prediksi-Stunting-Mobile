import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'widgets/colorful_icon.dart';
import 'config/api_config.dart';
import 'hasil_prediksi_page.dart';

class CekStuntingPage extends StatefulWidget {
  final bool isIbuDataComplete;
  final List<dynamic> daftarAnak;

  const CekStuntingPage({
    super.key,
    this.isIbuDataComplete = false,
    this.daftarAnak = const [],
  });

  @override
  State<CekStuntingPage> createState() => _CekStuntingPageState();
}

class _CekStuntingPageState extends State<CekStuntingPage> {
  late PageController _pageController;
  int _currentStep = 0;
  bool _isLoading = false;

  bool get _isSimplifiedMode => widget.daftarAnak.isNotEmpty;
  dynamic _selectedAnak;

  // Global Keys for Form Validation
  final _formKeyIbu = GlobalKey<FormState>();
  final _formKeyAnak = GlobalKey<FormState>();

  // Controllers - Ibu
  final TextEditingController _namaIbuCtrl = TextEditingController();
  final TextEditingController _tglLahirIbuCtrl = TextEditingController();
  final TextEditingController _umurIbuCtrl = TextEditingController();
  final TextEditingController _tinggiIbuCtrl = TextEditingController();
  String? _pendidikanIbu;
  String? _pekerjaanIbu;
  DateTime? _tglLahirIbu;
  int _usiaIbu = 0;

  // Controllers - Anak
  final TextEditingController _nikCtrl = TextEditingController();
  final TextEditingController _namaAnakCtrl = TextEditingController();
  final TextEditingController _tglLahirAnakCtrl = TextEditingController();
  final TextEditingController _umurAnakCtrl = TextEditingController();
  final TextEditingController _tglPemeriksaanCtrl = TextEditingController();
  final TextEditingController _bbLahirCtrl = TextEditingController();
  final TextEditingController _tbLahirCtrl = TextEditingController();
  final TextEditingController _beratCtrl = TextEditingController();
  final TextEditingController _tinggiCtrl = TextEditingController();
  String? _jenisKelaminAnak;
  DateTime? _tglLahirAnak;
  DateTime? _tglPemeriksaan;
  int _totalBulanAnak = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    if (_isSimplifiedMode) {
      _selectedAnak = widget.daftarAnak[0];
      _tglLahirAnak = DateTime.parse(_selectedAnak['tgl_lahir']);
      _tglPemeriksaan = DateTime.now();
      _tglPemeriksaanCtrl.text = _formatDate(_tglPemeriksaan!);
      _hitungUmurDinamis();
    } else {
      _currentStep = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _namaIbuCtrl.dispose();
    _tglLahirIbuCtrl.dispose();
    _umurIbuCtrl.dispose();
    _tinggiIbuCtrl.dispose();
    _nikCtrl.dispose();
    _namaAnakCtrl.dispose();
    _tglLahirAnakCtrl.dispose();
    _umurAnakCtrl.dispose();
    _tglPemeriksaanCtrl.dispose();
    _bbLahirCtrl.dispose();
    _tbLahirCtrl.dispose();
    _beratCtrl.dispose();
    _tinggiCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _hitungUmurDinamis() {
    if (_tglLahirAnak == null || _tglPemeriksaan == null) return;

    int totalMonths =
        (_tglPemeriksaan!.year - _tglLahirAnak!.year) * 12 +
        _tglPemeriksaan!.month -
        _tglLahirAnak!.month;
    int days = _tglPemeriksaan!.day - _tglLahirAnak!.day;

    if (days < 0) {
      totalMonths--;
      final lastDay = DateTime(
        _tglPemeriksaan!.year,
        _tglPemeriksaan!.month,
        0,
      );
      days += lastDay.day;
    }

    if (totalMonths < 0) totalMonths = 0;
    _totalBulanAnak = totalMonths;

    String umurText;
    if (totalMonths >= 12) {
      int years = totalMonths ~/ 12;
      int remainingMonths = totalMonths % 12;
      umurText = '$years tahun $remainingMonths bulan $days hari';
    } else {
      umurText = '$totalMonths bulan $days hari';
    }
    _umurAnakCtrl.text = umurText;
  }

  Future<void> _pilihTanggalLahirIbu() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _tglLahirIbu = picked;
        _tglLahirIbuCtrl.text = _formatDate(picked);

        DateTime today = DateTime.now();
        int years = today.year - picked.year;
        int months = today.month - picked.month;

        if (today.day < picked.day) {
          months--;
        }
        if (months < 0) {
          years--;
          months += 12;
        }

        _usiaIbu = years;
        _umurIbuCtrl.text = '$years tahun $months bulan';
      });
    }
  }

  Future<void> _pilihTanggalLahirAnak() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _tglLahirAnak = picked;
        _tglLahirAnakCtrl.text = _formatDate(picked);

        int totalMonths =
            (now.year - picked.year) * 12 + now.month - picked.month;
        int days = now.day - picked.day;

        if (days < 0) {
          totalMonths--;
          final lastDay = DateTime(now.year, now.month, 0);
          days += lastDay.day;
        }

        if (totalMonths < 0) totalMonths = 0;
        _totalBulanAnak = totalMonths;

        String umurText;
        if (totalMonths >= 12) {
          int years = totalMonths ~/ 12;
          int remainingMonths = totalMonths % 12;
          umurText = '$years tahun $remainingMonths bulan $days hari';
        } else {
          umurText = '$totalMonths bulan $days hari';
        }

        _umurAnakCtrl.text = umurText;

        if (_tglPemeriksaan != null && _tglPemeriksaan!.isBefore(picked)) {
          _tglPemeriksaan = null;
          _tglPemeriksaanCtrl.clear();
        }
      });
    }
  }

  Future<void> _pilihTanggalPemeriksaan() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tglPemeriksaan ?? now,
      firstDate: _tglLahirAnak ?? now.subtract(const Duration(days: 365 * 5)),
      lastDate: now, // Realtime means up to today
    );
    if (picked != null) {
      setState(() {
        _tglPemeriksaan = picked;
        _tglPemeriksaanCtrl.text = _formatDate(picked);
        _hitungUmurDinamis(); // Update umur anak secara realtime
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKeyIbu.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      if (_formKeyAnak.currentState!.validate()) {
        _simpanKeDatabse();
      }
    }
  }

  Future<void> _simpanPrediksiCepat() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) throw Exception("Sesi habis.");

      // Validasi _selectedAnak dan _id
      if (_selectedAnak == null) {
        throw Exception(
          "Data anak tidak ditemukan. Silakan pilih anak terlebih dahulu.",
        );
      }

      final idAnak = _selectedAnak['_id'] ?? _selectedAnak['id'];
      if (idAnak == null || idAnak.toString().isEmpty) {
        print('DEBUG: _selectedAnak = $_selectedAnak');
        throw Exception(
          "ID anak tidak valid. Coba refresh dan pilih anak lagi.",
        );
      }

      print('DEBUG: Mengirim prediksi dengan ID anak: $idAnak');

      final requestBody = {
        'id_anak': idAnak,
        'tinggi_badan':
            double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
        'berat_badan':
            double.tryParse(_beratCtrl.text.replaceAll(',', '.')) ?? 0,
        'umur_bulan': _totalBulanAnak,
      };
      print('DEBUG: Request body = $requestBody');

      final responsePrediksi = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/prediksi/hitung'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (responsePrediksi.statusCode != 200 &&
          responsePrediksi.statusCode != 201) {
        throw Exception(
          "Gagal terhubung ke Server AI. Body: ${responsePrediksi.body}",
        );
      }

      final responseBody = jsonDecode(responsePrediksi.body);
      // Laravel PrediksiController@predict mengembalikan: data.keterangan, data.probabilitas
      final hasilKeterangan =
          (responseBody['data']?['keterangan'] ?? 'Tidak diketahui') as String;
      final hasilProbabilitas =
          ((responseBody['data']?['probabilitas']) as num?)?.toDouble() ?? 0.0;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HasilPrediksiPage(
              namaAnak: _selectedAnak['nama_anak'] ?? 'Anak',
              keterangan: hasilKeterangan,
              probabilitas: hasilProbabilitas,
              umurAnak: _umurAnakCtrl.text,
              beratBadan:
                  double.tryParse(_beratCtrl.text.replaceAll(',', '.')),
              tinggiBadan:
                  double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simpanKeDatabse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("Sesi telah habis, silakan login kembali.");
      }

      final responseIbu = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/profil-ibu'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usia_ibu': _usiaIbu > 0 ? _usiaIbu : 20,
          'tinggi_ibu': double.tryParse(_tinggiIbuCtrl.text) ?? 150.0,
          'pendidikan_ibu': _pendidikanIbu,
          'pekerjaan_ibu': _pekerjaanIbu,
        }),
      );

      if (responseIbu.statusCode != 200 && responseIbu.statusCode != 201) {
        throw Exception("Gagal menyimpan profil ibu.");
      }

      final tglLahirAnakFormatted = _tglLahirAnak != null
          ? "${_tglLahirAnak!.year}-${_tglLahirAnak!.month.toString().padLeft(2, '0')}-${_tglLahirAnak!.day.toString().padLeft(2, '0')}"
          : "";

      final tglPemeriksaanFormatted = _tglPemeriksaan != null
          ? "${_tglPemeriksaan!.year}-${_tglPemeriksaan!.month.toString().padLeft(2, '0')}-${_tglPemeriksaan!.day.toString().padLeft(2, '0')}"
          : "";

      final responseAnak = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/anak'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nik': _nikCtrl.text,
          'nama_anak': _namaAnakCtrl.text,
          'nama_ortu': _namaIbuCtrl.text,
          'jenis_kelamin': _jenisKelaminAnak,
          'tgl_lahir': tglLahirAnakFormatted,
          'tgl_pemeriksaan': tglPemeriksaanFormatted,
          'bb_lahir':
              double.tryParse(_bbLahirCtrl.text.replaceAll(',', '.')) ?? 0,
          'tb_lahir':
              double.tryParse(_tbLahirCtrl.text.replaceAll(',', '.')) ?? 0,
          'berat_badan':
              double.tryParse(_beratCtrl.text.replaceAll(',', '.')) ?? 0,
          'tinggi_badan':
              double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
        }),
      );

      if (responseAnak.statusCode != 200 && responseAnak.statusCode != 201) {
        throw Exception("Gagal menyimpan data anak.");
      }

      final bodyAnak = jsonDecode(responseAnak.body);
      final idAnak = bodyAnak['data']['_id'] ?? bodyAnak['data']['id'];

      if (idAnak == null || idAnak.toString().isEmpty) {
        throw Exception("Server tidak mengembalikan ID anak. Hubungi admin.");
      }

      final responsePrediksi = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/prediksi/hitung'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_anak': idAnak,
          'tinggi_badan':
              double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
          'berat_badan':
              double.tryParse(_beratCtrl.text.replaceAll(',', '.')) ?? 0,
          'umur_bulan': _totalBulanAnak,
        }),
      );

      if (responsePrediksi.statusCode != 200 &&
          responsePrediksi.statusCode != 201) {
        throw Exception(
          "Anak tersimpan, namun Prediksi AI gagal. Body: ${responsePrediksi.body}",
        );
      }

      final responseBodyPrediksi = jsonDecode(responsePrediksi.body);
      // Laravel PrediksiController@predict mengembalikan: data.keterangan, data.probabilitas
      final hasilKeterangan =
          (responseBodyPrediksi['data']?['keterangan'] ?? 'Tidak diketahui') as String;
      final hasilProbabilitas =
          ((responseBodyPrediksi['data']?['probabilitas']) as num?)?.toDouble() ?? 0.0;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HasilPrediksiPage(
              namaAnak: _namaAnakCtrl.text,
              keterangan: hasilKeterangan,
              probabilitas: hasilProbabilitas,
              umurAnak: _umurAnakCtrl.text,
              beratBadan:
                  double.tryParse(_beratCtrl.text.replaceAll(',', '.')),
              tinggiBadan:
                  double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) {
      return 'Harus berupa angka valid';
    }
    if (number < 0) {
      return 'Angka tidak boleh minus';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Stunting'), centerTitle: true),
      body: _isSimplifiedMode
          ? _buildSimplifiedMode(context)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(0, 'Data Ibu', Icons.pregnant_woman),
                      Container(
                        width: 50,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: _currentStep >= 1
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                      ),
                      _buildStepIndicator(1, 'Data Anak', Icons.child_care),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentStep = idx),
                    children: [_buildFormIbu(), _buildFormAnak()],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _currentStep == 0
                                  ? 'Lanjut ke Data Anak'
                                  : 'Mulai Prediksi & Simpan',
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSimplifiedMode(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKeyAnak,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediksi Pertumbuhan Anak',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan hasil pengukuran terakhir si kecil untuk diprediksi.',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 24),

                  if (widget.daftarAnak.length > 1) ...[
                    _buildDropdownAnak(),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildTextField(
                      controller: TextEditingController(
                        text: _selectedAnak['nama_anak'],
                      ),
                      label: 'Nama Anak',
                      hint: '',
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    controller: _umurAnakCtrl,
                    label: 'Umur Anak (Real-time)',
                    hint: 'Otomatis dihitung',
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),

                  _buildDatePickerField(
                    controller: _tglPemeriksaanCtrl,
                    label: 'Tanggal Pemeriksaan (Posyandu)',
                    hint: 'Pilih Tanggal',
                    onTap: _pilihTanggalPemeriksaan,
                    validator: (v) =>
                        _validateRequired(v, 'Tanggal Pemeriksaan'),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _beratCtrl,
                          label: 'BB Saat Ini (kg)',
                          hint: 'Misal: 9.5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              _validateNumber(v, 'Berat Saat Ini'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _tinggiCtrl,
                          label: 'TB Saat Ini (cm)',
                          hint: 'Misal: 75',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) =>
                              _validateNumber(v, 'Tinggi Saat Ini'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_formKeyAnak.currentState!.validate()) {
                        _simpanPrediksiCepat();
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Mulai Prediksi Sekarang'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownAnak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Anak',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: _selectedAnak,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            errorStyle: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: widget.daftarAnak.map((dynamic anak) {
            return DropdownMenuItem<dynamic>(
              value: anak,
              child: Text(anak['nama_anak']),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedAnak = val;
              _tglLahirAnak = DateTime.parse(_selectedAnak['tgl_lahir']);
              _hitungUmurDinamis();
            });
          },
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        ColorfulIcon(
          icon: icon,
          color: isActive ? AppTheme.primaryColor : Colors.grey,
          size: 28,
          padding: 14,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFormIbu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKeyIbu,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lengkapi Data Diri Ibu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data ini membantu kami memberikan hasil yang lebih akurat.',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _namaIbuCtrl,
              label: 'Nama Lengkap Ibu',
              hint: 'Contoh: Siti Aminah',
              validator: (v) => _validateRequired(v, 'Nama Lengkap'),
            ),
            const SizedBox(height: 16),

            _buildDatePickerField(
              controller: _tglLahirIbuCtrl,
              label: 'Tanggal Lahir Ibu',
              hint: 'Pilih Tanggal (dd/mm/yyyy)',
              onTap: _pilihTanggalLahirIbu,
              validator: (v) => _validateRequired(v, 'Tanggal Lahir'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _umurIbuCtrl,
                    label: 'Umur Ibu',
                    hint: 'Otomatis',
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _tinggiIbuCtrl,
                    label: 'Tinggi Ibu (cm)',
                    hint: 'Misal: 155',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateNumber(v, 'Tinggi Ibu'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Pendidikan Terakhir',
              value: _pendidikanIbu,
              items: const [
                'SD',
                'SMP',
                'SMA',
                'Diploma',
                'S1',
                'S2/S3',
                'Lainnya',
              ],
              onChanged: (v) => setState(() => _pendidikanIbu = v),
              validator: (v) => _validateRequired(v, 'Pendidikan'),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Pekerjaan Ibu',
              value: _pekerjaanIbu,
              items: const [
                'Ibu Rumah Tangga',
                'Karyawan Swasta',
                'PNS / BUMN',
                'Wiraswasta',
                'Lainnya',
              ],
              onChanged: (v) => setState(() => _pekerjaanIbu = v),
              validator: (v) => _validateRequired(v, 'Pekerjaan'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormAnak() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKeyAnak,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Pertumbuhan Anak',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan data kelahiran & hasil pengukuran terakhir si kecil.',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _nikCtrl,
              label: 'NIK Anak (Opsional / Jika ada)',
              hint: 'Contoh: 3509...',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _namaAnakCtrl,
              label: 'Nama Lengkap Anak',
              hint: 'Contoh: Budi',
              validator: (v) => _validateRequired(v, 'Nama Anak'),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Jenis Kelamin',
              value: _jenisKelaminAnak,
              items: const ['Laki-laki', 'Perempuan'],
              onChanged: (v) => setState(() => _jenisKelaminAnak = v),
              validator: (v) => _validateRequired(v, 'Jenis Kelamin'),
            ),
            const SizedBox(height: 16),

            _buildDatePickerField(
              controller: _tglLahirAnakCtrl,
              label: 'Tanggal Lahir Anak',
              hint: 'Pilih Tanggal (Maks Umur 5 Tahun)',
              onTap: _pilihTanggalLahirAnak,
              validator: (v) => _validateRequired(v, 'Tanggal Lahir Anak'),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _umurAnakCtrl,
              label: 'Umur Anak',
              hint: 'Otomatis terisi (bulan hari)',
              readOnly: true,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _bbLahirCtrl,
                    label: 'BB Lahir (kg)',
                    hint: 'Misal: 3.2',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateNumber(v, 'BB Lahir'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _tbLahirCtrl,
                    label: 'TB Lahir (cm)',
                    hint: 'Misal: 49',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateNumber(v, 'TB Lahir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildDatePickerField(
              controller: _tglPemeriksaanCtrl,
              label: 'Tanggal Terakhir Pemeriksaan (Posyandu)',
              hint: 'Kapan BB & TB terakhir diukur?',
              onTap: _pilihTanggalPemeriksaan,
              validator: (v) => _validateRequired(v, 'Tanggal Pemeriksaan'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _beratCtrl,
                    label: 'BB Saat Ini (kg)',
                    hint: 'Misal: 9.5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateNumber(v, 'Berat Saat Ini'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _tinggiCtrl,
                    label: 'TB Saat Ini (cm)',
                    hint: 'Misal: 75',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateNumber(v, 'Tinggi Saat Ini'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? Colors.grey.shade600 : AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: const Icon(
              Icons.calendar_today,
              color: Colors.grey,
              size: 20,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            errorStyle: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
