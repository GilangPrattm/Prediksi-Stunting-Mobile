import 'package:flutter/material.dart';

class HasilPrediksiPage extends StatelessWidget {
  final String namaAnak;
  final String hasilPrediksi;
  final double probabilitas;
  final double? tinggiBadan;

  // Parameter JSON dari AI Laravel
  final String? rekomendasiTeks;
  final List<dynamic>? rekomendasiTerstruktur;

  const HasilPrediksiPage({
    super.key,
    required this.namaAnak,
    required this.hasilPrediksi,
    required this.probabilitas,
    this.tinggiBadan,
    this.rekomendasiTeks,
    this.rekomendasiTerstruktur,
  });

  // --- LOGIKA WARNA DINAMIS 4 STATUS ---
  bool get _isTinggi => hasilPrediksi.toLowerCase().contains('tinggi');
  bool get _isStunting => hasilPrediksi.toLowerCase().contains('stunting') || hasilPrediksi.toLowerCase().contains('pendek') || hasilPrediksi.toLowerCase().contains('berisiko');
  bool get _isSangatStunting => hasilPrediksi.toLowerCase().contains('sangat stunting') || hasilPrediksi.toLowerCase().contains('sangat pendek') || hasilPrediksi.toLowerCase().contains('severely');
  bool get _isNormal => !_isTinggi && !_isStunting && !_isSangatStunting;

  Color get _primaryColor {
    if (_isSangatStunting) return const Color(0xFFE11D48); // Rose/Merah
    if (_isStunting) return const Color(0xFFF59E0B); // Amber/Oranye
    if (_isTinggi) return const Color(0xFF1978E5); // Biru
    return const Color(0xFF10B981); // Emerald/Hijau (Normal)
  }

  Color get _primaryContainer {
    if (_isSangatStunting) return const Color(0xFFFFE4E6);
    if (_isStunting) return const Color(0xFFFEF3C7);
    if (_isTinggi) return const Color(0xFFD6E3FF);
    return const Color(0xFFD1FAE5);
  }

  Color get _onPrimaryContainer {
    if (_isSangatStunting) return const Color(0xFF881337);
    if (_isStunting) return const Color(0xFF78350F);
    if (_isTinggi) return const Color(0xFF003E9C);
    return const Color(0xFF064E3B);
  }

  final Color _bgColor = const Color(0xFFF8FAFA);
  final Color _surfaceLowest = const Color(0xFFFFFFFF);
  final Color _surfaceLow = const Color(0xFFF2F4F4);
  final Color _onSurface = const Color(0xFF191C1D);
  final Color _onSurfaceVariant = const Color(0xFF3D4947);
  final Color _outline = const Color(0xFF6D7A77);

  // --- LOGIKA CERDAS PENCOCOKAN GAMBAR (KEYWORD MATCHING) ---
  String _getImageAsset(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('ayam')) return 'assets/images/mpasi_ayam.png';
    if (name.contains('sapi') || name.contains('daging')) return 'assets/images/mpasi_daging.png';
    if (name.contains('ikan') || name.contains('salmon') || name.contains('lele') || name.contains('tuna')) return 'assets/images/mpasi_ikan.png';
    if (name.contains('telur') || name.contains('puyuh')) return 'assets/images/mpasi_telur.png';
    if (name.contains('sayur') || name.contains('bayam') || name.contains('brokoli') || name.contains('wortel')) return 'assets/images/mpasi_sayur.png';
    if (name.contains('buah') || name.contains('pisang') || name.contains('alpukat')) return 'assets/images/mpasi_buah.png';
    return 'assets/images/mpasi_default.png'; // Placeholder mangkuk bubur generik
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _buildHeroSection(context),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildConfidenceCard(),
                        const SizedBox(height: 16),
                        if (tinggiBadan != null) ...[
                          _buildMeasurementCard(),
                          const SizedBox(height: 16),
                        ],
                        _buildAlertBox(),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Rekomendasi',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF191C1D)),
                        ),
                        const SizedBox(height: 12),
                        _buildGeneralRecommendation(),
                        
                        const SizedBox(height: 24),
                        const Text(
                          'Rekomendasi Menu MPASI',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF191C1D)),
                        ),
                        const SizedBox(height: 16),
                        _buildHorizontalRecipesList(context),
                        
                        const SizedBox(height: 32),
                        _buildActionButtons(context),
                        const SizedBox(height: 16),
                        _buildFooterNote(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    IconData heroIcon = Icons.check_circle;
    if (_isTinggi) heroIcon = Icons.height;
    if (_isStunting || _isSangatStunting) heroIcon = Icons.warning_rounded;

    return Container(
      padding: const EdgeInsets.only(bottom: 48, top: 40),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(
                heroIcon,
                size: 48,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  heroIcon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  hasilPrediksi.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              namaAnak,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    String message = '';
    if (_isNormal) {
      message = 'Anak anda terprediksi memiliki status gizi Normal. Pertumbuhannya sesuai dengan standar usianya. Teruskan pola makan sehat dan stimulasi yang baik.';
    } else if (_isTinggi) {
      message = 'Anak anda memiliki pertumbuhan tinggi badan di atas rata-rata usianya. Pastikan berat badannya juga proporsional ya, Bunda!';
    } else {
      message = 'Anak anda terindikasi mengalami $hasilPrediksi. Sangat disarankan untuk segera berkonsultasi dengan dokter anak atau ahli gizi di Puskesmas terdekat.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLow),
        boxShadow: [
          BoxShadow(color: _primaryContainer.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Stunting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: _onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard() {
    int percentage = (probabilitas * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLow),
        boxShadow: [
          BoxShadow(color: _primaryContainer.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text('Keyakinan Model AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$percentage.0%', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: probabilitas,
              minHeight: 12,
              backgroundColor: const Color(0xFFECEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 12, color: _outline)),
              Text('$percentage%', style: TextStyle(fontSize: 12, color: _outline, fontWeight: FontWeight.bold)),
              Text('100%', style: TextStyle(fontSize: 12, color: _outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceLow),
        boxShadow: [
          BoxShadow(color: _primaryContainer.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: _primaryColor),
              const SizedBox(width: 8),
              Text('Detail Pengukuran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF98A9A8).withOpacity(0.2), // Tertiary container
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.height, color: Color(0xFF516161)),
                  ),
                  const SizedBox(height: 12),
                  Text('${tinggiBadan ?? 0} cm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
                  const SizedBox(height: 4),
                  Text('Tinggi', style: TextStyle(fontSize: 12, color: _outline)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBox() {
    IconData boxIcon = Icons.check_circle;
    String alertMessage = 'Pertumbuhan fisiknya sangat baik dan sesuai dengan kurva pertumbuhan anak sehat.';
    
    if (_isTinggi) {
      boxIcon = Icons.info;
      alertMessage = 'Pertumbuhan fisiknya berada di atas rata-rata usianya. Tetap pantau asupan gizi agar proporsional.';
    } else if (_isStunting || _isSangatStunting) {
      boxIcon = Icons.warning;
      alertMessage = 'Perlu intervensi gizi segera. Hubungi petugas kesehatan terdekat untuk mendapatkan arahan yang tepat.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(boxIcon, color: _primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: _onPrimaryContainer, fontSize: 15, height: 1.4),
                children: [
                  TextSpan(text: '$namaAnak terprediksi ${hasilPrediksi.toLowerCase()}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: alertMessage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralRecommendation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceLow),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saran Dari Kila AI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface)),
                const SizedBox(height: 4),
                Text(
                  (rekomendasiTeks != null && rekomendasiTeks!.isNotEmpty) 
                    ? rekomendasiTeks! 
                    : 'Lanjutkan pemberian gizi seimbang dengan porsi yang sesuai untuk menjaga pertumbuhan optimal.',
                  style: TextStyle(fontSize: 13, color: _onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRecipesList(BuildContext context) {
    if (rekomendasiTerstruktur == null || rekomendasiTerstruktur!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED), // Oranye sangat muda
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFEDD5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Color(0xFFF97316)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Terus berikan gizi seimbang seperti karbohidrat (nasi/kentang), protein hewani (telur/ikan), dan sayuran untuk mendukung masa emas si kecil.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    // Meratakan seluruh makanan dari semua nutrisi ke dalam satu list
    List<Map<String, dynamic>> allRecipes = [];
    for (var kategori in rekomendasiTerstruktur!) {
      String nutrisi = kategori['nutrisi'] ?? 'Menu Pilihan';
      List<dynamic> makananList = kategori['makanan'] ?? [];
      for (var m in makananList) {
        if (m is Map) {
          allRecipes.add({
            'nutrisi': nutrisi,
            'nama_makanan': m['nama_makanan'] ?? m['nama'] ?? m['menu'] ?? 'Resep Tanpa Nama',
            'deskripsi': m['deskripsi'] ?? m['manfaat'] ?? '',
          });
        }
      }
    }

    if (allRecipes.isEmpty) {
       return const Text('Format rekomendasi menu dari sistem tidak sesuai.', style: TextStyle(color: Colors.grey));
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: allRecipes.length,
        itemBuilder: (context, index) {
          final recipe = allRecipes[index];
          
          List<Color> iconColors = [const Color(0xFF006A63), const Color(0xFF136964), const Color(0xFF516161)];
          List<Color> bgColors = [const Color(0xFF4DB6AC).withOpacity(0.2), const Color(0xFFA4F0E9).withOpacity(0.2), const Color(0xFF98A9A8).withOpacity(0.2)];
          int colorIndex = index % 3;

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _surfaceLow),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: bgColors[colorIndex],
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(_getImageAsset(recipe['nama_makanan'])),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.05), BlendMode.darken),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recipe['nama_makanan'],
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _onSurface),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  recipe['nutrisi'],
                  style: TextStyle(fontSize: 12, color: iconColors[colorIndex], fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(recipe['nama_makanan']),
                          content: Text(recipe['deskripsi']),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('Lihat Detail', style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
            icon: const Icon(Icons.home, color: Colors.white, size: 20),
            label: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
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
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.refresh, color: _primaryColor, size: 20),
            label: Text('Prediksi Anak Lain', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryColor)),
            style: OutlinedButton.styleFrom(
              backgroundColor: _surfaceLowest,
              side: BorderSide(color: _primaryColor),
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
        color: const Color(0xFFECEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: _outline, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hasil ini merupakan prediksi dari model AI dan bukan diagnosa medis. Selalu konsultasikan dengan tenaga kesehatan profesional.',
              style: TextStyle(fontSize: 12, color: _outline, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}