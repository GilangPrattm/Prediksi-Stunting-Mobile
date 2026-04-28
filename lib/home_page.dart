import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'tambah_anak_page.dart';
import 'profil_page.dart';
import 'edit_profil_page.dart';
import 'config/api_config.dart';
import 'cek_gizi_bottom_sheet.dart';
import 'cek_stunting_page.dart';
import 'chatbot_page.dart';
import 'hasil_prediksi_page.dart';
import 'riwayat_page.dart';

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

      // Ambil histori prediksi dari server
      final resHistori = await http.get(
        Uri.parse('$_baseUrl/prediksi'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resHistori.statusCode == 200) {
        final dataHistori = jsonDecode(resHistori.body);
        setState(() {
          _daftarHistoriPrediksi = (dataHistori['data'] as List)
              .reversed
              .toList(); // Terbaru di atas
          _isLoadingHistori = false;
        });
      } else {
        setState(() => _isLoadingHistori = false);
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

  int _dapatkanUmurBulan(String? tglLahirStr) {
    if (tglLahirStr == null || tglLahirStr.isEmpty) return 0;
    try {
      DateTime birthDate = DateTime.parse(tglLahirStr);
      DateTime today = DateTime.now();
      int months =
          (today.year - birthDate.year) * 12 + today.month - birthDate.month;
      if (today.day < birthDate.day) {
        months--;
      }
      return months < 0 ? 0 : months;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // List layar dengan 5 elemen.
    // Index 1 (Cek Stunting) di-intercept → tidak render halaman, hanya buka bottom sheet.
    // Riwayat Prediksi diakses via ikon di header beranda.
    final List<Widget> pages = [
      _buildBeranda(),
      RiwayatPage(daftarAnak: _daftarAnak), // Index 1: Riwayat Prediksi
      const SizedBox(), // Index 2: Prediksi (Di-intercept)
      _buildEdukasiResep(), // Index 3: MPASI
      const ProfilPage(), // Index 4: Akun Saya
    ];

    const Color primaryColor = Color(0xFFBFDBFE);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotPage()),
          );
        },
        backgroundColor: const Color(0xFFBFDBFE),
        child: const Icon(Icons.smart_toy, color: Color(0xFF1E293B)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1E293B),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 10,
        ),
        elevation: 20,
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CekStuntingPage(
                  isIbuDataComplete: _isProfilIbuLengkap,
                  daftarAnak: _daftarAnak,
                ),
              ),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Prediksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'MPASI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun Saya',
          ),
        ],
      ),
    );
  }

  // ==== WIDGET TAB 0: BERANDA ====
  Widget _buildBeranda() {
    bool hasData = !_isLoadingAnak && _daftarAnak.isNotEmpty;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchProfilDanAnak,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER TEAL + KARTU ANAK (layout tanpa Stack overflow)
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Header background
                  _buildHeaderSesuaiGambar(),

                  // Kartu anak mengambang di bawah header
                  Positioned(
                    top: 110,
                    left: 20,
                    right: 20,
                    child: _isLoadingAnak
                        ? const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : (hasData
                              ? _buildKartuAnakSesuaiGambar()
                              : _buildKartuAnakKosong()),
                  ),
                ],
              ),

              // Spacer agar konten di bawah tidak bertabrakan dengan kartu yang mengambang
              const SizedBox(height: 160),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Banner Waktunya Cek Gizi!
                      if (hasData)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 25),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBFDBFE), // Light Blue
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFBFDBFE).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Waktunya Cek Gizi!',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pastikan tumbuh kembang si kecil sesuai dengan usianya.',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CekStuntingPage(
                                        isIbuDataComplete: _isProfilIbuLengkap,
                                        daftarAnak: _daftarAnak,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Cek Gizi Sekarang',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.chevron_right, size: 18, color: Color(0xFF1E293B)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Tips Area
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tips Hari Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      _buildTipsCardLama(
                        'Pentingnya Sayur Hijau untuk Anak',
                        'Oleh Dr. Kila • 3 min read',
                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                      ),
                      const SizedBox(height: 12),
                      _buildTipsCardLama(
                        'Pola Tidur yang Memicu Pertumbuhan',
                        'Oleh Dr. Kila • 5 min read',
                        'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400',
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  // --- KOMPONEN HEADER BARU ---
  Widget _buildHeaderSesuaiGambar() {
    String displayNama = _namaBunda.isNotEmpty ? _namaBunda : 'Bunda';

    return Container(
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFBFDBFE), // Solid Light Blue
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Mini
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Pagi,',
                        style: TextStyle(
                          color: Color(0xFF1E293B).withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Halo, Bunda $displayNama!',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Notifikasi Bell
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1E293B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN KARTU ANAK BARU MURNI DARI GAMBAR ---
  Widget _buildKartuAnakSesuaiGambar() {
    var anakAktif = _daftarAnak[_anakTerpilihIndeks];

    String namaMurni = anakAktif['nama_anak'] ?? 'Tanpa Nama';
    String teksUsia = _hitungUmur(anakAktif['tgl_lahir']);
    String tglPeriksaAsli = anakAktif['tgl_pemeriksaan'] != null
        ? 'Terakhir diperbarui: ${anakAktif['tgl_pemeriksaan']}'
        : 'Belum pernah dicek';
    String tinggiBadanAsli = anakAktif['tinggi_badan']?.toString() ?? '-';
    String beratBadanAsli = anakAktif['berat_badan']?.toString() ?? '-';
    // Case-insensitive check untuk semua variasi penulisan jenis kelamin
    final String jkRaw = (anakAktif['jenis_kelamin'] ?? '').toString().toLowerCase();
    final bool isLakiLaki = jkRaw == 'l' || jkRaw.contains('laki');
    String kelamin = isLakiLaki ? 'LAKI-LAKI' : 'PEREMPUAN';
    Color warnaBadgeKelamin = isLakiLaki
        ? const Color(0xFFDBEAFE) // Biru muda untuk laki-laki
        : const Color(0xFFFCE7F3); // Pink muda untuk perempuan
    Color warnaTeksBadge = isLakiLaki
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF9D174D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nama + Badge Kelamin
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        namaMurni,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: warnaBadgeKelamin,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        kelamin,
                        style: TextStyle(
                          color: warnaTeksBadge,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigasi Anak: hanya tampil jika ada lebih dari 1 anak
              if (_daftarAnak.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _anakTerpilihIndeks =
                          (_anakTerpilihIndeks + 1) % _daftarAnak.length;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBFDBFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_anakTerpilihIndeks + 1}/${_daftarAnak.length}',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, color: Color(0xFF1E293B), size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            tglPeriksaAsli,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox(Icons.calendar_today_outlined, 'USIA', teksUsia),
              _buildStatBox(
                Icons.monitor_weight_outlined,
                'BERAT',
                '$beratBadanAsli kg',
                iconColor: Colors.orange,
              ),
              _buildStatBox(
                Icons.height_outlined,
                'TINGGI',
                '$tinggiBadanAsli cm',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    IconData icon,
    String title,
    String value, {
    Color iconColor = const Color(0xFF1E293B),
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKartuAnakKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.child_care, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          const Text(
            'Lengkapi Data Diri Anda dan Buah Hati Anda',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mohon lengkapi data diri dan data anak Anda untuk memulai pantau tumbuh kembang.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              if (!_isProfilIbuLengkap) {
                _tampilkanDialogLengkapiProfil();
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
              backgroundColor: const Color(0xFFBFDBFE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Lengkapi Data',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tampilkanDialogLengkapiProfil() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          contentPadding: const EdgeInsets.all(25),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_outlined,
                  color: Colors.orange,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tunggu Sebentar, Bunda!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Untuk memastikan akurasi pantauan gizi si kecil, pastikan data diri Bunda sudah diisi dengan lengkap ya.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfilPage(),
                      ),
                    ).then((_) => _fetchProfilDanAnak());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFDBFE),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Lengkapi Profil Sekarang',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Nanti Saja',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipsCardLama(String title, String subtitle, String imgUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imgUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==== WIDGET TAB 1: RIWAYAT PREDIKSI ====
  Widget _buildPantauTumbuhKembang() {
    // Hitung statistik ringkas
    int jmlNormal = _daftarHistoriPrediksi.where((e) =>
        (e['hasil_prediksi'] ?? '').toString().toLowerCase().contains('normal')).length;
    int jmlBerisiko = _daftarHistoriPrediksi.where((e) =>
        (e['hasil_prediksi'] ?? '').toString().toLowerCase().contains('berisiko')).length;
    int jmlStunting = _daftarHistoriPrediksi.where((e) =>
        (e['hasil_prediksi'] ?? '').toString().toLowerCase().contains('stunting') &&
        !(e['hasil_prediksi'] ?? '').toString().toLowerCase().contains('berisiko')).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFBFDBFE),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Prediksi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analisis stunting oleh Kila AI · ${_daftarHistoriPrediksi.length} pemeriksaan',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1E293B).withOpacity(0.7),
                  ),
                ),
                if (_daftarHistoriPrediksi.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildStatChip('Normal', jmlNormal, const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildStatChip('Berisiko', jmlBerisiko, const Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      _buildStatChip('Stunting', jmlStunting, const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Isi Riwayat
          Expanded(
            child: _isLoadingHistori
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFBFDBFE)))
                : _daftarHistoriPrediksi.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 15),
                            const Text(
                              'Belum Ada Riwayat Prediksi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Lakukan Cek Stunting terlebih dahulu\nuntuk melihat hasil analisis AI di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchProfilDanAnak,
                        color: const Color(0xFFBFDBFE),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _daftarHistoriPrediksi.length,
                          itemBuilder: (context, index) {
                            return _buildKartuHistori(_daftarHistoriPrediksi[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildKartuHistori(Map<String, dynamic> item) {
    final String hasil = item['hasil_prediksi'] ?? 'Tidak diketahui';
    final String namaAnak = item['anak'] is Map
        ? (item['anak']['nama_anak'] ?? '-')
        : '-';
    final String idAnak = item['anak'] is Map
        ? (item['anak']['_id'] ?? item['anak']['id'] ?? '')
        : (item['id_anak'] ?? '');
    final String tanggal = item['tanggal_prediksi'] ?? item['created_at'] ?? '-';
    final double probabilitas =
        ((item['probabilitas']) as num?)?.toDouble() ?? 0.0;

    Color warnaBg;
    Color warnaText;
    IconData ikon;

    final String hasilLower = hasil.toLowerCase();
    if (hasilLower.contains('normal') && !hasilLower.contains('berisiko') && !hasilLower.contains('stunting')) {
      warnaBg = const Color(0xFFDCFAE6);
      warnaText = const Color(0xFF166534);
      ikon = Icons.check_circle_rounded;
    } else if (hasilLower.contains('berisiko') || hasilLower.contains('resiko') || hasilLower.contains('risiko')) {
      warnaBg = const Color(0xFFFFF7CD);
      warnaText = const Color(0xFF92400E);
      ikon = Icons.warning_amber_rounded;
    } else {
      warnaBg = const Color(0xFFFFE4E4);
      warnaText = const Color(0xFF991B1B);
      ikon = Icons.dangerous_rounded;
    }

    // Cari data anak lengkap dari _daftarAnak berdasarkan idAnak
    final anakData = _daftarAnak.firstWhere(
      (a) => (a['_id'] ?? a['id'] ?? '').toString() == idAnak,
      orElse: () => <String, dynamic>{},
    );

    return GestureDetector(
      onTap: () {
        // Tap kartu → lihat detail hasil prediksi
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HasilPrediksiPage(
              namaAnak: namaAnak,
              keterangan: hasil,
              probabilitas: probabilitas,
              beratBadan: (anakData['berat_badan'] as num?)?.toDouble(),
              tinggiBadan: (anakData['tinggi_badan'] as num?)?.toDouble(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: ikon + nama + badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: warnaBg, shape: BoxShape.circle),
                  child: Icon(ikon, color: warnaText, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaAnak,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tanggal.toString().split('T').first,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: warnaBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasil,
                    style: TextStyle(color: warnaText, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),

            // Probabilitas bar
            if (probabilitas > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Keyakinan AI:',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: probabilitas,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(warnaText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(probabilitas * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: warnaText,
                    ),
                  ),
                ],
              ),
            ],

            // Tombol Prediksi Ulang (hanya jika data anak ditemukan)
            if (idAnak.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // Buka CekStuntingPage dengan anak ini sudah terpilih
                  final List<dynamic> anakList = anakData.isNotEmpty
                      ? [anakData]
                      : _daftarAnak.where((a) =>
                          (a['_id'] ?? a['id'] ?? '').toString() == idAnak).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CekStuntingPage(
                        isIbuDataComplete: true,
                        daftarAnak: anakList.isNotEmpty ? anakList : _daftarAnak,
                      ),
                    ),
                  ).then((_) => _fetchProfilDanAnak());
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 15, color: warnaText),
                    const SizedBox(width: 6),
                    Text(
                      'Prediksi Ulang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: warnaText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==== WIDGET TAB 2: RESEP ====
  Widget _buildEdukasiResep() {
    bool adaAnakBeresiko = false;
    if (_daftarAnak.isNotEmpty) {
      String statusGiziRaw =
          _daftarAnak[_anakTerpilihIndeks]['status_gizi'] ??
          ((_daftarAnak[_anakTerpilihIndeks]['tinggi_badan'] != null &&
                  (_daftarAnak[_anakTerpilihIndeks]['tinggi_badan'] as num) <
                      65)
              ? 'Beresiko'
              : 'Baik');
      adaAnakBeresiko =
          statusGiziRaw.toLowerCase().contains('beresiko') ||
          statusGiziRaw.toLowerCase().contains('kurang');
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menu Nutrisi & MPASI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              adaAnakBeresiko
                  ? 'Difilter Cerdas: Mode Kejar Tumbuh (Tinggi Protein)'
                  : 'Rekomendasi harian kaya nutrisi',
              style: TextStyle(
                fontSize: 13,
                color: adaAnakBeresiko ? Colors.orange[800] : Colors.grey,
                fontWeight: adaAnakBeresiko
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (adaAnakBeresiko)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI merekomendasikan resep di bawah ini khusus untuk mempercepat pertumbuhan.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ..._daftarResep.map(
                    (resep) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildRecipeCardLama(
                        resep['nama_makanan'] ?? 'Menu Bergizi',
                        'Bagus (AI)',
                        'Cek Detail',
                        '-',
                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                      ),
                    ),
                  ),
                  if (_daftarResep.isEmpty)
                    _buildRecipeCardLama(
                      'Bubur Hati Ayam Lodeh (Contoh)',
                      'Bagus (AI)',
                      '150 Kkal',
                      '20 mnt',
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCardLama(
    String title,
    String rating,
    String cals,
    String time,
    String imgUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imgUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 70,
                height: 70,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cals,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.timer, color: Colors.grey, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
