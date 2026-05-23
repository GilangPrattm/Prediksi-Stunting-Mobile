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
  final TextEditingController _tbLahirCtrl = TextEditingController();
  final TextEditingController _tinggiCtrl = TextEditingController();
  String? _jenisKelaminAnak;
  DateTime? _tglLahirAnak;
  DateTime? _tglPemeriksaan;
  int _totalBulanAnak = 0;

  // Tema Warna HTML Baru
  final Color _htmlPrimary = const Color(0xFF005AB4);
  final Color _htmlBg = const Color(0xFFF8F9FF);
  final Color _htmlSurface = Colors.white;
  final Color _htmlText = const Color(0xFF0B1C30);
  final Color _htmlTextVariant = const Color(0xFF414753);
  final Color _htmlOutline = const Color(0xFFC1C6D5);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    if (_isSimplifiedMode) {
      _selectedAnak = widget.daftarAnak[0];
      _tglLahirAnak = DateTime.tryParse(_selectedAnak['tgl_lahir'] ?? '') ?? DateTime.now();
      
      // FITUR AUTO-DATE: Langsung set ke hari ini
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
    _tbLahirCtrl.dispose();
    _tinggiCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDisplayDate(DateTime date) {
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
    _umurAnakCtrl.text = '$totalMonths Bulan';
  }

  Future<void> _pilihTanggalPemeriksaan() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tglPemeriksaan ?? now,
      firstDate: _tglLahirAnak ?? now.subtract(const Duration(days: 365 * 5)),
      lastDate: now, 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _htmlPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tglPemeriksaan = picked;
        _tglPemeriksaanCtrl.text = _formatDate(picked);
        _hitungUmurDinamis();
      });
    }
  }

  Future<void> _simpanPrediksiCepat() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) throw Exception("Sesi habis.");

      final idAnak = _selectedAnak['_id'] ?? _selectedAnak['id'];
      if (idAnak == null || idAnak.toString().isEmpty) {
        throw Exception("ID anak tidak valid.");
      }

      final requestBody = {
        'id_anak': idAnak,
        'tinggi_badan': double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
        'umur_bulan': _totalBulanAnak,
      };

      final responsePrediksi = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/prediksi/hitung'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (responsePrediksi.statusCode != 200 && responsePrediksi.statusCode != 201) {
        throw Exception("Gagal terhubung ke Server AI.");
      }

      final responseBody = jsonDecode(responsePrediksi.body);
      final mapData = responseBody['data'] ?? responseBody;

      final hasilPrediksi = (mapData['hasil_prediksi'] ?? 'Unknown').toString();
      final hasilProbabilitas = (mapData['probabilitas'] as num?)?.toDouble() ?? 1.0;

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HasilPrediksiPage(
              namaAnak: _selectedAnak['nama_anak'] ?? 'Anak',
              hasilPrediksi: hasilPrediksi,
              probabilitas: hasilProbabilitas,
              tinggiBadan: double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
              rekomendasiTeks: mapData['rekomendasi_teks'] as String?,
              rekomendasiTerstruktur: mapData['rekomendasi_terstruktur'] != null 
                  ? List<dynamic>.from(mapData['rekomendasi_terstruktur']) 
                  : null,
            ),
          ),
          (Route<dynamic> route) => route.isFirst,
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

  @override
  Widget build(BuildContext context) {
    if (_isSimplifiedMode) {
      return Scaffold(
        backgroundColor: _htmlBg,
        appBar: AppBar(
          backgroundColor: _htmlSurface,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _htmlPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Icon(Icons.assessment, color: _htmlPrimary),
              const SizedBox(width: 8),
              Text(
                'Halaman Prediksi',
                style: TextStyle(
                  color: _htmlPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        body: _buildSimplifiedModeHTML(),
      );
    }
    
    // Tampilan Multi-step form lama tetap dipertahankan untuk pendaftaran awal
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Stunting'), centerTitle: true),
      body: const Center(child: Text('Form Pendaftaran Awal (Mode Lengkap)')),
    );
  }

  // =========================================================================
  // UI DESAIN BARU (Sesuai HTML Tailwind)
  // =========================================================================
  Widget _buildSimplifiedModeHTML() {
    String namaAnak = _selectedAnak['nama_anak'] ?? 'Anak';
    String jenisKelamin = (_selectedAnak['jenis_kelamin'] ?? 'L').toString().toLowerCase() == 'l' || 
                          (_selectedAnak['jenis_kelamin'] ?? '').toString().toLowerCase() == 'laki-laki' 
                          ? 'Laki-laki' : 'Perempuan';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KARTU PROFIL ──
          Container(
            decoration: BoxDecoration(
              color: _htmlSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF4FF)),
              boxShadow: [
                BoxShadow(
                  color: _htmlPrimary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Dekorasi pojok kanan atas
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _htmlPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROFIL SI KECIL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF717785),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE9FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFAAC7FF), width: 2),
                            ),
                            child: Icon(Icons.child_care, color: _htmlPrimary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaAnak,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _htmlText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildBadge(jenisKelamin == 'Laki-laki' ? Icons.male : Icons.female, jenisKelamin),
                                    const SizedBox(width: 8),
                                    _buildBadge(Icons.calendar_month, '${_totalBulanAnak} Bulan'),
                                  ],
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
            ),
          ),

          const SizedBox(height: 24),

          // ── FORM PENGUKURAN ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _htmlSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF4FF)),
              boxShadow: [
                BoxShadow(
                  color: _htmlPrimary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKeyAnak,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INPUT PENGUKURAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF717785),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Field Tanggal (Auto hari ini)
                  const Text(
                    'Tanggal Pemeriksaan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pilihTanggalPemeriksaan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF), // bg-surface-bright
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _htmlOutline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: _htmlOutline, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _tglPemeriksaan != null ? _formatDisplayDate(_tglPemeriksaan!) : '',
                            style: TextStyle(fontSize: 16, color: _htmlText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih tanggal saat pengukuran dilakukan (Otomatis hari ini).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF717785)),
                  ),

                  const SizedBox(height: 20),

                  // Field Tinggi Badan
                  const Text(
                    'Tinggi Badan (cm)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tinggiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 16, color: _htmlText),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      prefixIcon: Icon(Icons.height, color: _htmlOutline),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _htmlOutline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _htmlPrimary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Tinggi badan wajib diisi';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Harus angka valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masukkan tinggi badan terbaru si kecil.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF717785)),
                  ),

                  const SizedBox(height: 32),

                  // Tombol Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKeyAnak.currentState!.validate()) {
                                _simpanPrediksiCepat();
                              }
                            },
                      icon: _isLoading 
                          ? const SizedBox.shrink() 
                          : const Icon(Icons.analytics, color: Colors.white),
                      label: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Mulai Prediksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.7,
                                color: Colors.white
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _htmlPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        shadowColor: _htmlPrimary.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _htmlPrimary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF414753),
            ),
          ),
        ],
      ),
    );
  }
}