import 'package:flutter/material.dart';

class HasilPrediksiPage extends StatelessWidget {
  final String namaAnak;
  final String hasilPrediksi; // e.g. "Normal", "Berisiko", "Stunting"
  final double probabilitas; // 0.0 - 1.0
  final double? beratBadan;
  final double? tinggiBadan;

  const HasilPrediksiPage({
    super.key,
    required this.namaAnak,
    required this.hasilPrediksi,
    required this.probabilitas,
    this.beratBadan,
    this.tinggiBadan,
  });

  // --- DEFINISI WARNA BERDASARKAN HTML TAILWIND ---
  bool get _isNormal => hasilPrediksi.toLowerCase() == 'normal';

  Color get _primaryColor =>
      _isNormal ? const Color(0xFF006A63) : const Color(0xFFBA1A1A); // Teal / Red
  Color get _primaryContainer =>
      _isNormal ? const Color(0xFF4DB6AC) : const Color(0xFFFFDAD6);
  Color get _onPrimaryContainer =>
      _isNormal ? const Color(0xFF00433F) : const Color(0xFF410002);
  
  final Color _bgColor = const Color(0xFFF8FAFA);
  final Color _surfaceLowest = const Color(0xFFFFFFFF);
  final Color _surfaceLow = const Color(0xFFF2F4F4);
  final Color _onSurface = const Color(0xFF191C1D);
  final Color _onSurfaceVariant = const Color(0xFF3D4947);
  final Color _outline = const Color(0xFF6D7A77);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // Menyembunyikan AppBar standar karena kita memakai Hero Section custom
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 100), // Ruang untuk Bottom Nav
              children: [
                _buildHeroSection(context),
                Transform.translate(
                  offset: const Offset(0, -24), // Overlap efek seperti di HTML (-mt-6)
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildConfidenceCard(),
                        const SizedBox(height: 16),
                        _buildMeasurementDetails(),
                        const SizedBox(height: 16),
                        _buildAlertBox(),
                        const SizedBox(height: 24),
                        Text(
                          'Rekomendasi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendationsList(),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                        const SizedBox(height: 16),
                        _buildFooterNote(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Navigation Bar melayang
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET COMPONENTS
  // ==========================================

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 50, left: 20, right: 20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol Back
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            ),
          ),
          // Logo Kanan Atas
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care, color: Colors.grey, size: 30),
            ),
          ),
          // Konten Utama Hero
          Column(
            children: [
              const SizedBox(height: 30),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  _isNormal ? Icons.check_circle : Icons.warning_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isNormal ? Icons.check_circle_outline : Icons.error_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasilPrediksi.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                namaAnak,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLow),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Stunting',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface),
          ),
          const SizedBox(height: 16),
          Text(
            _isNormal
                ? 'Anak Anda terprediksi memiliki status gizi Normal. Pertumbuhannya sesuai dengan standar usianya. Teruskan pola makan sehat dan stimulasi yang baik.'
                : 'Peringatan: Berdasarkan data, anak Anda terprediksi mengalami indikasi Stunting atau Berisiko. Segera konsultasikan dengan bidan atau dokter anak untuk evaluasi lebih lanjut.',
            style: TextStyle(fontSize: 16, color: _onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final persentase = (probabilitas * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLow),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Text(
                    'Keyakinan Model AI',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$persentase%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: probabilitas,
              minHeight: 12,
              backgroundColor: _surfaceLow,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 12, color: _outline)),
              Text('$persentase%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _outline)),
              Text('100%', style: TextStyle(fontSize: 12, color: _outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Detail Pengukuran',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.monitor_weight_outlined, color: _primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${beratBadan ?? '-'} kg',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text('Berat', style: TextStyle(fontSize: 12, color: _outline)),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: _surfaceLow), // Divider vertikal
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF98A9A8).withValues(alpha: 0.2), // tertiary container
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.height, color: Color(0xFF516161)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${tinggiBadan ?? '-'} cm',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text('Tinggi', style: TextStyle(fontSize: 12, color: _outline)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isNormal ? Icons.check_circle : Icons.warning,
            color: _primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: _onPrimaryContainer, height: 1.4),
                children: [
                  TextSpan(
                    text: '$namaAnak terprediksi $hasilPrediksi. ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: _isNormal
                        ? 'Pertumbuhan fisiknya sangat baik dan sesuai dengan kurva pertumbuhan anak sehat.'
                        : 'Segera lakukan intervensi gizi untuk memperbaiki kurva pertumbuhannya.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    final List<Map<String, dynamic>> rekomendasi = _isNormal
        ? [
            {
              'icon': Icons.restaurant,
              'title': 'Pertahankan Asupan Nutrisi',
              'desc': 'Lanjutkan pemberian gizi seimbang dengan porsi yang sesuai untuk menjaga pertumbuhan optimal.',
            },
            {
              'icon': Icons.event_available,
              'title': 'Jadwal Posyandu Rutin',
              'desc': 'Tetap rutin memantau tumbuh kembang anak setiap bulan di Posyandu atau layanan kesehatan.',
            },
          ]
        : [
            {
              'icon': Icons.medical_services,
              'title': 'Konsultasi Medis',
              'desc': 'Segera hubungi bidan atau dokter anak untuk mendapatkan diagnosa klinis dan suplemen.',
            },
            {
              'icon': Icons.egg_alt,
              'title': 'Protein Hewani Tinggi',
              'desc': 'Tingkatkan asupan protein hewani harian seperti telur, ikan, atau hati ayam pada menu MPASI.',
            },
          ];

    return Column(
      children: rekomendasi.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _surfaceLow),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: _primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'],
                      style: TextStyle(fontSize: 14, color: _onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.refresh, color: _primaryColor),
            label: Text('Prediksi Anak Lain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
            style: OutlinedButton.styleFrom(
              backgroundColor: _surfaceLowest,
              side: BorderSide(color: _primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEEE), // surface-container
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hasil ini merupakan prediksi dari model AI dan bukan diagnosa medis. Selalu konsultasikan dengan tenaga kesehatan profesional.',
              style: TextStyle(fontSize: 12, color: _outline, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: _primaryColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.analytics, 'Tracker', isActive: true),
            _buildNavItem(Icons.history, 'History', isActive: false),
            _buildNavItem(Icons.menu_book, 'Resources', isActive: false),
            _buildNavItem(Icons.person_outline, 'Profile', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {required bool isActive}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? _primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isActive ? _onPrimaryContainer : _onSurfaceVariant,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? _onSurface : _onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}