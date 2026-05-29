import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'tambah_anak_page.dart';
import 'cek_stunting_page.dart';

class MpasiPage extends StatefulWidget {
  final List<dynamic> daftarAnak;
  final int anakTerpilihIndeks;

  const MpasiPage({
    super.key,
    required this.daftarAnak,
    required this.anakTerpilihIndeks,
  });

  @override
  State<MpasiPage> createState() => _MpasiPageState();
}

class _MpasiPageState extends State<MpasiPage> {
  // --- TEMA WARNA BIRU KONSISTEN ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _cardBg = Colors.white;

  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  List<String> _filters = [
    'Semua',
    'Protein Tinggi',
    'Zat Besi & Energi',
    'Serat & Vitamin',
    'Lemak Sehat',
  ];

  bool _isLoading = true;
  List<Map<String, dynamic>> _semuaResep = [];

  // --- DATABASE MOCK RESEP MPASI PREMIUM ---
  final List<Map<String, dynamic>> _mockResepList = [
    {
      'kategori': 'Protein Tinggi',
      'nama_makanan': 'Bubur Halus Salmon & Kentang',
      'deskripsi':
          'Sumber lemak sehat omega-3 dari salmon yang dipadukan dengan kentang lembut sangat baik untuk perkembangan otak dan sel tubuh si Kecil.',
      'img': 'assets/images/mpasi_ikan.png',
      'porsi': '2 Porsi',
      'waktu': '25 Menit',
      'bahan': [
        '50g Daging Salmon Fillet (cincang halus)',
        '1 buah Kentang Ukuran Sedang (kupas, potong dadu)',
        '1 sdm ASI atau Susu Formula',
        '1 sdt Unsalted Butter (UB)',
        'Air secukupnya untuk mengukus',
      ],
      'langkah': [
        'Kukus kentang dadu hingga empuk (sekitar 15 menit).',
        'Tambahkan cincangan salmon pada 5 menit terakhir proses mengukus.',
        'Haluskan kentang dan salmon kukus menggunakan blender makanan bayi atau saringan kawat.',
        'Campurkan ASI/susu formula dan mentega tanpa garam (unsalted butter) selagi hangat.',
        'Aduk rata hingga teksturnya pas untuk disajikan hangat.',
      ],
      'manfaat':
          'Kaya akan protein premium, Omega-3 (DHA/EPA), dan Vitamin D untuk pertumbuhan fisik dan kognitif optimal.',
    },
    {
      'kategori': 'Zat Besi & Energi',
      'nama_makanan': 'Purée Daging Sapi & Wortel Manis',
      'deskripsi':
          'Daging sapi kaya zat besi mudah diserap dikombinasikan dengan wortel manis alami untuk membantu mencegah anemia dan memperkuat kekebalan tubuh.',
      'img': 'assets/images/mpasi_daging.png',
      'porsi': '2 Porsi',
      'waktu': '30 Menit',
      'bahan': [
        '50g Daging Sapi Giling Rendah Lemak',
        '1/2 batang Wortel Organik (kupas, iris tipis)',
        '1 siung Bawang Putih (untuk aroma, geprek saja)',
        '1 sdt Minyak Zaitun (Extra Virgin Olive Oil)',
      ],
      'langkah': [
        'Rebus daging giling dengan sedikit air bersama bawang putih geprek hingga matang dan empuk.',
        'Kukus wortel hingga sangat lunak di wadah terpisah.',
        'Tiriskan daging sapi (buang bawang putih) dan blender bersama wortel hingga lembut merata.',
        'Tambahkan sedikit air sisa rebusan untuk menyesuaikan kekentalan bubur.',
        'Sajikan dengan tambahan beberapa tetes minyak zaitun hangat.',
      ],
      'manfaat':
          'Tinggi Zat Besi (Heme Iron), Seng, Vitamin A, dan Beta-Karoten untuk meningkatkan daya tahan tubuh anak.',
    },
    {
      'kategori': 'Serat & Vitamin',
      'nama_makanan': 'Bubur Saring Hati Ayam & Bayam Merah',
      'deskripsi':
          'Hati ayam kaya akan vitamin A dan zat besi dikombinasikan dengan bayam merah lembut untuk merangsang produksi sel darah merah baru.',
      'img': 'assets/images/mpasi_ayam.png',
      'porsi': '1 Porsi',
      'waktu': '20 Menit',
      'bahan': [
        '1 buah Hati Ayam Segar (bersihkan lemaknya)',
        '5-7 lembar Daun Bayam Merah (cuci bersih)',
        '2 sdm Beras Putih Organik',
        'Air kaldu ayam secukupnya',
      ],
      'langkah': [
        'Masak beras putih bersama air kaldu hingga menjadi bubur lembek.',
        'Rebus hati ayam secara terpisah hingga benar-benar matang sempurna.',
        'Masukkan bayam merah ke dalam bubur nasi 2 menit sebelum kompor dimatikan agar nutrisi bayam terjaga.',
        'Haluskan hati ayam matang bersama bubur nasi bayam menggunakan saringan kawat hingga lembut.',
        'Sajikan hangat-hangat kepada si Kecil.',
      ],
      'manfaat':
          'Kombinasi zat besi hewani tingkat tinggi dan folat nabati yang sangat baik untuk memperlancar metabolisme tubuh.',
    },
    {
      'kategori': 'Lemak Sehat',
      'nama_makanan': 'Susu Alpukat & Pisang Lumat',
      'deskripsi':
          'Kombinasi manis pisang raja dengan kelembutan buah alpukat mentega kaya lemak nabati sangat efektif untuk meningkatkan berat badan anak.',
      'img': 'assets/images/mpasi_buah.png',
      'porsi': '1 Porsi',
      'waktu': '10 Menit',
      'bahan': [
        '1/2 buah Alpukat Mentega Matang',
        '1/2 buah Pisang Ambon atau Pisang Raja Matang',
        '2-3 sdm ASI atau Susu Formula hangat',
      ],
      'langkah': [
        'Keruk daging buah alpukat mentega menggunakan sendok bersih.',
        'Kupas pisang dan lumatkan bersama alpukat dalam piring makan kecil menggunakan punggung garpu.',
        'Tambahkan tetesan ASI atau susu formula hangat untuk melarutkan kekentalan.',
        'Aduk cepat hingga menyatu merata dan sajikan segar segera setelah dibuat.',
      ],
      'manfaat':
          'Kaya lemak tak jenuh tunggal yang sehat, kalium, dan serat pencernaan untuk menaikkan berat badan secara sehat.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistoriMpasi();
  }

  // --- FETCH API HISTORY LARAVEL ---
  Future<void> _fetchHistoriMpasi() async {
    if (widget.daftarAnak.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var anakAktif = widget.daftarAnak[widget.anakTerpilihIndeks];
      String idAnak =
          anakAktif['_id']?.toString() ?? anakAktif['id']?.toString() ?? '';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/riwayat/$idAnak'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> riwayatList = data['data'] ?? [];

        var riwayatTerbaru = riwayatList.firstWhere(
          (item) =>
              (item['rekomendasi_terstruktur'] != null &&
                  (item['rekomendasi_terstruktur'] as List).isNotEmpty) ||
              (item['rekomendasi_data'] != null &&
                  (item['rekomendasi_data'] as List).isNotEmpty),
          orElse: () => null,
        );

        if (riwayatTerbaru != null) {
          List<dynamic> struktur =
              riwayatTerbaru['rekomendasi_terstruktur'] ??
              riwayatTerbaru['rekomendasi_data'] ??
              [];
          List<Map<String, dynamic>> resepDiekstrak = [];
          Set<String> setKategori = {'Semua'};

          for (var kategori in struktur) {
            String nutrisi =
                kategori['nutrisi'] ?? kategori['kategori'] ?? 'Menu Lainnya';
            setKategori.add(nutrisi);

            for (var makanan
                in (kategori['makanan'] ?? kategori['menu'] ?? [])) {
              // [PERBAIKAN LOGIKA]: Membaca berbagai kemungkinan nama kunci (key) dari Gemini AI
              if (makanan is Map) {
                String namaMakanan =
                    makanan['nama_makanan'] ??
                    makanan['nama'] ??
                    makanan['menu'] ??
                    makanan['judul'] ??
                    'Tanpa Nama';
                String deskripsi =
                    makanan['deskripsi'] ??
                    makanan['manfaat'] ??
                    makanan['keterangan'] ??
                    'Menu sehat rekomendasi AI untuk si Kecil.';

                resepDiekstrak.add({
                  'kategori': nutrisi,
                  'nama_makanan': namaMakanan,
                  'deskripsi': deskripsi,
                  'img': _getImageAsset(namaMakanan),
                });
              } else if (makanan is String) {
                // Jaga-jaga jika AI mengembalikan data berupa list string langsung, bukan object
                resepDiekstrak.add({
                  'kategori': nutrisi,
                  'nama_makanan': makanan,
                  'deskripsi':
                      'Sangat disarankan untuk melengkapi kebutuhan gizi anak Anda.',
                  'img': _getImageAsset(makanan),
                });
              }
            }
          }

          if (mounted) {
            setState(() {
              _semuaResep = resepDiekstrak;
              _filters = setKategori.toList();
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA CERDAS PENCOCOKAN GAMBAR ---
  String _getImageAsset(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('ayam')) return 'assets/images/mpasi_ayam.png';
    if (name.contains('sapi') || name.contains('daging'))
      return 'assets/images/mpasi_daging.png';
    if (name.contains('ikan') ||
        name.contains('salmon') ||
        name.contains('lele') ||
        name.contains('tuna'))
      return 'assets/images/mpasi_ikan.png';
    if (name.contains('telur') || name.contains('puyuh'))
      return 'assets/images/mpasi_telur.png';
    if (name.contains('sayur') ||
        name.contains('bayam') ||
        name.contains('brokoli') ||
        name.contains('wortel'))
      return 'assets/images/mpasi_sayur.png';
    if (name.contains('buah') ||
        name.contains('pisang') ||
        name.contains('alpukat'))
      return 'assets/images/mpasi_buah.png';
    return 'assets/images/mpasi_default.png';
  }

  // --- CTA BANNER DINAMIS ---
  Widget _buildCtaBanner() {
    bool anakKosong = widget.daftarAnak.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1978E5),
            const Color(0xFF0F5EC7).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1978E5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Bubble
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        anakKosong
                            ? 'Dapatkan Menu Personal AI'
                            : 'Menu MPASI Personal dari AI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  anakKosong
                      ? 'Tambah data anak terlebih dahulu agar Kila AI dapat merancang asupan gizi MPASI terstruktur.'
                      : 'Lakukan Cek Stunting sekarang untuk mendapatkan diagnosis gizi eksklusif yang disesuaikan khusus untuk si Kecil.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (anakKosong) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TambahAnakPage(),
                          ),
                        ).then((_) => _fetchHistoriMpasi());
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CekStuntingPage(
                              isIbuDataComplete: true,
                              daftarAnak: widget.daftarAnak,
                            ),
                          ),
                        ).then((_) => _fetchHistoriMpasi());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1978E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          anakKosong
                              ? 'Tambah Data Anak Sekarang'
                              : 'Cek Stunting Sekarang',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERACTIVE RECIPE DETAILS BOTTOM SHEET ---
  void _showRecipeDetails(BuildContext context, Map<String, dynamic> data) {
    final porsi = data['porsi'] ?? '1-2 Porsi';
    final waktu = data['waktu'] ?? '20 Menit';
    final List<dynamic> bahan =
        data['bahan'] ??
        [
          'ASI / Susu Formula hangat secukupnya',
          'Bahan segar penunjang gizi (karbohidrat/protein)',
          'Mentega tawar / Unsalted Butter (lemak tambahan)',
        ];
    final List<dynamic> langkah =
        data['langkah'] ??
        [
          'Cuci bersih bahan penunjang gizi bayi hingga steril.',
          'Kukus atau rebus bahan penunjang hingga lunak dan matang.',
          'Saring/haluskan bahan dengan blender makanan bayi atau saringan kawat.',
          'Campurkan ASI atau susu formula hangat untuk mengatur tingkat kekentalan.',
          'Hidangkan selagi hangat dengan sendok khusus bayi.',
        ];
    final manfaat =
        data['manfaat'] ??
        data['deskripsi'] ??
        'Nutrisi padat gizi untuk masa perkembangan emas sang buah hati.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Background/Header Top Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEAF1FF), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      // Pull Indicator
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Close button & title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['kategori'].toString().toUpperCase(),
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close_rounded,
                                color: _bgHitam,
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 40,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                data['nama_makanan'],
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _bgHitam,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                data['deskripsi'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _outlineColor,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Quick Info Badges (Porsi, Waktu)
                              Row(
                                children: [
                                  _buildQuickInfoItem(
                                    Icons.restaurant_rounded,
                                    porsi,
                                    'Porsi',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildQuickInfoItem(
                                    Icons.timer_outlined,
                                    waktu,
                                    'Waktu Masak',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Card Manfaat Nutrisi
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEAF1FF),
                                      Color(0xFFEFF4FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD6E3FF),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.stars_rounded,
                                      color: _primaryBlue,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Manfaat Kesehatan & Nutrisi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _bgHitam,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            manfaat,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _bgHitam.withOpacity(0.8),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Section: Bahan-bahan
                              Text(
                                'Bahan-bahan Utama',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _bgHitam,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(bahan.length, (idx) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.8),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          bahan[idx].toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _bgHitam.withOpacity(0.95),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 28),

                              // Section: Langkah Pembuatan
                              Text(
                                'Cara Pembuatan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _bgHitam,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(langkah.length, (idx) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _primaryBlue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            color: _primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          langkah[idx].toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _bgHitam.withOpacity(0.85),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: _outlineColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _bgHitam,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Membaca dari API, jika kosong gunakan database mock premium
    List<Map<String, dynamic>> resepSumber = _semuaResep.isEmpty
        ? _mockResepList
        : _semuaResep;

    List<Map<String, dynamic>> resepTampil = resepSumber.where((resep) {
      bool masukKategori =
          _selectedFilter == 'Semua' || resep['kategori'] == _selectedFilter;
      bool masukPencarian = resep['nama_makanan'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return masukKategori && masukPencarian;
    }).toList();

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu MPASI AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _bgHitam,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rekomendasi nutrisi harian khusus untuk si Kecil.',
                    style: TextStyle(color: _outlineColor, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Tampilkan Banner CTA jika data dari API kosong (agar lebih interaktif)
            if (_semuaResep.isEmpty) _buildCtaBanner(),

            // SEARCH & FILTER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari resep dari AI...',
                      prefixIcon: Icon(Icons.search, color: _outlineColor),
                      filled: true,
                      fillColor: _cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((filter) {
                        bool isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryBlue : _cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? _primaryBlue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : _outlineColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // LISTVIEW BENTO RESEP
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryBlue),
                    )
                  : resepTampil.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Resep tidak ditemukan',
                            style: TextStyle(
                              color: _outlineColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      itemCount: resepTampil.length,
                      itemBuilder: (context, index) {
                        return _buildRecipeCard(resepTampil[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => _showRecipeDetails(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Box (Kiri)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.asset(
                data['img'],
                width: 120, // Ukuran gambar proporsional
                height: 135,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 135,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.fastfood,
                    color: Colors.grey.shade400,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Content Box (Kanan - Memanjang)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['kategori'],
                        style: TextStyle(
                          fontSize: 10,
                          color: _primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['nama_makanan'],
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _bgHitam,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['deskripsi'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _outlineColor,
                        height: 1.4,
                      ),
                      maxLines: 3,
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
  }
}
