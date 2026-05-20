import 'package:flutter/material.dart';

class MpasiPage extends StatefulWidget {
  final List<dynamic> daftarAnak;
  final int anakTerpilihIndeks;
  final List<dynamic> daftarResep;

  const MpasiPage({
    super.key,
    required this.daftarAnak,
    required this.anakTerpilihIndeks,
    required this.daftarResep,
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
  final List<String> _filters = ['Semua', 'Bubur', 'Tim', 'Finger Food', 'Selingan'];

  // Fungsi hitung umur berdasarkan tanggal lahir
  String _hitungUmur(String? tglLahirStr) {
    if (tglLahirStr == null || tglLahirStr.isEmpty) return 'Umur Tidak Diketahui';
    try {
      DateTime birthDate = DateTime.parse(tglLahirStr);
      DateTime today = DateTime.now();
      int months = (today.year - birthDate.year) * 12 + today.month - birthDate.month;
      if (today.day < birthDate.day) months--;
      if (months <= 0) return 'Baru Lahir';
      if (months < 12) return '$months Bulan';
      int years = months ~/ 12;
      int remainingMonths = months % 12;
      return remainingMonths == 0 ? '$years Tahun' : '$years Tahun $remainingMonths Bulan';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data anak jika ada
    String teksUsia = 'Belum ada data';
    String statusGizi = 'Normal';
    
    if (widget.daftarAnak.isNotEmpty) {
      var anakAktif = widget.daftarAnak[widget.anakTerpilihIndeks];
      teksUsia = _hitungUmur(anakAktif['tgl_lahir']);
      statusGizi = anakAktif['status_gizi'] ?? 'Normal';
    }

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER & INFO ANAK
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu MPASI Si Kecil',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _bgHitam, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE9FF)),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: _bgHitam.withOpacity(0.7), fontSize: 13, height: 1.5, fontFamily: 'Nunito Sans'),
                        children: [
                          const TextSpan(text: 'Rekomendasi gizi berdasarkan usia '),
                          TextSpan(text: teksUsia, style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' (Status: '),
                          TextSpan(text: statusGizi, style: TextStyle(color: statusGizi.toLowerCase().contains('normal') ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                          const TextSpan(text: ')'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SEARCH BAR & FILTER CHIPS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: _surfaceBg.withOpacity(0.95),
              child: Column(
                children: [
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari resep MPASI...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: _outlineColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((filter) {
                        bool isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryBlue : _cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? _primaryBlue : Colors.grey.shade300),
                                boxShadow: isSelected ? [BoxShadow(color: _primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _outlineColor,
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

            // GRID RESEP & TIPS
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    // Grid Bento
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 Kolom seperti Bento Style
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.58, // Rasio disesuaikan agar card proporsional
                      ),
                      // Dummy data untuk visual yang cantik, tapi bisa di-replace dengan widget.daftarResep nanti
                      itemCount: 3, 
                      itemBuilder: (context, index) {
                        List<Map<String, dynamic>> dummyData = [
                          {
                            "title": "Bubur Salmon & Bayam",
                            "time": "25 mnt",
                            "img": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400",
                            "badges": ["Tinggi Protein", "Omega-3"],
                            "kalori": "180", "protein": "12g", "lemak": "6g"
                          },
                          {
                            "title": "Nasi Tim Ayam Wortel",
                            "time": "40 mnt",
                            "img": "https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400",
                            "badges": ["Vitamin A", "Zat Besi"],
                            "kalori": "210", "protein": "15g", "lemak": "5g"
                          },
                          {
                            "title": "Puding Mangga Sehat",
                            "time": "15 mnt",
                            "img": "https://images.unsplash.com/photo-1555507036-ab1f40ce88cb?w=400",
                            "badges": ["Vitamin C", "Serat"],
                            "kalori": "110", "protein": "2g", "lemak": "1g"
                          }
                        ];
                        return _buildRecipeCard(dummyData[index]);
                      },
                    ),

                    const SizedBox(height: 30),

                    // Educational Tips
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF), // Biru sangat muda
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD6E3FF)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(Icons.lightbulb_outline_rounded, color: _primaryBlue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pentingnya Protein Hewani', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _bgHitam)),
                                const SizedBox(height: 6),
                                Text(
                                  'Protein hewani sangat krusial untuk mencegah stunting pada 1000 Hari Pertama Kehidupan. Pastikan ada setidaknya satu sumber protein hewani dalam setiap porsi makan si Kecil.',
                                  style: TextStyle(fontSize: 12, color: _outlineColor, height: 1.5),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Spasi untuk Bottom Navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Box
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  child: Image.network(
                    data['img'],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: _primaryBlue),
                        const SizedBox(width: 4),
                        Text(data['time'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _bgHitam)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          
          // Content Box
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _bgHitam, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Badges
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (data['badges'] as List<String>).map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(8)),
                        child: Text(badge, style: TextStyle(fontSize: 9, color: _primaryBlue, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                  
                  const Spacer(),
                  
                  // Nutrition Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutriBox('Kalori', data['kalori']),
                      _buildNutriBox('Protein', data['protein']),
                      _buildNutriBox('Lemak', data['lemak']),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 14, color: Colors.white),
                      label: const Text('Lihat Resep', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutriBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 8, color: _outlineColor)),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _bgHitam)),
        ],
      ),
    );
  }
}