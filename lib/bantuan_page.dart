import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher ditambahkan
import 'chatbot_page.dart'; 

class BantuanPage extends StatefulWidget {
  const BantuanPage({super.key});

  @override
  State<BantuanPage> createState() => _BantuanPageState();
}

class _BantuanPageState extends State<BantuanPage> {
  final TextEditingController _searchController = TextEditingController();

  // --- TEMA WARNA ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);
  final Color _cardBg = Colors.white;

  // --- DATA DUMMY FAQ ---
  final List<Map<String, dynamic>> _faqCategories = [
    {
      "title": "Tentang Stunt-Check",
      "icon": Icons.info_outline,
      "faqs": [
        {
          "question": "Apa itu Stunt-Check?",
          "answer": "Stunt-Check adalah aplikasi pemantauan tumbuh kembang anak yang dirancang untuk membantu orang tua dan tenaga medis mendeteksi dini risiko stunting melalui pencatatan antropometri berkala."
        },
        {
          "question": "Bagaimana cara membaca grafik pertumbuhan?",
          "answer": "Grafik menggunakan standar WHO. Garis hijau menunjukkan pertumbuhan optimal, sedangkan garis di bawah kurva peringatan menunjukkan perlunya evaluasi asupan gizi."
        },
        {
          "question": "Apakah data anak saya aman?",
          "answer": "Sangat aman. Kami menggunakan enkripsi standar industri untuk memastikan data rekam medis anak Anda hanya bisa diakses oleh Anda dan sistem analisis kami."
        },
      ]
    },
    {
      "title": "Penggunaan Alat Ukur",
      "icon": Icons.straighten_outlined,
      "faqs": [
        {
          "question": "Cara mengukur tinggi badan dengan benar",
          "answer": "Pastikan anak berdiri tegak tanpa alas kaki. Tumit, bokong, punggung, dan kepala bagian belakang harus menempel tegak lurus pada dinding atau alat ukur."
        },
        {
          "question": "Tips menimbang berat badan balita",
          "answer": "Gunakan timbangan digital yang sudah dikalibrasi. Pastikan anak memakai pakaian seminimal mungkin dan tidak memegang mainan saat ditimbang."
        },
      ]
    },
    {
      "title": "Akun & Keamanan",
      "icon": Icons.shield_outlined,
      "faqs": [
        {
          "question": "Lupa kata sandi",
          "answer": "Gunakan fitur 'Lupa Sandi' di halaman Login, atau ubah kata sandi langsung melalui menu 'Profil' -> 'Ubah Kata Sandi' jika Anda masih dalam keadaan login."
        },
        {
          "question": "Cara mengubah profil anak",
          "answer": "Buka tab Beranda, ketuk nama anak di kartu profil atas, lalu pilih opsi edit untuk memperbarui tanggal lahir atau metrik sebelumnya."
        },
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        backgroundColor: _surfaceBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bantuan & FAQ',
          style: TextStyle(
            color: _primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // KONTEN SCROLL (Pencarian & List FAQ)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _bgHitam, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Cari bantuan...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: _outlineColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Kategori FAQ Iterator
                  ..._faqCategories.map((category) => _buildFaqCategory(category)),
                  
                  // Spacer agar konten paling bawah tidak tertutup Bottom Section
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // BOTTOM SECTION FIXED (Tombol Bantuan Lanjutan)
          Container(
            padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 30),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Masih butuh bantuan?',
                  style: TextStyle(
                    color: _outlineColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tombol Chat Kila AI
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatbotPage()),
                      );
                    },
                    icon: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
                    label: const Text(
                      'Chat dengan Kila AI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // [PERBAIKAN FITUR]: Tombol WhatsApp Support
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Format nomor HP internasional tanpa angka 0 di depan
                      final String phoneNumber = "6285234063810"; 
                      final String pesan = "Halo Admin Stunt-Check, aku butuh bantuan terkait penggunaan aplikasi ini nih.";
                      
                      // Membuat URL API WhatsApp
                      final Uri waUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(pesan)}");

                      try {
                        // Membuka aplikasi WhatsApp
                        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint("Gagal membuka WhatsApp: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal membuka WhatsApp. Pastikan aplikasi WhatsApp terinstal.')),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: _primaryBlue, size: 22),
                    label: Text(
                      'WhatsApp Support',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryBlue),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _primaryBlue, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCategory(Map<String, dynamic> category) {
    List<Map<String, String>> faqs = List<Map<String, String>>.from(category['faqs']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category['icon'], color: _primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                category['title'],
                style: TextStyle(
                  color: _primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: faqs.map((faq) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: faq != faqs.last ? Colors.grey.shade200 : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent), 
                      child: ExpansionTile(
                        iconColor: _primaryBlue,
                        collapsedIconColor: Colors.grey.shade400,
                        title: Text(
                          faq['question']!,
                          style: TextStyle(
                            color: _bgHitam,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            child: Text(
                              faq['answer']!,
                              style: TextStyle(
                                color: _outlineColor,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}