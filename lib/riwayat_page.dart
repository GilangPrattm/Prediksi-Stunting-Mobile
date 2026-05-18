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
  // Warna sesuai tema HTML
  final Color _primary = const Color(0xFF006A63);
  final Color _primaryContainer = const Color(0xFF4DB6AC);
  final Color _onPrimaryContainer = const Color(0xFF00433F);
  final Color _surfaceLowest = const Color(0xFFFFFFFF);
  final Color _surfaceContainer = const Color(0xFFECEEEE);
  final Color _onSurface = const Color(0xFF191C1D);
  final Color _onSurfaceVariant = const Color(0xFF3D4947);
  final Color _outline = const Color(0xFF6D7A77);
  final Color _bg = const Color(0xFFF5F7F7);

  List<dynamic> _riwayatPrediksi = [];
  List<dynamic> _dataPengukuran = [];
  late Future<Map<String, dynamic>> _futureData;
  String? _anakTerpilihId;
  String _anakTerpilihNama = 'Semua Anak';
  int _tabGrafik = 0; // 0 = Berat Badan, 1 = Tinggi Badan

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surfaceLowest,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Icon(Icons.child_care, color: _primary),
            const SizedBox(width: 8),
            Text(
              'Stunt-Check',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primary));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Gagal memuat data",
                style: TextStyle(color: _onSurfaceVariant),
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
            color: _primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  if (hasData) ...[
                    _buildGrafikCard(),
                    const SizedBox(height: 24),
                    _buildRiwayatList(),
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
    // Hitung statistik singkat
    int normal = 0;
    int stunting = 0;
    int pendek = 0;
    
    for (var r in _riwayatPrediksi) {
      String status = (r['status'] ?? '').toString().toLowerCase();
      if (status == 'normal') normal++;
      else if (status.contains('sangat pendek') || status == 'stunting') stunting++;
      else if (status.contains('pendek') || status == 'berisiko') pendek++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat & Tumbuh Kembang',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '$_anakTerpilihNama · ${_riwayatPrediksi.length} pemeriksaan',
          style: TextStyle(fontSize: 14, color: _onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (_riwayatPrediksi.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatBadge('Normal: $normal', const Color(0xFF136964), const Color(0xFFA4F0E9)),
              _buildStatBadge('Sangat Pendek: $stunting', const Color(0xFF93000A), const Color(0xFFFFDAD6)),
              _buildStatBadge('Pendek: $pendek', const Color(0xFF994500), const Color(0xFFFFDCC2)),
            ],
          ),
      ],
    );
  }

  Widget _buildStatBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
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
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface)),
                  Text(
                      _tabGrafik == 0
                          ? 'Berat Badan (kg) per Bulan'
                          : 'Tinggi Badan (cm) per Bulan',
                      style: TextStyle(fontSize: 12, color: _onSurfaceVariant)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildTabButton('BB', 0),
                    _buildTabButton('TB', 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _dataPengukuran.isEmpty
                ? const Center(child: Text('Data tidak cukup untuk grafik'))
                : _buildFlChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = _tabGrafik == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabGrafik = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : _onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFlChart() {
    List<FlSpot> spots = [];
    double maxX = _dataPengukuran.length.toDouble();
    double maxY = 0;
    double minY = double.infinity;

    for (int i = 0; i < _dataPengukuran.length; i++) {
      var item = _dataPengukuran[i];
      double val = _tabGrafik == 0
          ? double.tryParse(item['berat'].toString()) ?? 0
          : double.tryParse(item['tinggi'].toString()) ?? 0;
      
      if (val > maxY) maxY = val;
      if (val < minY && val > 0) minY = val;
      
      spots.add(FlSpot(i.toDouble(), val));
    }

    // Add padding to Y axis
    maxY = maxY + (maxY * 0.2);
    minY = minY > 5 ? minY - 5 : 0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _tabGrafik == 0 ? 5 : 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: _surfaceContainer,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _tabGrafik == 0 ? 5 : 20,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: _onSurfaceVariant, fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _dataPengukuran.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Bln ${value.toInt() + 1}',
                      style: TextStyle(color: _onSurfaceVariant, fontSize: 10),
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
            color: _primaryContainer,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 4, color: _primary, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _primaryContainer.withValues(alpha: 0.1),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface)),
            Text('${_riwayatPrediksi.length} data',
                style: TextStyle(fontSize: 12, color: _outline)),
          ],
        ),
        const SizedBox(height: 12),
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
    
    String rawStatus = (data['status'] ?? 'Normal').toString();
    String status = rawStatus;
    
    // Tentukan warna berdasarkan status
    Color badgeColor = const Color(0xFF136964); // Teal/Normal
    Color badgeBg = const Color(0xFFA4F0E9);
    IconData icon = Icons.check_circle;

    if (rawStatus.toLowerCase().contains('sangat pendek') || rawStatus.toLowerCase() == 'stunting') {
      badgeColor = const Color(0xFFBA1A1A); // Red
      badgeBg = const Color(0xFFFFDAD6);
      icon = Icons.report;
      status = "Stunting";
    } else if (rawStatus.toLowerCase().contains('pendek') || rawStatus.toLowerCase() == 'berisiko') {
      badgeColor = const Color(0xFF994500); // Orange
      badgeBg = const Color(0xFFFFDCC2);
      icon = Icons.warning;
      status = "Berisiko";
    }

    double probabilitas = double.tryParse(data['probabilitas']?.toString() ?? '1') ?? 1.0;
    int probPersen = (probabilitas * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _surfaceContainer, shape: BoxShape.circle),
                child: Center(child: Text('$urutan', style: TextStyle(fontWeight: FontWeight.bold, color: _onSurface))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_anakTerpilihNama, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface)),
                    Text(tglStr, style: TextStyle(fontSize: 12, color: _onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Keyakinan AI:', style: TextStyle(fontSize: 12, color: _onSurfaceVariant)),
              Text('$probPersen%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: probabilitas,
              minHeight: 8,
              backgroundColor: _surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CekStuntingPage()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 18, color: _primary),
                const SizedBox(width: 6),
                Text('Prediksi Ulang', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: _outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Belum Ada Riwayat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
          const SizedBox(height: 8),
          Text('Lakukan Cek Stunting untuk melihat\nhasil analisis AI di sini.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _onSurfaceVariant)),
        ],
      ),
    );
  }
}