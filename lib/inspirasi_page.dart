import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/api_config.dart';

class InspirasiPage extends StatefulWidget {
  const InspirasiPage({super.key});

  @override
  State<InspirasiPage> createState() => _InspirasiPageState();
}

class _InspirasiPageState extends State<InspirasiPage> {
  final String _baseUrl = ApiConfig.baseUrl;

  // --- WARNA TEMA BIRU KONSISTEN ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _primaryFixed = const Color(0xFFD6E3FF);

  List<dynamic> _daftarInspirasi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSemuaInspirasi();
  }

  Future<void> _fetchSemuaInspirasi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/inspirasi'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _daftarInspirasi = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Fetching Inspirasi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _bukaArtikel(dynamic artikel) async {
    if (artikel['url_sumber'] != null && artikel['url_sumber'].toString().isNotEmpty) {
      final url = Uri.parse(artikel['url_sumber']);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Could not launch $url: $e");
      }
    } else if (artikel['konten_lengkap'] != null && artikel['konten_lengkap'].toString().isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(artikel['judul'], style: TextStyle(color: _bgHitam, fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Text(artikel['konten_lengkap'], style: TextStyle(color: _outlineColor, height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        title: Text(
          'Artikel Kesehatan',
          style: TextStyle(color: _bgHitam, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _surfaceBg,
        elevation: 0,
        iconTheme: IconThemeData(color: _bgHitam),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchSemuaInspirasi,
              color: _primaryBlue,
              child: _daftarInspirasi.isEmpty
                  ? _buildKosong()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _daftarInspirasi.length,
                      itemBuilder: (context, index) {
                        final artikel = _daftarInspirasi[index];
                        return _buildArtikelCard(artikel);
                      },
                    ),
            ),
    );
  }

  Widget _buildArtikelCard(dynamic artikel) {
    final bool hasImage = artikel['url_gambar'] != null && artikel['url_gambar'].toString().isNotEmpty;
    final String kategori = artikel['kategori'] ?? 'Umum';
    String tglStr = artikel['tanggal_publikasi'] ?? artikel['created_at'] ?? '';
    if (tglStr.length > 10) tglStr = tglStr.substring(0, 10);

    return GestureDetector(
      onTap: () => _bukaArtikel(artikel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotak Gambar
            Container(
              width: 110,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryFixed,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                      child: Image.network(
                        artikel['url_gambar'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: _primaryBlue.withOpacity(0.5))),
                      ),
                    )
                  : Center(child: Icon(Icons.article, color: _primaryBlue.withOpacity(0.5), size: 32)),
            ),
            
            // Kotak Konten Teks
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(6)),
                          child: Text(kategori, style: TextStyle(color: _primaryBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        if (tglStr.isNotEmpty)
                          Text(tglStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artikel['judul'] ?? 'Tips Kesehatan',
                      style: TextStyle(color: _bgHitam, fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      artikel['deskripsi_singkat'] ?? '',
                      style: TextStyle(color: _outlineColor, fontSize: 11, height: 1.4),
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
  }

  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada artikel tersedia.', style: TextStyle(color: _outlineColor, fontSize: 16)),
        ],
      ),
    );
  }
}