import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_page.dart';
import 'tambah_anak_page.dart'; // Kita akan buat file ini setelah ini

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variabel untuk mengecek apakah user sudah punya data anak
  // (Nanti ini diubah jadi dinamis ambil dari API Laravel)
  bool _hasChildData = false; 

  // Fungsi Logout
  void _logout() async {
    await AuthService().logout(); // Hapus token dari brankas
    if (!mounted) return;
    // Lempar kembali ke halaman Login dan hapus riwayat halaman
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF009888);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background Hijau Atas
            Container(
              height: 250,
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Profil & Tombol Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100'),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Selamat Pagi,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                Text('Bunda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        // Tombol Logout
                        GestureDetector(
                          onTap: () {
                            // Munculkan dialog konfirmasi sebelum logout
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Keluar Aplikasi'),
                                content: const Text('Apakah Bunda yakin ingin keluar?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _logout();
                                    }, 
                                    child: const Text('Keluar', style: TextStyle(color: Colors.red))
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.logout, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Logika Tampilan Kartu Anak
                    _hasChildData ? _buildKartuAnakAda() : _buildKartuAnakKosong(primaryColor),
                    
                    const SizedBox(height: 30),

                    // Seksi Resep
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Rekomendasi Resep', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Nutrisi tepat untuk kejar tumbuh', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        Text('Lihat Semua', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // List Resep (Sementara Dummy)
                    _buildRecipeCard('Bubur Bayam Merah & Hati Ayam Organik', '4.8', '250 kkal', '20 mnt', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: 'Pantau'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Resep'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  // TAMPILAN JIKA BELUM ADA DATA ANAK
  Widget _buildKartuAnakKosong(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Icon(Icons.child_care, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 15),
          const Text('Belum Ada Data Anak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Yuk Bunda, lengkapi data si kecil untuk mulai memantau tumbuh kembangnya.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Pindah ke halaman form input data anak
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TambahAnakPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
              child: const Text('Tambah Data Anak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // TAMPILAN JIKA SUDAH ADA DATA ANAK (Tanpa Prediksi Otomatis)
  Widget _buildKartuAnakAda() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Budi Kusuma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('2 Tahun 3 Bulan', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.cyan[50], shape: BoxShape.circle),
                child: Icon(Icons.edit, color: Colors.cyan[400], size: 20), // Tombol edit
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildIndicator('TINGGI BADAN', '82 cm', Icons.arrow_downward, Colors.red)),
              const SizedBox(width: 15),
              Expanded(child: _buildIndicator('BERAT BADAN', '10.5 kg', Icons.arrow_upward, Colors.green)),
            ],
          ),
          const SizedBox(height: 20),
          // Tombol Panggil AI (Bukan langsung memunculkan hasil)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Nanti di sini fungsi tembak API ke Python dipanggil
              },
              icon: const Icon(Icons.psychology, color: Color(0xFF009888)),
              label: const Text('Cek Status Gizi (AI)', style: TextStyle(color: Color(0xFF009888), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF009888)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIndicator(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 5),
              Icon(icon, color: iconColor, size: 16),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecipeCard(String title, String rating, String cal, String time, String imgUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(imgUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image_not_supported))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 5),
                    Text(rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.cyan[50], borderRadius: BorderRadius.circular(8)), child: Text(cal, style: TextStyle(color: Colors.cyan[700], fontSize: 11, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Row(children: [const Icon(Icons.access_time, color: Colors.grey, size: 14), const SizedBox(width: 4), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11))]),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}