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

// Model sederhana untuk menyimpan data satu anak
class _DataAnak {
  final TextEditingController nikCtrl = TextEditingController();
  final TextEditingController namaCtrl = TextEditingController();
  final TextEditingController tglLahirCtrl = TextEditingController();
  final TextEditingController tglPemeriksaanCtrl = TextEditingController();
  final TextEditingController tbLahirCtrl = TextEditingController();
  final TextEditingController tbSekarangCtrl = TextEditingController();
  String? jenisKelamin;

  void dispose() {
    nikCtrl.dispose();
    namaCtrl.dispose();
    tglLahirCtrl.dispose();
    tglPemeriksaanCtrl.dispose();
    tbLahirCtrl.dispose();
    tbSekarangCtrl.dispose();
  }
}

class _TambahAnakPageState extends State<TambahAnakPage>
    with SingleTickerProviderStateMixin {
  // --- STEP: 1 = Form Ibu, 2 = Pilih Jumlah Anak, 3 = Form Anak ---
  int _currentStep = 1;
  bool _isLoading = false;

  // Jumlah anak yang dipilih
  int _jumlahAnak = 1;
  // Indeks anak yang sedang diisi (0-based)
  int _indexAnakAktif = 0;
  // List data per anak
  List<_DataAnak> _daftarDataAnak = [];

  // TabController untuk navigasi antar anak
  TabController? _tabController;

  // --- TEMA WARNA ---
  final Color _bgSurface = const Color(0xFFF8F9FF);
  final Color _cardBg = const Color(0xFFFFFFFF);
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _textMain = const Color(0xFF0B1C30);
  final Color _textOutline = const Color(0xFF717785);
  final Color _inputBg = const Color(0xFFF8F9FF);

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

  @override
  void initState() {
    super.initState();
    _fetchDataIbuAwal();
  }

  @override
  void dispose() {
    _namaIbuController.dispose();
    _emailIbuController.dispose();
    _telpIbuController.dispose();
    _tglLahirIbuController.dispose();
    _tbIbuController.dispose();
    _tabController?.dispose();
    for (var d in _daftarDataAnak) {
      d.dispose();
    }
    super.dispose();
  }

  // Inisialisasi list data anak sesuai jumlah yang dipilih
  void _inisialisasiDataAnak(int jumlah) {
    // Dispose controller lama
    for (var d in _daftarDataAnak) {
      d.dispose();
    }
    _daftarDataAnak = List.generate(jumlah, (_) => _DataAnak());
    _indexAnakAktif = 0;

    _tabController?.dispose();
    _tabController = TabController(length: jumlah, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() => _indexAnakAktif = _tabController!.index);
      }
    });
  }

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
      debugPrint("Gagal fetch data awal: $e");
    }
  }

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

  // ─── NAVIGASI ───────────────────────────────────────────────

  void _lanjutKeStep2() {
    if (_namaIbuController.text.isEmpty ||
        _tglLahirIbuController.text.isEmpty) {
      _showSnackbar(
        'Mohon lengkapi Nama dan Tanggal Lahir Bunda terlebih dahulu.',
        isError: true,
      );
      return;
    }
    setState(() => _currentStep = 2);
  }

  void _lanjutKeFormAnak() {
    _inisialisasiDataAnak(_jumlahAnak);
    setState(() => _currentStep = 3);
  }

  void _kembali() {
    if (_currentStep == 2) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 2);
    } else {
      Navigator.pop(context);
    }
  }

  // Cek apakah anak aktif sudah terisi field wajib
  bool _anakAktifValid() {
    final d = _daftarDataAnak[_indexAnakAktif];
    return d.nikCtrl.text.isNotEmpty &&
        d.namaCtrl.text.isNotEmpty &&
        d.tglLahirCtrl.text.isNotEmpty &&
        d.jenisKelamin != null;
  }

  void _lanjutAtauSimpan() {
    if (!_anakAktifValid()) {
      _showSnackbar(
        'Lengkapi data Anak ${_indexAnakAktif + 1} terlebih dahulu ya Bunda!',
        isError: true,
      );
      return;
    }

    if (_indexAnakAktif < _jumlahAnak - 1) {
      // Masih ada anak berikutnya → pindah tab
      _tabController!.animateTo(_indexAnakAktif + 1);
    } else {
      // Semua anak sudah diisi → simpan
      _prosesSimpanFinal();
    }
  }

  // ─── SIMPAN ─────────────────────────────────────────────────

  void _prosesSimpanFinal() async {
    setState(() => _isLoading = true);

    int calculatedUsiaIbu = 0;
    if (_tglLahirIbuController.text.isNotEmpty) {
      try {
        DateTime dob = DateTime.parse(_tglLahirIbuController.text);
        DateTime now = DateTime.now();
        calculatedUsiaIbu = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          calculatedUsiaIbu--;
        }
      } catch (e) {
        debugPrint("Error parsing tgl lahir ibu: $e");
      }
    }

    // Simpan data ibu
    final dataKirimIbu = {
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
      _showSnackbar('Gagal menyimpan data ibu. Coba lagi.', isError: true);
      return;
    }

    // Simpan semua data anak secara berurutan
    bool semuaSukses = true;
    for (int i = 0; i < _daftarDataAnak.length; i++) {
      final d = _daftarDataAnak[i];
      final dataKirimAnak = {
        'nik': d.nikCtrl.text,
        'nama_anak': d.namaCtrl.text,
        'nama_ortu': _namaIbuController.text,
        'jenis_kelamin': d.jenisKelamin,
        'tgl_lahir': d.tglLahirCtrl.text,
        'tgl_pemeriksaan': d.tglPemeriksaanCtrl.text,
        'tb_lahir': double.tryParse(d.tbLahirCtrl.text) ?? 0,
        'tinggi_badan': double.tryParse(d.tbSekarangCtrl.text) ?? 0,
      };

      bool sukses = await AnakService().simpanData(dataKirimAnak);
      if (!sukses) {
        semuaSukses = false;
        if (mounted) {
          _showSnackbar(
            'Gagal menyimpan data Anak ${i + 1}. Coba lagi.',
            isError: true,
          );
        }
        break;
      }
    }

    setState(() => _isLoading = false);

    if (semuaSukses && mounted) {
      _showSnackbar('Semua data berhasil disimpan!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    }
  }

  // ─── HELPER ─────────────────────────────────────────────────

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _labelLangkah() {
    switch (_currentStep) {
      case 1:
        return 'Langkah 1 dari 3';
      case 2:
        return 'Langkah 2 dari 3';
      case 3:
        return 'Langkah 3 dari 3';
      default:
        return '';
    }
  }

  String _judulAppBar() {
    switch (_currentStep) {
      case 1:
        return 'Data Bunda';
      case 2:
        return 'Jumlah Anak';
      case 3:
        if (_daftarDataAnak.isNotEmpty) {
          return 'Data Anak ${_indexAnakAktif + 1} dari $_jumlahAnak';
        }
        return 'Data Anak';
      default:
        return '';
    }
  }

  String _labelTombol() {
    if (_currentStep == 1) return 'Lanjut ke Jumlah Anak';
    if (_currentStep == 2) return 'Mulai Isi Data Anak';
    // Step 3
    if (_indexAnakAktif < _jumlahAnak - 1) {
      return 'Lanjut ke Anak ${_indexAnakAktif + 2}';
    }
    return 'Simpan Semua Data';
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          onPressed: _kembali,
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _judulAppBar(),
            key: ValueKey(_judulAppBar()),
            style: TextStyle(
              color: _textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── STEPPER INDICATOR ──
          _buildStepperIndicator(),

          // ── KONTEN ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == 1
                  ? SingleChildScrollView(
                      key: const ValueKey('step1'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: _buildFormIbu(),
                    )
                  : _currentStep == 2
                  ? SingleChildScrollView(
                      key: const ValueKey('step2'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: _buildPilihJumlahAnak(),
                    )
                  : _buildFormAnakMulti(),
            ),
          ),

          // ── BOTTOM BUTTON ──
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ─── STEPPER INDICATOR ──────────────────────────────────────

  Widget _buildStepperIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _labelLangkah(),
            style: TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              final active = _currentStep >= (i + 1);
              return Row(
                children: [
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 8,
                    width: active ? 32 : 16,
                    decoration: BoxDecoration(
                      color: active ? _primaryBlue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM BUTTON ──────────────────────────────────────────

  Widget _buildBottomButton() {
    return Container(
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
              : () {
                  if (_currentStep == 1) {
                    _lanjutKeStep2();
                  } else if (_currentStep == 2) {
                    _lanjutKeFormAnak();
                  } else {
                    _lanjutAtauSimpan();
                  }
                },
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
                      _labelTombol(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_currentStep < 3 ||
                        (_currentStep == 3 &&
                            _indexAnakAktif < _jumlahAnak - 1)) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1 — FORM IBU
  // ============================================================

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
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // STEP 2 — PILIH JUMLAH ANAK
  // ============================================================

  Widget _buildPilihJumlahAnak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          'Berapa jumlah anak yang ingin didaftarkan? Data setiap anak akan diisi secara terpisah.',
          Icons.child_friendly_outlined,
        ),
        const SizedBox(height: 24),
        Text(
          'Pilih jumlah anak',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _textMain,
          ),
        ),
        const SizedBox(height: 16),

        // Grid pilihan angka 1–4
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: 4,
          itemBuilder: (_, i) {
            final angka = i + 1;
            final dipilih = _jumlahAnak == angka;
            return GestureDetector(
              onTap: () => setState(() => _jumlahAnak = angka),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: dipilih ? _primaryBlue : _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dipilih ? _primaryBlue : Colors.grey.shade200,
                    width: dipilih ? 2 : 1,
                  ),
                  boxShadow: dipilih
                      ? [
                          BoxShadow(
                            color: _primaryBlue.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$angka',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: dipilih ? Colors.white : _textMain,
                      ),
                    ),
                    Text(
                      'anak',
                      style: TextStyle(
                        fontSize: 11,
                        color: dipilih ? Colors.white70 : _textOutline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),

        // Ringkasan pilihan
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(_jumlahAnak),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE9FF)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: _primaryBlue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kamu akan mengisi data untuk $_jumlahAnak '
                    '${_jumlahAnak == 1 ? 'anak' : 'anak'}. '
                    'Setiap anak memiliki form terpisah.',
                    style: TextStyle(
                      color: _textMain,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // STEP 3 — FORM ANAK (MULTI-TAB)
  // ============================================================

  Widget _buildFormAnakMulti() {
    if (_daftarDataAnak.isEmpty || _tabController == null) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('step3'),
      children: [
        // ── TAB BAR (hanya tampil jika anak > 1) ──
        if (_jumlahAnak > 1)
          Container(
            color: _bgSurface,
            child: TabBar(
              controller: _tabController,
              isScrollable: _jumlahAnak > 3,
              labelColor: _primaryBlue,
              unselectedLabelColor: _textOutline,
              indicatorColor: _primaryBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: List.generate(
                _jumlahAnak,
                (i) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.accessibility_new_rounded,
                        size: 16,
                        color: _indexAnakAktif == i
                            ? _primaryBlue
                            : _textOutline,
                      ),
                      const SizedBox(width: 4),
                      Text('Anak ${i + 1}'),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── KONTEN PER ANAK ──
        Expanded(
          child: _jumlahAnak == 1
              // Jika hanya 1 anak: langsung tampilkan form
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: _buildFormAnakSatu(0),
                )
              // Jika > 1: gunakan TabBarView
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    _jumlahAnak,
                    (i) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: _buildFormAnakSatu(i),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // Form untuk satu anak (berdasarkan index)
  Widget _buildFormAnakSatu(int index) {
    final d = _daftarDataAnak[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoBanner(
          'Pastikan data Anak ${index + 1} disalin dengan benar dari Buku KIA ya Bunda.',
          Icons.stars,
        ),
        const SizedBox(height: 20),

        // SECTION 1: IDENTITAS
        _buildSectionTitle('1. Identitas Anak ${index + 1}'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('NIK Anak'),
              _buildCustomTextField(
                d.nikCtrl,
                'Contoh: 3509xxxxxxxxxxxx',
                Icons.badge_outlined,
                inputType: TextInputType.number,
              ),
              _buildLabel('Nama Lengkap Anak'),
              _buildCustomTextField(
                d.namaCtrl,
                'Contoh: Sal Priadi',
                Icons.accessibility_new_rounded,
              ),
              _buildLabel('Jenis Kelamin'),
              _buildCustomDropdownDynamic(
                value: d.jenisKelamin,
                hint: 'Pilih Jenis Kelamin',
                icon: Icons.wc_outlined,
                items: ['Laki-laki', 'Perempuan'],
                onChanged: (val) => setState(() => d.jenisKelamin = val),
              ),
              _buildLabel('Tanggal Lahir'),
              _buildDateTextField(
                d.tglLahirCtrl,
                'Pilih Tanggal Lahir',
                context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION 2: DATA KELAHIRAN
        _buildSectionTitle('2. Data Kelahiran'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('TB Lahir (cm)'),
              _buildCustomTextField(
                d.tbLahirCtrl,
                'Misal: 49',
                Icons.height_outlined,
                inputType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION 3: PEMERIKSAAN POSYANDU
        _buildSectionTitle('3. Pemeriksaan Terakhir di Posyandu'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Tanggal Terakhir Periksa'),
              _buildDateTextField(
                d.tglPemeriksaanCtrl,
                'Pilih Tanggal',
                context,
              ),
              _buildLabel('TB Saat Ini (cm)'),
              _buildCustomTextField(
                d.tbSekarangCtrl,
                'Misal: 82',
                Icons.straighten_outlined,
                inputType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: _textMain,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: _primaryBlue.withOpacity(0.05), blurRadius: 15),
      ],
    );
  }

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

  // Dropdown untuk data ibu (state di-manage di state class)
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
      items: items
          .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // Dropdown untuk data anak per-item (state di _DataAnak)
  Widget _buildCustomDropdownDynamic({
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
      items: items
          .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
