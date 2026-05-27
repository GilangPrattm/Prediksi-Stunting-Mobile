import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mpasi_page.dart';
import 'custom_bottom_nav.dart';
import 'tambah_anak_page.dart';
import 'profil_page.dart';
import 'edit_profil_page.dart';
import 'config/api_config.dart';
import 'cek_gizi_bottom_sheet.dart';
import 'cek_stunting_page.dart';
import 'chatbot_page.dart';
import 'hasil_prediksi_page.dart';
import 'riwayat_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final String _baseUrl = ApiConfig.baseUrl;

  List<dynamic> _daftarAnak = [];
  bool _isLoadingAnak = true;
  int _anakTerpilihIndeks = 0;
  String _namaBunda = '';
  List<dynamic> _daftarResep = [];
  bool _isProfilIbuLengkap = true;
  List<dynamic> _daftarHistoriPrediksi = [];
  bool _isLoadingHistori = true;

  List<dynamic> _daftarInspirasi = [];
  bool _isLoadingInspirasi = true;

  // --- WARNA TEMA ---
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _primaryFixed = const Color(0xFFD6E3FF);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _surfaceContainer = const Color(0xFFE5EEFF);

  @override
  void initState() {
    super.initState();
    _fetchProfilDanAnak();
  }

  Future<void> _fetchProfilDanAnak() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    try {
      final resCekIbu = await http.get(
        Uri.parse('$_baseUrl/profil-ibu'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resCekIbu.statusCode == 404) {
        setState(() => _isProfilIbuLengkap = false);
      } else {
        setState(() => _isProfilIbuLengkap = true);
      }

      final resProfil = await http.get(
        Uri.parse('$_baseUrl/profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resProfil.statusCode == 200) {
        final dataProfil = jsonDecode(resProfil.body);
        setState(() {
          _namaBunda = dataProfil['data']['name'] ?? '';
        });
      }

      final resAnak = await http.get(
        Uri.parse('$_baseUrl/anak'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resAnak.statusCode == 200) {
        final dataAnak = jsonDecode(resAnak.body);
        setState(() {
          _daftarAnak = dataAnak['data'];
          _isLoadingAnak = false;
        });
      } else {
        setState(() => _isLoadingAnak = false);
      }

      final resMakanan = await http.get(
        Uri.parse('$_baseUrl/makanan'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resMakanan.statusCode == 200) {
        setState(() {
          _daftarResep = jsonDecode(resMakanan.body)['data'];
        });
      }

      final resHistori = await http.get(
        Uri.parse('$_baseUrl/prediksi'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resHistori.statusCode == 200) {
        final dataHistori = jsonDecode(resHistori.body);
        setState(() {
          _daftarHistoriPrediksi = (dataHistori['data'] as List).reversed
              .toList();
          _isLoadingHistori = false;
        });
      } else {
        setState(() => _isLoadingHistori = false);
      }

      final resInspirasi = await http.get(
        Uri.parse('$_baseUrl/inspirasi'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resInspirasi.statusCode == 200) {
        setState(() {
          _daftarInspirasi = jsonDecode(resInspirasi.body)['data'] ?? [];
          _isLoadingInspirasi = false;
        });
      } else {
        setState(() => _isLoadingInspirasi = false);
      }
    } catch (e) {
      print("Error Fetching API: $e");
      setState(() {
        _isLoadingAnak = false;
        _isLoadingHistori = false;
      });
    }
  }

  String _hitungUmur(String? tglLahirStr) {
    if (tglLahirStr == null || tglLahirStr.isEmpty) {
      return 'Umur Tidak Diketahui';
    }
    try {
      DateTime birthDate = DateTime.parse(tglLahirStr);
      DateTime today = DateTime.now();
      int months =
          (today.year - birthDate.year) * 12 + today.month - birthDate.month;
      if (today.day < birthDate.day) {
        months--;
      }
      if (months <= 0) return 'Baru Lahir';
      if (months < 12) return '$months Bulan';
      int years = months ~/ 12;
      int remainingMonths = months % 12;
      return remainingMonths == 0
          ? '$years Tahun'
          : '$years Tahun $remainingMonths Bulan';
    } catch (e) {
      return '-';
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CekStuntingPage(
            isIbuDataComplete: _isProfilIbuLengkap,
            daftarAnak: _daftarAnak,
          ),
        ),
      ).then((_) => _fetchProfilDanAnak()); // Refresh data saat kembali
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBeranda(),
      RiwayatPage(daftarAnak: _daftarAnak),
      const SizedBox(), 
      MpasiPage(
        daftarAnak: _daftarAnak,
        anakTerpilihIndeks: _anakTerpilihIndeks,
      ),
      const ProfilPage(),
    ];

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? _buildFAB() : null,
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotPage()),
          );
        },
        backgroundColor: _primaryBlue,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(30),
          ),
          side: BorderSide(color: Color(0xFFD6E3FF), width: 2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // [PERBAIKAN 2] Ikon Chatbot menggunakan gambar kustom Kila AI
            ClipOval(
              child: Image.asset(
                'assets/images/kila_icon.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.smart_toy, color: Colors.white, size: 30),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryBlue, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==== WIDGET TAB 0: BERANDA ====
  Widget _buildBeranda() {
    bool hasData = !_isLoadingAnak && _daftarAnak.isNotEmpty && _isProfilIbuLengkap;
    bool isUserBaru = !_isLoadingAnak && (!_isProfilIbuLengkap || _daftarAnak.isEmpty);

    return RefreshIndicator(
      onRefresh: _fetchProfilDanAnak,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),

            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingAnak)
                      const Center(child: CircularProgressIndicator())
                    else if (isUserBaru)
                      _buildKartuUserBaru() 
                    else
                      _buildProgressHero(),

                    const SizedBox(height: 24),

                    if (hasData) _buildAksiCepat(),

                    const SizedBox(height: 24),

                    _buildTipsHarian(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    String displayNama = _namaBunda.isNotEmpty ? _namaBunda : 'Bunda';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF1FF), Color(0xFFD6E3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.8)),
                  ),
                  child: Icon(Icons.person, color: _primaryBlue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Pagi,',
                        style: TextStyle(
                          color: _bgHitam.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Halo, $displayNama!',
                        style: TextStyle(
                          color: _bgHitam,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis, 
                        maxLines: 1, 
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.8)),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: _primaryBlue,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuUserBaru() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.family_restroom, size: 40, color: _primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat Datang di Stunt-Check!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _bgHitam,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mari mulai perjalanan memantau tumbuh kembang si Kecil dengan melengkapi data berikut.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _outlineColor, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!_isProfilIbuLengkap) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilPage(),
                    ),
                  ).then((_) => _fetchProfilDanAnak());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TambahAnakPage(),
                    ),
                  ).then((_) => _fetchProfilDanAnak());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Lengkapi Data Sekarang',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHero() {
    var anakAktif = _daftarAnak[_anakTerpilihIndeks];
    String idAnakAktif = anakAktif['_id']?.toString() ?? anakAktif['id']?.toString() ?? '';
    String namaMurni = anakAktif['nama_anak'] ?? 'Tanpa Nama';
    String teksUsia = _hitungUmur(anakAktif['tgl_lahir']);
    String tinggiBadan = anakAktif['tinggi_badan']?.toString() ?? '-';
    
    // [PERBAIKAN 1]: Mengambil data Status Gizi dan Tgl Pemeriksaan dari histori (Real-time update)
    var riwayatAnak = _daftarHistoriPrediksi.where((r) => (r['id_anak']?.toString() ?? '') == idAnakAktif).toList();
    
    String statusGiziRaw = 'Normal';
    String tglPeriksa = anakAktif['tgl_pemeriksaan'] ?? 'Belum dicek';
    
    if (riwayatAnak.isNotEmpty) {
      statusGiziRaw = (riwayatAnak.first['hasil_prediksi'] ?? riwayatAnak.first['status'] ?? 'Normal').toString();
      
      String tgl = (riwayatAnak.first['tanggal'] ?? riwayatAnak.first['created_at'] ?? '').toString();
      if (tgl.length > 10) tgl = tgl.substring(0, 10);
      if (tgl.isNotEmpty) tglPeriksa = tgl;
      
      if(riwayatAnak.first['tinggi_badan'] != null) {
        tinggiBadan = riwayatAnak.first['tinggi_badan'].toString();
      }
    } else {
      statusGiziRaw = anakAktif['status_gizi'] ?? 'Normal';
    }

    String statusGizi = statusGiziRaw;
    Color ringColor = const Color(0xFF10B981); // Emerald/Normal (Default)

    if (statusGiziRaw.toLowerCase().contains('sangat stunting') || statusGiziRaw.toLowerCase().contains('sangat pendek') || statusGiziRaw.toLowerCase().contains('severely')) {
      ringColor = const Color(0xFFE11D48); // Rose
      statusGizi = "Sangat Stunting";
    } else if (statusGiziRaw.toLowerCase().contains('stunting') || statusGiziRaw.toLowerCase().contains('pendek') || statusGiziRaw.toLowerCase().contains('berisiko')) {
      ringColor = const Color(0xFFF59E0B); // Amber
      statusGizi = "Stunting";
    } else if (statusGiziRaw.toLowerCase().contains('tinggi')) {
      ringColor = _primaryBlue; // Blue
      statusGizi = "Tinggi";
    } else {
      statusGizi = "Normal";
    }

    final String jkRaw = (anakAktif['jenis_kelamin'] ?? '').toString().toLowerCase();
    final bool isLakiLaki = jkRaw == 'l' || jkRaw.contains('laki');
    String kelamin = isLakiLaki ? 'Laki-Laki' : 'Perempuan';

    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaMurni,
                      style: TextStyle(
                        color: _bgHitam,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$kelamin • $teksUsia',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_daftarAnak.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _anakTerpilihIndeks =
                          (_anakTerpilihIndeks + 1) % _daftarAnak.length;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, color: _primaryBlue),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.verified, color: _primaryBlue),
                ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      color: _surfaceContainer,
                    ),
                    CircularProgressIndicator(
                      value: 0.75,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: ringColor,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              statusGizi,
                              style: TextStyle(
                                color: _bgHitam,
                                fontSize: statusGizi.length > 8 ? 12 : 16, // Penyesuaian font jika teksnya panjang
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status Gizi',
                            style: TextStyle(
                              color: _outlineColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12), 

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _surfaceContainer),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.height,
                          color: _primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8), 
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TINGGI BADAN',
                              style: TextStyle(
                                color: _outlineColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    tinggiBadan,
                                    style: TextStyle(
                                      color: _bgHitam,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'cm',
                                  style: TextStyle(
                                    color: _outlineColor,
                                    fontSize: 12,
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
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            'Pembaruan terakhir: $tglPeriksa',
            style: TextStyle(color: _outlineColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCepat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKSI CEPAT',
          style: TextStyle(
            color: _bgHitam,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CekStuntingPage(
                        isIbuDataComplete: _isProfilIbuLengkap,
                        daftarAnak: _daftarAnak,
                      ),
                    ),
                  ).then((_) => _fetchProfilDanAnak());
                },
                child: Container(
                  width: 150,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.add_chart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const Text(
                        'Cek Gizi\nSekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: Container(
                  width: 150,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _surfaceContainer),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryFixed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: _primaryBlue,
                          size: 20,
                        ),
                      ),
                      Text(
                        'Rekomendasi\nResep',
                        style: TextStyle(
                          color: _bgHitam,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsHarian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspirasi Harian',
                  style: TextStyle(
                    color: _bgHitam,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tips untuk tumbuh kembang optimal',
                  style: TextStyle(color: _outlineColor, fontSize: 14),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: _primaryBlue,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingInspirasi)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_daftarInspirasi.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Belum ada tips hari ini.',
                style: TextStyle(color: _outlineColor),
              ),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: _daftarInspirasi.length,
              itemBuilder: (context, index) {
                final artikel = _daftarInspirasi[index];
                final bool hasImage =
                    artikel['url_gambar'] != null &&
                    artikel['url_gambar'].toString().isNotEmpty;
                final String kategori = artikel['kategori'] ?? 'Umum';

                return GestureDetector(
                  onTap: () async {
                    if (artikel['url_sumber'] != null &&
                        artikel['url_sumber'].toString().isNotEmpty) {
                      final url = Uri.parse(artikel['url_sumber']);
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        print("Could not launch $url: $e");
                      }
                    } else if (artikel['konten_lengkap'] != null &&
                        artikel['konten_lengkap'].toString().isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(artikel['judul']),
                          content: SingleChildScrollView(
                            child: Text(artikel['konten_lengkap']),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: _primaryFixed,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (hasImage)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                  child: Image.network(
                                    artikel['url_gambar'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: _primaryBlue.withOpacity(
                                              0.5,
                                            ),
                                            size: 40,
                                          ),
                                        ),
                                  ),
                                ),
                              if (!hasImage)
                                Center(
                                  child: Icon(
                                    Icons.article,
                                    color: _primaryBlue.withOpacity(0.5),
                                    size: 40,
                                  ),
                                ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    kategori,
                                    style: TextStyle(
                                      color: _primaryBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artikel['judul'] ?? 'Tips',
                                  style: TextStyle(
                                    color: _bgHitam,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  artikel['deskripsi_singkat'] ?? '',
                                  style: TextStyle(
                                    color: _outlineColor,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}