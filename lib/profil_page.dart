import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import 'bantuan_page.dart';
import 'ubah_sandi_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final String _baseUrl = ApiConfig.baseUrl;
  String _nama = 'Pengguna';
  String _inisial = 'P';
  String _email = 'Memuat...';
  String _telepon = '-';
  String _namaAnak = '-';
  bool _isLoading = true;

  // --- WARNA TEMA KONSISTEN ---
  final Color _primaryBlue = const Color(0xFF1978E5);
  final Color _bgHitam = const Color(0xFF0B1C30);
  final Color _surfaceBg = const Color(0xFFF8F9FF);
  final Color _outlineColor = const Color(0xFF717785);

  @override
  void initState() {
    super.initState();
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final responseAkun = await http.get(
        Uri.parse('$_baseUrl/profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final responseIbu = await http.get(
        Uri.parse('$_baseUrl/profil-ibu'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (responseAkun.statusCode == 200) {
        final data = jsonDecode(responseAkun.body)['data'];
        if (!mounted) return;
        setState(() {
          _nama = data['name'] ?? 'Pengguna';
          _email = data['email'] ?? '';
          _telepon = data['no_hp'] ?? '-';
          if (_nama.isNotEmpty) {
            var splitted = _nama.split(' ');
            _inisial = splitted.length > 1
                ? '${splitted[0][0]}${splitted[1][0]}'.toUpperCase()
                : _nama[0].toUpperCase();
          }
        });
      }

      if (responseIbu.statusCode == 200) {
        try {
          final responseData = jsonDecode(responseIbu.body);

          // Response bisa berupa array atau object dengan key 'data'
          final dataList = responseData is List
              ? responseData
              : (responseData['data'] is List ? responseData['data'] : []);

          if (dataList is List && dataList.isNotEmpty) {
            List<String> names = [];

            // Cek jika response adalah list of profil ibu
            for (var item in dataList) {
              // Cek struktur: profil ibu punya key 'anak' yang berisi list anak
              if (item is Map && item.containsKey('anak')) {
                final listAnak = item['anak'];
                if (listAnak != null && listAnak is List) {
                  for (var a in listAnak) {
                    if (a is Map &&
                        a.containsKey('nama_anak') &&
                        a['nama_anak'] != null) {
                      names.add(a['nama_anak'] as String);
                    }
                  }
                }
              }
              // Fallback: jika item sendiri adalah anak atau punya struktur berbeda
              else if (item is Map &&
                  item.containsKey('nama_anak') &&
                  item['nama_anak'] != null) {
                names.add(item['nama_anak'] as String);
              }
            }

            if (names.isNotEmpty && mounted) {
              setState(() {
                _namaAnak = names.join(', ');
              });
            }
          }
        } catch (e) {
          debugPrint('Error parsing profil-ibu response: $e');
        }
      }
    } catch (e) {
      // Ignored for UI
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _keluar() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Aplikasi?',
          style: TextStyle(color: _bgHitam, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Anda harus login kembali untuk mengakses data gizi.',
          style: TextStyle(color: _outlineColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: _outlineColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? token = prefs.getString('token');

              if (token != null) {
                try {
                  await http.post(
                    Uri.parse('$_baseUrl/logout'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                  );
                } catch (e) {
                  debugPrint('Logout API error (ignored): $e');
                }
              }

              await prefs.clear();
              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (c) => const LoginPage()),
                (r) => false,
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _ubahKataSandi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UbahSandiPage(namaLengkap: _nama, email: _email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchProfil,
              color: _primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // HEADER BIRU & KARTU PROFIL OVERLAP
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Latar Biru Gradient Atas
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1978E5), Color(0xFF005AB4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          padding: const EdgeInsets.only(
                            top: 60,
                            left: 24,
                            right: 24,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akun Saya',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            ],
                          ),
                        ),

                        // Kartu Profil Putih (Mengambang)
                        Container(
                          margin: const EdgeInsets.only(
                            top: 110,
                            left: 20,
                            right: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 25,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryBlue.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Foto Profil + Icon Edit
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: _surfaceBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFD6E3FF),
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _inisial,
                                        style: TextStyle(
                                          color: _primaryBlue,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Nama dan Deskripsi
                              Text(
                                'Bunda $_nama',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _bgHitam,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFF60A5FA),
                                      Color(0xFF1978E5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  'Ibu dari $_namaAnak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Kontak Email & Telepon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: _primaryBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _email.isNotEmpty ? _email : '-',
                                    style: TextStyle(
                                      color: _outlineColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.phone_outlined,
                                    color: _primaryBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _telepon.isNotEmpty ? _telepon : '-',
                                      style: TextStyle(
                                        color: _outlineColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // MENU LIST
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            'Edit Profil',
                            Icons.person_outline,
                            onTap: () async {
                              final refresh = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilPage(),
                                ),
                              );
                              if (refresh == true) _fetchProfil();
                            },
                          ),
                          _buildMenuItem(
                            'Ubah Kata Sandi',
                            Icons.lock_outline,
                            onTap: _ubahKataSandi,
                          ),
                          _buildMenuItem(
                            'Bantuan & FAQ',
                            Icons.help_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BantuanPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Tombol Keluar Merah
                          GestureDetector(
                            onTap: _keluar,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2), // Rose-50
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFFE4E6),
                                ), // Rose-100
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFE11D48), // Rose-600
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Keluar Akun',
                                    style: TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primaryBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _bgHitam,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
