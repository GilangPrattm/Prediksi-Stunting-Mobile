import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'services/auth_service.dart';
import 'login_page.dart';
import 'tambah_anak_page.dart';
import 'edit_anak_page.dart'; // Import File Edit Ini
import 'profil_page.dart';
import 'lengkapi_profil_page.dart'; // Import Form Wajib Ini
import 'config/api_config.dart'; // Import File Sentral
import 'cek_gizi_bottom_sheet.dart'; // Import file popup gizi
import 'chatbot_page.dart'; // Asisten Pintar AI
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 
  final String _baseUrl = ApiConfig.baseUrl; // Gunakan IP Sentral

  List<dynamic> _daftarAnak = [];
  bool _isLoadingAnak = true; 
  int _anakTerpilihIndeks = 0;
  String _namaBunda = 'Bunda';
  List<dynamic> _daftarResep = [];

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
      // 0. JEBAKAN BATMAN: Cek apakah Profil Ibu sudah diisi?
      final resCekIbu = await http.get(Uri.parse('$_baseUrl/profil-ibu'), headers: {'Authorization': 'Bearer $token'});
      if (resCekIbu.statusCode == 404) {
        if (!mounted) return;
        // Lempar paksa ke Halaman Wajib Isi Data Ibu
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LengkapiProfilPage()));
        return; // Jangan eksekusi sedot data lainnya!
      }

      // 1. Tarik Nama Ibu
      final resProfil = await http.get(Uri.parse('$_baseUrl/profil'), headers: {'Authorization': 'Bearer $token'});
      if (resProfil.statusCode == 200) {
        final dataProfil = jsonDecode(resProfil.body);
        setState(() {
          _namaBunda = dataProfil['data']['name'] ?? 'Bunda';
        });
      }

      // 2. Tarik Data Anak Asli dari Tabel MongoDB
      final resAnak = await http.get(Uri.parse('$_baseUrl/anak'), headers: {'Authorization': 'Bearer $token'});
      if (resAnak.statusCode == 200) {
        final dataAnak = jsonDecode(resAnak.body);
        setState(() {
          _daftarAnak = dataAnak['data'];
          _isLoadingAnak = false;
        });
      } else {
        setState(() => _isLoadingAnak = false);
      }

      // 3. Tarik Rekomendasi Menu Resep
      final resMakanan = await http.get(Uri.parse('$_baseUrl/makanan'), headers: {'Authorization': 'Bearer $token'});
      if (resMakanan.statusCode == 200) {
        setState(() {
          _daftarResep = jsonDecode(resMakanan.body)['data'];
        });
      }

    } catch (e) {
      print("Gagal Mengambil Data Asli: $e");
      setState(() => _isLoadingAnak = false);
    }
  }

  // Fungsi Pembantu Komputasi Umur Cerdas (Dari Tanggal Lahir ke Format: X Tahun Y Bulan)
  String _hitungUmur(String? tglLahirStr) {
    if (tglLahirStr == null || tglLahirStr.isEmpty) return 'Umur Tidak Diketahui';
    try {
      DateTime birthDate = DateTime.parse(tglLahirStr);
      DateTime today = DateTime.now();
      int months = (today.year - birthDate.year) * 12 + today.month - birthDate.month;
      if (today.day < birthDate.day) {
        months--;
      }
      if (months <= 0) return 'Baru Lahir';
      if (months < 12) return '$months Bulan';
      int years = months ~/ 12;
      int remainingMonths = months % 12;
      return remainingMonths == 0 ? '$years Tahun' : '$years Tahun $remainingMonths Bulan';
    } catch (e) {
      return '-';
    }
  }

  int _dapatkanUmurBulan(String? tglLahirStr) {
    if (tglLahirStr == null || tglLahirStr.isEmpty) return 0;
    try {
      DateTime birthDate = DateTime.parse(tglLahirStr);
      DateTime today = DateTime.now();
      int months = (today.year - birthDate.year) * 12 + today.month - birthDate.month;
      if (today.day < birthDate.day) {
        months--;
      }
      return months < 0 ? 0 : months;
    } catch (e) {
      return 0;
    }
  }

  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
  }

  // ==== WIDGET FOOTER TAB: 0 (BERANDA UTAMA) ====
  Widget _buildBeranda(Color primaryColor) {
    bool hasData = !_isLoadingAnak && _daftarAnak.isNotEmpty;
    // Cek Peringatan Timbang
    bool belumDiperiksaBulanIni = false;
    if (hasData) {
      String? tgl = _daftarAnak[_anakTerpilihIndeks]['tgl_pemeriksaan'];
      if (tgl != null && tgl.isNotEmpty) {
        try {
          DateTime lastCheck = DateTime.parse(tgl);
          DateTime now = DateTime.now();
          if (lastCheck.year != now.year || lastCheck.month != now.month) {
            belumDiperiksaBulanIni = true;
          }
        } catch (_) {}
      } else {
        belumDiperiksaBulanIni = true;
      }
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchProfilDanAnak,
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Stack(
              children: [
                Container(
                  height: 250,
                  decoration: BoxDecoration(color: primaryColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40))),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100')),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Halo,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    Text('Bunda $_namaBunda', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() { _selectedIndex = 3; });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 30),
                        
                        _isLoadingAnak 
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : (_daftarAnak.isNotEmpty ? _buildKartuAnakAda(primaryColor) : _buildKartuAnakKosong(primaryColor)),
                        
                        if (hasData && belumDiperiksaBulanIni)
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.shade200)),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
                                const SizedBox(width: 15),
                                Expanded(child: Text('Bunda, anak belum timbang bulan ini lho. Yuk catat perkembangannya sekarang!', style: TextStyle(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),

                        const SizedBox(height: 30),
                        const Text('Tips Gizi Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        
                        _buildTipsCard('Protein Hewani Wajib MPASI', 'Mencegah stunting dengan telur dan ikan setiap hari.', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'),
                        const SizedBox(height: 12),
                        _buildTipsCard('Menjaga Kebersihan Air', 'Air dengan kuman memicu infeksi dan hambat tumbuh kembang.', 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400'),
                        const SizedBox(height: 80), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // --- Floating Chatbot AI Kanan Bawah ---
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF06B6D4), // Cyan muda khas chatbot medis
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Agak membulat
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotPage()));
            },
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(String title, String subtitle, String imgUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(imgUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                 const SizedBox(height: 4),
                 Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
               ]
            )
          )
        ]
      )
    );
  }

  // ==== WIDGET TAB: 1 (RIWAYAT GRAFIK) ====
  Widget _buildPantauTumbuhKembang() {
    // Pastikan warna konsisten
    const Color primaryColor = Color(0xFF2563EB);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Pertumbuhan Grafik', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            const Text('Status grafik berat badan berdasarkan usia (WHO)', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 30),
            
            // Box Grafik (Dihilangkan Datanya)
            Container(
              height: 250,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))]),
              child: const Center(
                child: Text(
                  'Belum ada data grafik.\nLakukan Cek Gizi untuk mulai menggambar grafik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Data Historis Bulanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('Riwayat kosong...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    )
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String bulan, String bb, String tb, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.history, color: statusColor, size: 20)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bulan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('BB: $bb | TB: $tb', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      )
    );
  }

  // ==== WIDGET TAB: 2 (RESEP) ====
  Widget _buildEdukasiResep() {
    bool adaAnakBeresiko = false;
    if (_daftarAnak.isNotEmpty) {
      String statusGiziRaw = _daftarAnak[_anakTerpilihIndeks]['status_gizi'] ?? ( (_daftarAnak[_anakTerpilihIndeks]['tinggi_badan'] != null && (_daftarAnak[_anakTerpilihIndeks]['tinggi_badan'] as num) < 65) ? 'Beresiko' : 'Baik' );
      adaAnakBeresiko = statusGiziRaw.toLowerCase().contains('beresiko') || statusGiziRaw.toLowerCase().contains('kurang');
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Menu Nutrisi & MPASI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text(adaAnakBeresiko ? 'Difilter Cerdas: Mode Kejar Tumbuh (Tinggi Protein)' : 'Rekomendasi harian kaya nutrisi', style: TextStyle(fontSize: 13, color: adaAnakBeresiko ? Colors.orange[800] : Colors.grey, fontWeight: adaAnakBeresiko ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  if (adaAnakBeresiko)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                      child: const Row(children: [Icon(Icons.auto_awesome, color: Colors.orange, size: 20), SizedBox(width: 8), Expanded(child: Text('AI merekomendasikan resep di bawah ini khusus untuk mempercepat pertumbuhan.', style: TextStyle(color: Colors.orange, fontSize: 12)))]),
                    ),

                  ..._daftarResep.map((resep) => Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: _buildRecipeCard(resep['nama_makanan'] ?? 'Menu Bergizi', 'Bagus (AI)', 'Cek Detail', '-', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'),
                      )).toList(),
                  if (_daftarResep.isEmpty)
                    _buildRecipeCard('Bubur Hati Ayam Lodeh (Contoh)', 'Bagus (AI)', '150 Kkal', '20 mnt', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'),
                ],
              ),
            )
          ]
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2563EB);

    final List<Widget> pages = [
      _buildBeranda(primaryColor),
      _buildPantauTumbuhKembang(),
      _buildEdukasiResep(),
      const ProfilPage(), 
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),
      floatingActionButtonLocation: null,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        clipBehavior: Clip.none, // Ubah ke none agar tombol custom melayang sempurna tidak terpotong
        elevation: 20,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.receipt_long, label: 'Riwayat', index: 1),
              
              // Custom Middle FAB (Anti-Keangkat Snackbar)
              GestureDetector(
                onTap: () {
                  if (_daftarAnak.isNotEmpty) {
                    var anakAktif = _daftarAnak[_anakTerpilihIndeks];
                    int umurBulanAsli = _dapatkanUmurBulan(anakAktif['tgl_lahir']);
                    tampilDialogCekGizi(context, anakAktif, umurBulanAsli, _fetchProfilDanAnak);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Tambahkan data anak terlebih dahulu!'), 
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating, // Floating behavior
                    ));
                  }
                },
                child: Container(
                  height: 55,
                  width: 55,
                  transform: Matrix4.translationValues(0.0, -15.0, 0.0), // Melayang di atas navbar
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                    ],
                  ),
                  child: const Icon(Icons.monitor_weight, color: Colors.white, size: 28),
                ),
              ),
              
              _buildNavItem(icon: Icons.restaurant_menu, label: 'Resep', index: 2),
              _buildNavItem(icon: Icons.person_outline, label: 'Profil', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    bool isSelected = _selectedIndex == index;
    Color color = isSelected ? const Color(0xFF2563EB) : Colors.black54; // Biru menyala jika aktif
    
    return MaterialButton(
      minWidth: 50, // Melebarkan tap target area
      padding: EdgeInsets.zero, // Hapus padding default agar lebih rapat ke tengah
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildKartuAnakKosong(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Icon(Icons.child_care, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 15),
          const Text('Belum Ada Data Anak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Yuk Bunda, lengkapi data si kecil untuk mulai memantau tumbuh kembangnya.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { 
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahAnakPage())).then((_) {
                  // Tarik data lagi secara otomatis jika Ibu baru saja mendaftarkan Anak dari layar "Tambah Anak"
                  _fetchProfilDanAnak();
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Tambah Data Anak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // TAMPILAN JIKA ADA DATA (Murni Menyedot JSON dari MongoDB API)
  Widget _buildKartuAnakAda(Color primaryColor) {
    var anakAktif = _daftarAnak[_anakTerpilihIndeks];
    
    // Kalkulasi Data Mentah Database Jadi Tampilan Cantik
    String namaMurni = anakAktif['nama_anak'] ?? 'Tanpa Nama';
    String teksUmur = _hitungUmur(anakAktif['tgl_lahir']);
    String tglPeriksaAsli = anakAktif['tgl_pemeriksaan'] ?? 'Belum Diperiksa';
    String tinggiBadanAsli = anakAktif['tinggi_badan']?.toString() ?? '0';
    String beratBadanAsli = anakAktif['berat_badan']?.toString() ?? '0';
    
    // Fallback status gizi mockup (beresiko jika tinggi kurang dari 65 misal)
    String statusGiziRaw = anakAktif['status_gizi'] ?? ( (anakAktif['tinggi_badan'] != null && (anakAktif['tinggi_badan'] as num) < 65) ? 'Beresiko' : 'Baik' );
    bool isBeresiko = statusGiziRaw.toLowerCase().contains('beresiko') || statusGiziRaw.toLowerCase().contains('kurang') || statusGiziRaw.toLowerCase().contains('pendek');
    
    Color accentColor = isBeresiko ? Colors.orange : primaryColor;
    Color bgCardColor = isBeresiko ? Colors.orange.shade50 : Colors.white;
    Color borderCardColor = isBeresiko ? Colors.orange.shade300 : Colors.transparent;

    return Container(
      decoration: BoxDecoration(color: bgCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: borderCardColor, width: 1.5), boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isBeresiko ? Colors.orange.shade200 : Colors.grey.shade100))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_daftarAnak.length + 1, (index) {
                  // Jika index mencapai panjang daftar, render tombol (+)
                  if (index == _daftarAnak.length) {
                    return IconButton(
                      icon: Icon(Icons.add_circle, color: primaryColor, size: 35),
                      onPressed: () { 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahAnakPage())).then((_) => _fetchProfilDanAnak());
                      },
                    );
                  }
                  bool isSelected = index == _anakTerpilihIndeks;
                  return GestureDetector(
                    onTap: () { setState(() { _anakTerpilihIndeks = index; }); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: isSelected ? accentColor.withValues(alpha: isBeresiko ? 0.2 : 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? accentColor : (isBeresiko ? Colors.orange.shade200 : Colors.grey.shade300))),
                      child: Row(
                        children: [
                          Icon(Icons.face, size: 16, color: isSelected ? accentColor : Colors.grey),
                          const SizedBox(width: 5),
                          Text(_daftarAnak[index]['nama_anak'] ?? 'Anak', style: TextStyle(color: isSelected ? accentColor : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(namaMurni, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(teksUmur, style: TextStyle(color: isBeresiko ? Colors.orange[800] : Colors.grey)),
                          const SizedBox(height: 5),
                          Row(children: [Icon(Icons.event_available, size: 12, color: accentColor), const SizedBox(width: 4), Text('Tgl Periksa: $tglPeriksaAsli', style: TextStyle(fontSize: 11, color: accentColor))]),
                          const SizedBox(height: 10),
                          // Badge Status Gizi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: isBeresiko ? Colors.orange : Colors.green, borderRadius: BorderRadius.circular(10)),
                            child: Text('Status: ${statusGiziRaw.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => EditAnakPage(dataAnak: anakAktif))).then((_) => _fetchProfilDanAnak());
                      },
                      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (isBeresiko ? Colors.orange.shade100 : Colors.cyan[50]), shape: BoxShape.circle), child: Icon(Icons.edit, color: isBeresiko ? Colors.orange.shade800 : Colors.cyan[400], size: 20)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildIndicator('TINGGI BADAN', '$tinggiBadanAsli cm', Icons.straighten, Colors.blue)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildIndicator('BERAT BADAN', '$beratBadanAsli kg', Icons.monitor_weight_outlined, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () { 
                      int umurBulanAsli = _dapatkanUmurBulan(anakAktif['tgl_lahir']);
                      tampilDialogCekGizi(context, anakAktif, umurBulanAsli, _fetchProfilDanAnak);
                    },
                    icon: Icon(Icons.psychology, color: primaryColor),
                    label: Text('Cek Status Gizi (AI)', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIndicator(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 5),
              Icon(icon, color: iconColor, size: 16),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecipeCard(String title, String rating, String cal, String time, String imgUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(imgUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image_not_supported))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), const SizedBox(width: 5), Text(rating, style: const TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 5),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.cyan[50], borderRadius: BorderRadius.circular(8)), child: Text(cal, style: TextStyle(color: Colors.cyan[700], fontSize: 11, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Row(children: [const Icon(Icons.access_time, color: Colors.grey, size: 14), const SizedBox(width: 4), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
