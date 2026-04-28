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
  List<dynamic> _riwayatPrediksi = [];
  List<dynamic> _dataPengukuran = [];
  bool _isLoading = true;
  String? _anakTerpilihId;
  String _anakTerpilihNama = 'Semua Anak';
  int _tabGrafik = 0; // 0=Berat, 1=Tinggi

  @override
  void initState() {
    super.initState();
    if (widget.daftarAnak.isNotEmpty) {
      _anakTerpilihId =
          widget.daftarAnak[0]['_id']?.toString() ??
          widget.daftarAnak[0]['id']?.toString();
      _anakTerpilihNama = widget.daftarAnak[0]['nama_anak'] ?? 'Anak';
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch Prediksi dengan error handling sendiri
      try {
        final resPrediksi = await http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/prediksi'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 15));

        if (resPrediksi.statusCode == 200) {
          final responseData = jsonDecode(resPrediksi.body);
          final riwayat = responseData['data'] as List?;
          if (mounted) {
            _riwayatPrediksi = riwayat ?? [];
          }
        } else {
          print('Prediksi API error: ${resPrediksi.statusCode}');
        }
      } catch (ePrediksi) {
        print('Error fetching prediksi: $ePrediksi');
        if (mounted) {
          _riwayatPrediksi = [];
        }
      }

      // Fetch Pengukuran dengan error handling sendiri
      try {
        final resPengukuran = await http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/pengukuran'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 15));

        if (resPengukuran.statusCode == 200) {
          final responseData = jsonDecode(resPengukuran.body);
          final pengukuran = responseData['data'] as List?;
          if (mounted) {
            _dataPengukuran = pengukuran ?? [];
          }
        } else {
          print('Pengukuran API error: ${resPengukuran.statusCode}');
        }
      } catch (ePengukuran) {
        print('Error fetching pengukuran: $ePengukuran');
        if (mounted) {
          _dataPengukuran = [];
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _pengukuranTerpilih {
    if (_anakTerpilihId == null) return _dataPengukuran;
    return _dataPengukuran
        .where((p) => p['id_anak']?.toString() == _anakTerpilihId)
        .toList()
      ..sort(
        (a, b) => (a['tanggal_ukur'] ?? '').compareTo(b['tanggal_ukur'] ?? ''),
      );
  }

List<dynamic> get _prediksiTerpilih {
  if (_anakTerpilihId == null) return _riwayatPrediksi;
  return _riwayatPrediksi.where((p) {
    // Coba semua kemungkinan field
    String idDariAnak = '';
    if (p['anak'] is Map) {
      idDariAnak = (p['anak']['_id'] ?? p['anak']['id'] ?? '').toString();
    }
    // Fallback ke id_anak di root (selalu cek, bukan hanya jika bukan Map)
    if (idDariAnak.isEmpty) {
      idDariAnak = (p['id_anak'] ?? '').toString();
    }
    return idDariAnak == _anakTerpilihId.toString();
  }).toList();
}

  // ── Warna status ──────────────────────────────────────────────────────────
  Color _warnaStatus(String hasil) {
    final h = hasil.toLowerCase();
    if (h.contains('normal') &&
        !h.contains('berisiko') &&
        !h.contains('stunting'))
      return const Color(0xFF10B981);
    if (h.contains('berisiko')) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _ikonStatus(String hasil) {
    final h = hasil.toLowerCase();
    if (h.contains('normal') && !h.contains('berisiko'))
      return Icons.check_circle_rounded;
    if (h.contains('berisiko')) return Icons.warning_rounded;
    return Icons.dangerous_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBFDBFE)),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFFBFDBFE),
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),

                  // ── Filter Anak ─────────────────────────────────────────
                  if (widget.daftarAnak.length > 1)
                    SliverToBoxAdapter(child: _buildFilterAnak()),

                  // ── Grafik ──────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildGrafikSection()),

                  // ── Tabel Riwayat ───────────────────────────────────────
                  SliverToBoxAdapter(child: _buildTabelHeader()),
                  _prediksiTerpilih.isEmpty
                      ? SliverToBoxAdapter(child: _buildKosong())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) =>
                                _buildBarisTabel(_prediksiTerpilih[i], i),
                            childCount: _prediksiTerpilih.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final jmlNormal = _prediksiTerpilih.where((e) {
      final h = (e['hasil_prediksi'] ?? '').toString().toLowerCase();
      return h.contains('normal') &&
          !h.contains('berisiko') &&
          !h.contains('stunting');
    }).length;
    final jmlBerisiko = _prediksiTerpilih
        .where(
          (e) => (e['hasil_prediksi'] ?? '').toString().toLowerCase().contains(
            'berisiko',
          ),
        )
        .length;
    final jmlStunting = _prediksiTerpilih.where((e) {
      final h = (e['hasil_prediksi'] ?? '').toString().toLowerCase();
      return h.contains('stunting') && !h.contains('berisiko');
    }).length;

    return Container(
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
            'Riwayat & Tumbuh Kembang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_anakTerpilihNama · ${_prediksiTerpilih.length} pemeriksaan',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF1E293B).withOpacity(0.7),
            ),
          ),
          if (_prediksiTerpilih.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _chip('Normal', jmlNormal, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _chip('Berisiko', jmlBerisiko, const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _chip('Stunting', jmlStunting, const Color(0xFFEF4444)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      '$label: $count',
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildFilterAnak() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.daftarAnak.length,
        itemBuilder: (ctx, i) {
          final anak = widget.daftarAnak[i];
          final id = anak['_id']?.toString() ?? anak['id']?.toString() ?? '';
          final selected = id == _anakTerpilihId;
          return GestureDetector(
            onTap: () => setState(() {
              _anakTerpilihId = id;
              _anakTerpilihNama = anak['nama_anak'] ?? 'Anak';
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2196F3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                anak['nama_anak'] ?? '-',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrafikSection() {
    final data = _pengukuranTerpilih;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              const Text(
                'Grafik Tumbuh Kembang',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
              // Tab BB / TB
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [_tabBtn('BB', 0), _tabBtn('TB', 1)]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _tabGrafik == 0
                ? 'Berat Badan (kg) per Pemeriksaan'
                : 'Tinggi Badan (cm) per Pemeriksaan',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada data pengukuran',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            SizedBox(height: 200, child: _buildLineChart(data)),
          const SizedBox(height: 8),
          // Legenda
          Row(
            children: [
              _legendDot(const Color(0xFF2196F3)),
              const SizedBox(width: 4),
              Text(
                _tabGrafik == 0 ? 'Berat Badan (kg)' : 'Tinggi Badan (cm)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int idx) => GestureDetector(
    onTap: () => setState(() => _tabGrafik = idx),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _tabGrafik == idx ? const Color(0xFF2196F3) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _tabGrafik == idx ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ),
  );

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildLineChart(List<dynamic> data) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = _tabGrafik == 0
          ? (data[i]['berat_badan'] as num?)?.toDouble()
          : (data[i]['tinggi_badan'] as num?)?.toDouble();
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.isEmpty) return const SizedBox();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final tgl = (data[i]['tanggal_ukur'] ?? '').toString();
                final parts = tgl.split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    parts.length >= 2
                        ? '${parts[2].substring(0, 2)}/${parts[1]}'
                        : tgl,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, _) => Text(
                val.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY < 0 ? 0 : minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2196F3),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF2196F3),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2196F3).withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(1)} ${_tabGrafik == 0 ? 'kg' : 'cm'}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabelHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Riwayat Prediksi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            '${_prediksiTerpilih.length} data',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildBarisTabel(Map<String, dynamic> item, int index) {
    final hasil = item['hasil_prediksi'] ?? 'Tidak diketahui';
    final namaAnak = item['anak'] is Map
        ? (item['anak']['nama_anak'] ?? '-')
        : '-';
    final idAnak = item['anak'] is Map
        ? (item['anak']['_id'] ?? item['anak']['id'] ?? '')
        : (item['id_anak'] ?? '');
    final tanggal = (item['tanggal_prediksi'] ?? item['created_at'] ?? '-')
        .toString()
        .split('T')
        .first;
    final probabilitas = ((item['probabilitas']) as num?)?.toDouble() ?? 0.0;
    final color = _warnaStatus(hasil);
    final ikon = _ikonStatus(hasil);

    // Data anak terkait
    final anakData = widget.daftarAnak.firstWhere(
      (a) => (a['_id'] ?? a['id'] ?? '').toString() == idAnak.toString(),
      orElse: () => <String, dynamic>{},
    );

    return GestureDetector(
      onTap: () => Navigator.push(
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
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Nomor
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nama + tanggal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaAnak,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        tanggal,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge hasil
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(ikon, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        hasil,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Probabilitas
            if (probabilitas > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Keyakinan AI:',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: probabilitas,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(probabilitas * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
            // Tombol prediksi ulang
            if (idAnak.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final anakList = anakData.isNotEmpty
                      ? [anakData]
                      : widget.daftarAnak
                            .where(
                              (a) =>
                                  (a['_id'] ?? a['id'] ?? '').toString() ==
                                  idAnak.toString(),
                            )
                            .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CekStuntingPage(
                        isIbuDataComplete: true,
                        daftarAnak: anakList.isNotEmpty
                            ? anakList
                            : widget.daftarAnak,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      'Prediksi Ulang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
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

  Widget _buildKosong() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text(
          'Belum Ada Riwayat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lakukan Cek Stunting untuk melihat\nhasil analisis AI di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    ),
  );
}
