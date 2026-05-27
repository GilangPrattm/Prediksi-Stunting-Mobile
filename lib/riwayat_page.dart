import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'cek_stunting_page.dart';
import 'hasil_prediksi_page.dart';

class RiwayatPage extends StatefulWidget {
  final List<dynamic> daftarAnak;
  const RiwayatPage({super.key, required this.daftarAnak});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // --- TEMA WARNA BIRU KONSISTEN ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _primaryLight = const Color(0xFFD6E3FF);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _cardBg = Colors.white;

  List<dynamic> _riwayatPrediksi = [];
  List<dynamic> _dataPengukuran = [];
  late Future<Map<String, dynamic>> _futureData;
  String? _anakTerpilihId;
  String _anakTerpilihNama = 'Semua Anak';

  @override
  void initState() {
    super.initState();
    if (widget.daftarAnak.isNotEmpty) {
      _anakTerpilihId = widget.daftarAnak[0]['_id']?.toString() ??
                        widget.daftarAnak[0]['id']?.toString();
      _anakTerpilihNama = widget.daftarAnak[0]['nama_anak'] ?? 'Anak';
    }
    _futureData = _fetchAllData();
  }

  Future<Map<String, dynamic>> _fetchAllData() async {
    if (_anakTerpilihId == null) {
      return {'riwayat': [], 'grafik': []};
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final urlRiwayat = '${ApiConfig.baseUrl}/riwayat/$_anakTerpilihId';
    final urlGrafik = '${ApiConfig.baseUrl}/riwayat/grafik/$_anakTerpilihId';

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(urlRiwayat), headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(urlGrafik), headers: {'Authorization': 'Bearer $token'}),
      ]);

      final resRiwayat = responses[0];
      final resGrafik = responses[1];

      List<dynamic> riwayat = [];
      List<dynamic> grafik = [];

      if (resRiwayat.statusCode == 200) {
        final jRiwayat = json.decode(resRiwayat.body);
        if (jRiwayat['status'] == 'success') riwayat = jRiwayat['data'] ?? [];
      }
      if (resGrafik.statusCode == 200) {
        final jGrafik = json.decode(resGrafik.body);
        if (jGrafik['status'] == 'success') grafik = jGrafik['data'] ?? [];
      }

      _riwayatPrediksi = riwayat;
      _dataPengukuran = grafik;
      return {'riwayat': riwayat, 'grafik': grafik};
    } catch (e) {
      throw Exception('Gagal mengambil data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        backgroundColor: _surfaceBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: _primaryBlue, size: 28),
            const SizedBox(width: 8),
            Text(
              'Halaman Riwayat', // [PERBAIKAN 1]: Judul diganti
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryBlue));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat data dari server",
                style: TextStyle(color: _outlineColor),
              ),
            );
          }

          final bool hasData = _riwayatPrediksi.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureData = _fetchAllData();
              });
            },
            color: _primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  if (hasData) ...[
                    _buildGrafikCard(),
                    const SizedBox(height: 30),
                    _buildRiwayatList(),
                    const SizedBox(height: 40), 
                  ] else ...[
                    _buildKosong(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // WIDGET COMPONENTS
  // ==========================================

  Widget _buildHeaderInfo() {
    int normal = 0;
    int tinggi = 0;
    int stunting = 0; 
    int sangatStunting = 0;
    
    for (var r in _riwayatPrediksi) {
      // [PERBAIKAN 3]: Mengambil data dari 'hasil_prediksi' terlebih dahulu (menyesuaikan versi ML terbaru)
      String status = (r['hasil_prediksi'] ?? r['status'] ?? '').toString().toLowerCase();
      if (status.contains('sangat stunting') || status.contains('sangat pendek') || status.contains('severely')) sangatStunting++;
      else if (status.contains('stunting') || status.contains('pendek') || status.contains('berisiko')) stunting++;
      else if (status.contains('tinggi')) tinggi++;
      else normal++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat & Tumbuh Kembang',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _bgHitam, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          '$_anakTerpilihNama · ${_riwayatPrediksi.length} pemeriksaan',
          style: TextStyle(fontSize: 14, color: _outlineColor),
        ),
        const SizedBox(height: 16),
        if (_riwayatPrediksi.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatBadge('Normal: $normal', const Color(0xFF10B981), const Color(0xFFD1FAE5)),
              // [PERBAIKAN 2]: Menghilangkan if (tinggi > 0) agar kategori Tinggi paten muncul
              _buildStatBadge('Tinggi: $tinggi', _primaryBlue, _primaryLight),
              _buildStatBadge('Stunting: $stunting', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
              _buildStatBadge('Sangat Stunting: $sangatStunting', const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
            ],
          ),
      ],
    );
  }

  Widget _buildStatBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGrafikCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grafik Tumbuh Kembang',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bgHitam)),
                  const SizedBox(height: 2),
                  Text(
                      'Tinggi Badan (cm) per Pemeriksaan',
                      style: TextStyle(fontSize: 12, color: _outlineColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 250,
            child: _dataPengukuran.isEmpty
                ? Center(child: Text('Data tidak cukup untuk grafik', style: TextStyle(color: _outlineColor)))
                : _buildFlChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlChart() {
    // [PERBAIKAN 4]: Membatasi data agar hanya menampilkan maksimal 20 data terakhir
    List<dynamic> limitedData = _dataPengukuran;
    if (limitedData.length > 20) {
      limitedData = limitedData.sublist(limitedData.length - 20);
    }

    List<FlSpot> spots = [];
    double maxX = limitedData.length.toDouble();
    double maxY = 0;
    double minY = double.infinity;

    for (int i = 0; i < limitedData.length; i++) {
      var item = limitedData[i];
      double val = double.tryParse(item['tinggi'].toString()) ?? 0;
      
      if (val > maxY) maxY = val;
      if (val < minY && val > 0) minY = val;
      
      spots.add(FlSpot(i.toDouble(), val));
    }

    maxY = maxY + (maxY * 0.1);
    minY = minY > 5 ? minY - 5 : 0;
    
    // Interval X-Axis cerdas: Jika data banyak, lewati beberapa label agar tidak menumpuk
    double xInterval = limitedData.length > 10 ? 2 : 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10, // Grid garis horizontal diperlebar agar estetik
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: _outlineColor, fontSize: 11, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval, // Interval yang disesuaikan
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < limitedData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'P.${value.toInt() + 1}', // P = Pemeriksaan
                      style: TextStyle(color: _outlineColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX - 1,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35, // Membuat garis sedikit lebih melengkung alami
            color: _primaryBlue,
            barWidth: 3.5, // Garis sedikit lebih tebal
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 4.5, color: _primaryBlue, strokeWidth: 2, strokeColor: Colors.white),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _primaryBlue.withOpacity(0.25),
                  _primaryBlue.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Data Riwayat Prediksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _bgHitam)),
            Text('${_riwayatPrediksi.length} data',
                style: TextStyle(fontSize: 13, color: _outlineColor, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _riwayatPrediksi.length,
          itemBuilder: (context, index) {
            final data = _riwayatPrediksi[index];
            return _buildRiwayatCard(data, index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildRiwayatCard(dynamic data, int urutan) {
    String tglStr = data['tanggal'] ?? data['created_at'] ?? '';
    if (tglStr.length > 10) tglStr = tglStr.substring(0, 10);
    
    // [PERBAIKAN 3]: Gunakan 'hasil_prediksi' sebagai key prioritas
    String rawStatus = (data['hasil_prediksi'] ?? data['status'] ?? 'Normal').toString();
    String status = rawStatus;
    
    // Tema Warna berdasarkan Status Gizi
    Color badgeColor = const Color(0xFF10B981); // Emerald/Normal
    Color badgeBg = const Color(0xFFD1FAE5);
    IconData icon = Icons.check_circle;

    if (rawStatus.toLowerCase().contains('sangat stunting') || rawStatus.toLowerCase().contains('sangat pendek') || rawStatus.toLowerCase().contains('severely')) {
      badgeColor = const Color(0xFFE11D48); // Rose
      badgeBg = const Color(0xFFFFE4E6);
      icon = Icons.report;
      status = "Sangat Stunting";
    } else if (rawStatus.toLowerCase().contains('stunting') || rawStatus.toLowerCase().contains('pendek') || rawStatus.toLowerCase().contains('berisiko')) {
      badgeColor = const Color(0xFFF59E0B); // Amber
      badgeBg = const Color(0xFFFEF3C7);
      icon = Icons.warning;
      status = "Stunting";
    } else if (rawStatus.toLowerCase().contains('tinggi')) {
      badgeColor = _primaryBlue; // Blue
      badgeBg = _primaryLight;
      icon = Icons.height;
      status = "Tinggi";
    } else {
      status = "Normal";
    }

    double probabilitas = double.tryParse(data['probabilitas']?.toString() ?? '1') ?? 1.0;
    int probPersen = (probabilitas * 100).toInt();

    // Data Anak untuk diteruskan
    final String idAnak = data['id_anak']?.toString() ?? _anakTerpilihId ?? '';
    final anakData = widget.daftarAnak.firstWhere(
      (a) => (a['_id'] ?? a['id'] ?? '').toString() == idAnak,
      orElse: () => <String, dynamic>{},
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HasilPrediksiPage(
              namaAnak: _anakTerpilihNama,
              hasilPrediksi: status,
              probabilitas: probabilitas,
              tinggiBadan: (anakData['tinggi_badan'] as num?)?.toDouble(),
              rekomendasiTeks: data['rekomendasi_teks'],
              rekomendasiTerstruktur: data['rekomendasi_terstruktur'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor Urut
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(color: _surfaceBg, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$urutan', 
                      style: TextStyle(fontWeight: FontWeight.w900, color: _bgHitam, fontSize: 16)
                    )
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _anakTerpilihNama, 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _bgHitam, height: 1.2)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tglStr, 
                        style: TextStyle(fontSize: 12, color: _outlineColor, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
                // Badge Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(icon, size: 14, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        status, 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // AI Confidence Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Keyakinan AI:', style: TextStyle(fontSize: 13, color: _outlineColor, fontWeight: FontWeight.w600)),
                Text('$probPersen%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primaryBlue)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: probabilitas,
                minHeight: 8,
                backgroundColor: _surfaceBg,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
              ),
            ),
            
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            
            // Tombol Prediksi Ulang
            GestureDetector(
              onTap: () {
                final List<dynamic> anakList = anakData.isNotEmpty
                    ? [anakData]
                    : widget.daftarAnak;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CekStuntingPage(
                      isIbuDataComplete: true,
                      daftarAnak: anakList,
                    ),
                  ),
                ).then((_) {
                  setState(() {
                    _futureData = _fetchAllData();
                  });
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: _primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Prediksi Ulang', 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryBlue)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.1), blurRadius: 20)]),
            child: Icon(Icons.history_toggle_off_rounded, size: 60, color: _outlineColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text('Belum Ada Riwayat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _bgHitam)),
          const SizedBox(height: 8),
          Text(
            'Lakukan Cek Gizi pada Beranda untuk melihat\nhasil analisis AI di sini.',
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 14, color: _outlineColor, height: 1.5)
          ),
        ],
      ),
    );
  }
}