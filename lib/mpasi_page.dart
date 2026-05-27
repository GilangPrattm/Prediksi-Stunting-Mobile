import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

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
  List<String> _filters = ['Semua'];
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _semuaResep = [];

  @override
  void initState() {
    super.initState();
    _fetchHistoriMpasi();
  }

  // --- FETCH API HISTORY LARAVEL ---
  Future<void> _fetchHistoriMpasi() async {
    if (widget.daftarAnak.isEmpty) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      var anakAktif = widget.daftarAnak[widget.anakTerpilihIndeks];
      String idAnak = anakAktif['_id']?.toString() ?? anakAktif['id']?.toString() ?? '';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/riwayat/$idAnak'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> riwayatList = data['data'] ?? [];

        var riwayatTerbaru = riwayatList.firstWhere(
          (item) => (item['rekomendasi_terstruktur'] != null && (item['rekomendasi_terstruktur'] as List).isNotEmpty) ||
                    (item['rekomendasi_data'] != null && (item['rekomendasi_data'] as List).isNotEmpty),
          orElse: () => null,
        );

        if (riwayatTerbaru != null) {
          List<dynamic> struktur = riwayatTerbaru['rekomendasi_terstruktur'] ?? riwayatTerbaru['rekomendasi_data'] ?? [];
          List<Map<String, dynamic>> resepDiekstrak = [];
          Set<String> setKategori = {'Semua'};

          for (var kategori in struktur) {
            String nutrisi = kategori['nutrisi'] ?? kategori['kategori'] ?? 'Menu Lainnya';
            setKategori.add(nutrisi);
            
            for (var makanan in (kategori['makanan'] ?? kategori['menu'] ?? [])) {
              // [PERBAIKAN LOGIKA]: Membaca berbagai kemungkinan nama kunci (key) dari Gemini AI
              if (makanan is Map) {
                String namaMakanan = makanan['nama_makanan'] ?? makanan['nama'] ?? makanan['menu'] ?? makanan['judul'] ?? 'Tanpa Nama';
                String deskripsi = makanan['deskripsi'] ?? makanan['manfaat'] ?? makanan['keterangan'] ?? 'Menu sehat rekomendasi AI untuk si Kecil.';
                
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
                  'deskripsi': 'Sangat disarankan untuk melengkapi kebutuhan gizi anak Anda.',
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
    if (name.contains('sapi') || name.contains('daging')) return 'assets/images/mpasi_daging.png';
    if (name.contains('ikan') || name.contains('salmon') || name.contains('lele') || name.contains('tuna')) return 'assets/images/mpasi_ikan.png';
    if (name.contains('telur') || name.contains('puyuh')) return 'assets/images/mpasi_telur.png';
    if (name.contains('sayur') || name.contains('bayam') || name.contains('brokoli') || name.contains('wortel')) return 'assets/images/mpasi_sayur.png';
    if (name.contains('buah') || name.contains('pisang') || name.contains('alpukat')) return 'assets/images/mpasi_buah.png';
    return 'assets/images/mpasi_default.png'; 
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> resepTampil = _semuaResep.where((resep) {
      bool masukKategori = _selectedFilter == 'Semua' || resep['kategori'] == _selectedFilter;
      bool masukPencarian = resep['nama_makanan'].toLowerCase().contains(_searchQuery.toLowerCase());
      return masukKategori && masukPencarian;
    }).toList();

    return Scaffold(
      backgroundColor: _surfaceBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menu MPASI AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _bgHitam, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Rekomendasi nutrisi harian khusus untuk si Kecil.', style: TextStyle(color: _outlineColor, fontSize: 13)),
                ],
              ),
            ),

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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? _primaryBlue : _cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? _primaryBlue : Colors.grey.shade300),
                              ),
                              child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : _outlineColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
                ? Center(child: CircularProgressIndicator(color: _primaryBlue))
                : resepTampil.isEmpty 
                  ? Center(child: Text('Belum ada rekomendasi. Lakukan Cek Stunting terlebih dahulu.', style: TextStyle(color: _outlineColor)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Box (Kiri)
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: Image.asset(
              data['img'],
              width: 120, // Ukuran gambar proporsional
              height: 135,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 135,
                color: Colors.grey.shade100, 
                child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 40)
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(6)),
                    child: Text(data['kategori'], style: TextStyle(fontSize: 10, color: _primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['nama_makanan'], 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _bgHitam, height: 1.2), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['deskripsi'], 
                    style: TextStyle(fontSize: 12, color: _outlineColor, height: 1.4), 
                    maxLines: 3, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}