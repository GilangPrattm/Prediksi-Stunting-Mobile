import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Warna diatur menggunakan Teal (tema Stunt-Check). 
    // Jika ingin kembali ke biru, ubah hex ini menjadi 0xFF1978E5
    const Color primaryColor = Color(0xFF1978E5); 

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // ── 1. Background Bar (Paten menempel di layar bawah) ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4), // Bayangan lembut ke arah atas
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 65, // Tinggi rata navbar
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Beranda', 0, primaryColor),
                  _buildNavItem(Icons.history_rounded, 'Riwayat', 1, primaryColor),
                  
                  // Ruang kosong di tengah agar tombol tidak tertumpuk
                  const SizedBox(width: 60), 
                  
                  _buildNavItem(Icons.restaurant_menu_rounded, 'MPASI', 3, primaryColor),
                  _buildNavItem(Icons.person_outline_rounded, 'Profil', 4, primaryColor),
                ],
              ),
            ),
          ),
        ),

        // ── 2. Tombol Tengah (Prediksi) yang Menonjol ──
        Positioned(
          top: -25, // Nilai minus ini yang menarik tombol keluar ke atas
          child: GestureDetector(
            onTap: () => onTap(2),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5), // Garis putih tebal pembatas
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(
                Icons.analytics_outlined, 
                color: Colors.white, 
                size: 28, // Ukuran ikon sedikit lebih besar
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Fungsi Pembangun Tombol Samping ──
  Widget _buildNavItem(IconData icon, String label, int index, Color primaryColor) {
    final isSelected = currentIndex == index;
    final color = isSelected ? primaryColor : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, // Area tap mencakup seluruh tinggi navbar
      child: SizedBox(
        width: 60, // Lebar area tekan per tombol
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}