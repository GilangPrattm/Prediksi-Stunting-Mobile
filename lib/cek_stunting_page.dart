import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'hasil_prediksi_page.dart';
import 'tambah_anak_page.dart';

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
  bool _isLoading = false;

  bool get _isSimplifiedMode => widget.daftarAnak.isNotEmpty;
  dynamic _selectedAnak;

  final _formKeyAnak = GlobalKey<FormState>();
  final TextEditingController _umurAnakCtrl = TextEditingController();
  final TextEditingController _tglPemeriksaanCtrl = TextEditingController();
  final TextEditingController _tinggiCtrl = TextEditingController();

  DateTime? _tglLahirAnak;
  DateTime? _tglPemeriksaan;
  int _totalBulanAnak = 0;

  // ── Warna ──────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF005AB4);
  static const Color _bg = Color(0xFFF8F9FF);
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF0B1C30);
  static const Color _textVariant = Color(0xFF414753);
  static const Color _outline = Color(0xFFC1C6D5);
  static const Color _subtleGray = Color(0xFF717785);

  @override
  void initState() {
    super.initState();
    if (_isSimplifiedMode) {
      _selectedAnak = widget.daftarAnak[0];
      _tglLahirAnak =
          DateTime.tryParse(_selectedAnak['tgl_lahir'] ?? '') ?? DateTime.now();
      _tglPemeriksaan = DateTime.now();
      _tglPemeriksaanCtrl.text = _formatDate(_tglPemeriksaan!);
      _hitungUmurDinamis();
    }
  }

  @override
  void dispose() {
    _umurAnakCtrl.dispose();
    _tglPemeriksaanCtrl.dispose();
    _tinggiCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _formatDisplayDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  void _hitungUmurDinamis() {
    if (_tglLahirAnak == null || _tglPemeriksaan == null) return;
    int months =
        (_tglPemeriksaan!.year - _tglLahirAnak!.year) * 12 +
        _tglPemeriksaan!.month -
        _tglLahirAnak!.month;
    int days = _tglPemeriksaan!.day - _tglLahirAnak!.day;
    if (days < 0) {
      months--;
      final last = DateTime(_tglPemeriksaan!.year, _tglPemeriksaan!.month, 0);
      days += last.day;
    }
    if (months < 0) months = 0;
    _totalBulanAnak = months;
    _umurAnakCtrl.text = '$months Bulan';
  }

  Future<void> _pilihTanggalPemeriksaan() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglPemeriksaan ?? now,
      firstDate: _tglLahirAnak ?? now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Sesi habis.');

      final idAnak = _selectedAnak['_id'] ?? _selectedAnak['id'];
      if (idAnak == null || idAnak.toString().isEmpty) {
        throw Exception('ID anak tidak valid.');
      }

      final body = {
        'id_anak': idAnak,
        'tinggi_badan':
            double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
        'umur_bulan': _totalBulanAnak,
      };

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/prediksi/hitung'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Gagal terhubung ke Server AI.');
      }

      final json = jsonDecode(res.body);
      final mapData = json['data'] ?? json;

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HasilPrediksiPage(
              namaAnak: _selectedAnak['nama_anak'] ?? 'Anak',
              hasilPrediksi: (mapData['hasil_prediksi'] ?? 'Unknown')
                  .toString(),
              probabilitas:
                  (mapData['probabilitas'] as num?)?.toDouble() ?? 1.0,
              tinggiBadan:
                  double.tryParse(_tinggiCtrl.text.replaceAll(',', '.')) ?? 0,
              rekomendasiTeks: mapData['rekomendasi_teks'] as String?,
              rekomendasiTerstruktur: mapData['rekomendasi_terstruktur'] != null
                  ? List<dynamic>.from(mapData['rekomendasi_terstruktur'])
                  : null,
            ),
          ),
          (route) => route.isFirst,
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

  // ── Tentukan apa yang kurang ───────────────────────────────────
  bool get _dataAnakKosong => widget.daftarAnak.isEmpty;
  bool get _dataIbuKosong => !widget.isIbuDataComplete;

  // ── BUILD ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cek Stunting',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      // Pilih body: data lengkap → form prediksi, belum lengkap → halaman arahan
      body: _isSimplifiedMode ? _buildFormPrediksi() : _buildDataBelumLengkap(),
    );
  }

  // =========================================================================
  // [BARU] HALAMAN ARAHAN — Data Belum Lengkap
  // Tampil sebagai halaman penuh, bukan bottom sheet, agar tidak ada masalah timing
  // =========================================================================
  Widget _buildDataBelumLengkap() {
    final bool keduaKosong = _dataAnakKosong && _dataIbuKosong;
    final bool hanyaAnakKosong = _dataAnakKosong && !_dataIbuKosong;
    final bool hanyaIbuKosong = !_dataAnakKosong && _dataIbuKosong;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Ilustrasi ──
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD6E3FF), width: 2),
              ),
              child: const Icon(
                Icons.assignment_ind_outlined,
                size: 52,
                color: _primary,
              ),
            ),
            const SizedBox(height: 28),

            // ── Judul ──
            const Text(
              'Data Belum Lengkap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textMain,
              ),
            ),
            const SizedBox(height: 12),

            // ── Deskripsi ──
            Text(
              keduaKosong
                  ? 'Untuk memulai prediksi stunting, Bunda perlu melengkapi data profil ibu dan data anak terlebih dahulu.'
                  : hanyaAnakKosong
                  ? 'Untuk memulai prediksi, Bunda perlu menambahkan data anak terlebih dahulu di halaman Profil.'
                  : 'Untuk memulai prediksi, Bunda perlu melengkapi data profil ibu terlebih dahulu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _textVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // ── Checklist item yang belum diisi ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFF4FF)),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yang perlu dilengkapi:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _subtleGray,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_dataIbuKosong)
                    _buildChecklistItem(
                      'Data profil ibu',
                      'Nama, tanggal lahir, tinggi badan, pendidikan',
                      Icons.person_outline,
                    ),
                  if (_dataIbuKosong && _dataAnakKosong)
                    const SizedBox(height: 10),
                  if (_dataAnakKosong)
                    _buildChecklistItem(
                      'Data anak',
                      'Nama, tanggal lahir, jenis kelamin',
                      Icons.child_care_rounded,
                    ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // ── Tombol Utama ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TambahAnakPage()),
                  ).then((_) {
                    // Setelah kembali dari TambahAnakPage, pop ke home
                    // agar home_page.dart re-fetch data dan kirim daftarAnak terbaru
                    if (mounted) Navigator.pop(context);
                  });
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Lengkapi Data Sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: _primary.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Tombol Sekunder ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String judul, String sub, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Color(0xFFE11D48),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: _textVariant),
                  const SizedBox(width: 6),
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(fontSize: 12, color: _subtleGray),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // FORM PREDIKSI (simplified mode — data sudah lengkap)
  // =========================================================================
  Widget _buildFormPrediksi() {
    final namaAnak = _selectedAnak['nama_anak'] ?? 'Anak';
    final jk = (_selectedAnak['jenis_kelamin'] ?? 'L').toString().toLowerCase();
    final jenisKelamin = (jk == 'l' || jk == 'laki-laki')
        ? 'Laki-laki'
        : 'Perempuan';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Kartu Profil ──
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF4FF)),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
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
                          color: _subtleGray,
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
                              border: Border.all(
                                color: const Color(0xFFAAC7FF),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.child_care,
                              color: _primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaAnak,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _textMain,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildBadge(
                                      jenisKelamin == 'Laki-laki'
                                          ? Icons.male
                                          : Icons.female,
                                      jenisKelamin,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildBadge(
                                      Icons.calendar_month,
                                      '$_totalBulanAnak Bulan',
                                    ),
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

          // ── Form Pengukuran ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFF4FF)),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.08),
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
                      color: _subtleGray,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tanggal Pemeriksaan
                  const Text(
                    'Tanggal Pemeriksaan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pilihTanggalPemeriksaan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _outline),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: _outline,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _tglPemeriksaan != null
                                ? _formatDisplayDate(_tglPemeriksaan!)
                                : '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: _textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih tanggal saat pengukuran dilakukan (Otomatis hari ini).',
                    style: TextStyle(fontSize: 12, color: _subtleGray),
                  ),

                  const SizedBox(height: 20),

                  // Tinggi Badan
                  const Text(
                    'Tinggi Badan (cm)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tinggiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 16, color: _textMain),
                    decoration: InputDecoration(
                      hintText: '0.0',
                      prefixIcon: const Icon(Icons.height, color: _outline),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Tinggi badan wajib diisi';
                      if (double.tryParse(v.replaceAll(',', '.')) == null)
                        return 'Harus angka valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masukkan tinggi badan terbaru si kecil.',
                    style: TextStyle(fontSize: 12, color: _subtleGray),
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
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Mulai Prediksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.7,
                                color: Colors.white,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                        shadowColor: _primary.withOpacity(0.4),
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
          Icon(icon, size: 14, color: _primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textVariant,
            ),
          ),
        ],
      ),
    );
  }
}
