import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

/// Halaman hasil prediksi stunting yang ditampilkan setelah analisis AI selesai.
class HasilPrediksiPage extends StatefulWidget {
  final String namaAnak;
  final String keterangan; // "Normal", "Berisiko Stunting", "Stunting"
  final double probabilitas; // 0.0 - 1.0
  final String? umurAnak;
  final double? beratBadan;
  final double? tinggiBadan;

  const HasilPrediksiPage({
    super.key,
    required this.namaAnak,
    required this.keterangan,
    required this.probabilitas,
    this.umurAnak,
    this.beratBadan,
    this.tinggiBadan,
  });

  @override
  State<HasilPrediksiPage> createState() => _HasilPrediksiPageState();
}

class _HasilPrediksiPageState extends State<HasilPrediksiPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    // Jalankan animasi secara berurutan
    _fadeController.forward().then((_) {
      _scaleController.forward();
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ─── Konfigurasi berdasarkan status ──────────────────────────────────────
  Color get _statusColor {
    switch (widget.keterangan.toLowerCase()) {
      case 'normal':
        return const Color(0xFF10B981); // emerald
      case 'berisiko stunting':
      case 'berisiko':
        return const Color(0xFFF59E0B); // amber
      case 'stunting':
        return const Color(0xFFEF4444); // red
      default:
        return const Color(0xFF6B7280);
    }
  }

  List<Color> get _gradientColors {
    switch (widget.keterangan.toLowerCase()) {
      case 'normal':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'berisiko stunting':
      case 'berisiko':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'stunting':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  IconData get _statusIcon {
    switch (widget.keterangan.toLowerCase()) {
      case 'normal':
        return Icons.check_circle_rounded;
      case 'berisiko stunting':
      case 'berisiko':
        return Icons.warning_rounded;
      case 'stunting':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String get _statusEmoji {
    switch (widget.keterangan.toLowerCase()) {
      case 'normal':
        return '🎉';
      case 'berisiko stunting':
      case 'berisiko':
        return '⚠️';
      case 'stunting':
        return '🚨';
      default:
        return '📊';
    }
  }

  String get _pesanUtama {
    switch (widget.keterangan.toLowerCase()) {
      case 'normal':
        return 'Pertumbuhan ${widget.namaAnak} dalam kondisi baik dan sesuai standar WHO.';
      case 'berisiko stunting':
      case 'berisiko':
        return '${widget.namaAnak} berisiko mengalami stunting. Perlu perhatian lebih pada asupan gizi.';
      case 'stunting':
        return '${widget.namaAnak} terindikasi stunting. Segera konsultasikan dengan tenaga kesehatan.';
      default:
        return 'Hasil prediksi telah tersimpan.';
    }
  }

  List<_RekomendasiItem> get _rekomendasi {
    switch (widget.keterangan.toLowerCase()) {
      case 'normal':
        return [
          _RekomendasiItem(
            icon: Icons.restaurant_rounded,
            judul: 'Pertahankan Gizi Seimbang',
            deskripsi: 'Lanjutkan pola makan bergizi seimbang dengan protein, karbohidrat, dan sayuran.',
          ),
          _RekomendasiItem(
            icon: Icons.monitor_weight_rounded,
            judul: 'Pantau Rutin',
            deskripsi: 'Tetap lakukan pemantauan berat dan tinggi badan setiap bulan di Posyandu.',
          ),
          _RekomendasiItem(
            icon: Icons.bedtime_rounded,
            judul: 'Istirahat Cukup',
            deskripsi: 'Pastikan anak tidur cukup 10–14 jam/hari untuk mendukung pertumbuhan optimal.',
          ),
        ];
      case 'berisiko stunting':
      case 'berisiko':
        return [
          _RekomendasiItem(
            icon: Icons.egg_alt_rounded,
            judul: 'Tingkatkan Asupan Protein',
            deskripsi: 'Berikan telur, ikan, daging, atau tahu tempe setiap hari untuk mendukung pertumbuhan.',
          ),
          _RekomendasiItem(
            icon: Icons.local_hospital_rounded,
            judul: 'Konsultasi ke Puskesmas',
            deskripsi: 'Kunjungi tenaga gizi di Puskesmas untuk mendapat panduan diet yang tepat.',
          ),
          _RekomendasiItem(
            icon: Icons.vaccines_rounded,
            judul: 'Cek Vitamin & Suplemen',
            deskripsi: 'Pastikan anak mendapat vitamin A, zink, dan zat besi sesuai anjuran dokter.',
          ),
        ];
      case 'stunting':
        return [
          _RekomendasiItem(
            icon: Icons.medical_services_rounded,
            judul: 'Segera ke Tenaga Kesehatan',
            deskripsi: 'Bawa anak ke dokter atau ahli gizi segera untuk penanganan lebih lanjut.',
          ),
          _RekomendasiItem(
            icon: Icons.food_bank_rounded,
            judul: 'Program Pemberian Makanan',
            deskripsi: 'Ikuti program Pemberian Makanan Tambahan (PMT) yang tersedia di Posyandu/Puskesmas.',
          ),
          _RekomendasiItem(
            icon: Icons.monitor_heart_rounded,
            judul: 'Pemantauan Intensif',
            deskripsi: 'Lakukan pemantauan pertumbuhan lebih sering, minimal 2 minggu sekali.',
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final persen = (widget.probabilitas * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App Bar dengan gradient ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: _gradientColors[0],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _gradientColors,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),

                        // Ikon hasil animasi
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _statusIcon,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Label hasil
                        Text(
                          '${_statusEmoji}  ${widget.keterangan.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.namaAnak,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // Tombol back di posisi kiri
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Kartu Kepercayaan AI ─────────────────────────────
                    _buildConfidenceCard(persen),
                    const SizedBox(height: 20),

                    // ── Kartu Detail Pengukuran ──────────────────────────
                    if (widget.beratBadan != null || widget.tinggiBadan != null || widget.umurAnak != null)
                      _buildMeasurementCard(),

                    if (widget.beratBadan != null || widget.tinggiBadan != null || widget.umurAnak != null)
                      const SizedBox(height: 20),

                    // ── Pesan Status ──────────────────────────────────────
                    _buildStatusMessageCard(),
                    const SizedBox(height: 20),

                    // ── Rekomendasi ───────────────────────────────────────
                    const Text(
                      'Rekomendasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._rekomendasi.map((r) => _buildRekomendasiCard(r)),

                    const SizedBox(height: 28),

                    // ── Tombol Aksi ───────────────────────────────────────
                    _buildActionButtons(context),

                    const SizedBox(height: 32),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hasil ini merupakan prediksi dari model AI dan bukan diagnosa medis. Selalu konsultasikan dengan tenaga kesehatan profesional.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard(String persen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: _statusColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Keyakinan Model AI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$persen%',
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar animasi
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressAnim.value * widget.probabilitas,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '${(_progressAnim.value * widget.probabilitas * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '100%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Detail Pengukuran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.umurAnak != null)
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.cake_rounded,
                    label: 'Umur',
                    value: widget.umurAnak!,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              if (widget.beratBadan != null)
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Berat',
                    value: '${widget.beratBadan} kg',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              if (widget.tinggiBadan != null)
                Expanded(
                  child: _buildMeasurementItem(
                    icon: Icons.height_rounded,
                    label: 'Tinggi',
                    value: '${widget.tinggiBadan} cm',
                    color: const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon, color: _statusColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _pesanUtama,
              style: TextStyle(
                color: _statusColor.withOpacity(0.9),
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekomendasiCard(_RekomendasiItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.deskripsi,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Tombol kembali ke home
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              // Kembali ke root (home page)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('Kembali ke Beranda'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gradientColors[0],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol prediksi lagi
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () {
              // Kembali ke halaman cek stunting
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.refresh_rounded, color: _gradientColors[0]),
            label: Text(
              'Prediksi Anak Lain',
              style: TextStyle(color: _gradientColors[0]),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _gradientColors[0], width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RekomendasiItem {
  final IconData icon;
  final String judul;
  final String deskripsi;

  const _RekomendasiItem({
    required this.icon,
    required this.judul,
    required this.deskripsi,
  });
}
