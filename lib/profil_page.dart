import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';
import 'edit_profil_page.dart';
import 'edit_anak_page.dart';
import 'login_page.dart';
import 'bantuan_page.dart';
import 'ubah_sandi_page.dart';
import 'services/auth_service.dart';

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
  
  List<dynamic> _daftarAnak = []; // Menampung list anak untuk diedit

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
      final responseAkun = await http.get(Uri.parse('$_baseUrl/profil'), headers: {'Authorization': 'Bearer $token'});
      final responseIbu = await http.get(Uri.parse('$_baseUrl/profil-ibu'), headers: {'Authorization': 'Bearer $token'});
      final responseAnak = await http.get(Uri.parse('$_baseUrl/anak'), headers: {'Authorization': 'Bearer $token'}); // Tarik data anak

      if (responseAkun.statusCode == 200) {
        final data = jsonDecode(responseAkun.body)['data'];
        if (!mounted) return;
        setState(() {
          _nama = data['name'] ?? 'Pengguna';
          _email = data['email'] ?? '';
          _telepon = data['no_hp'] ?? '-';
          if (_nama.isNotEmpty) {
            var splitted = _nama.split(' ');
            _inisial = splitted.length > 1 ? '${splitted[0][0]}${splitted[1][0]}'.toUpperCase() : _nama[0].toUpperCase();
          }
        });
      }

      if (responseAnak.statusCode == 200) {
        final dataAnak = jsonDecode(responseAnak.body)['data'];
        if (dataAnak is List) {
          if (mounted) setState(() {
            _daftarAnak = dataAnak;
            _namaAnak = _daftarAnak.map((e) => e['nama_anak']).join(', ');
            if (_namaAnak.isEmpty) _namaAnak = '-';
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logika Cerdas untuk memilih anak sebelum masuk ke EditAnakPage
  void _pilihAnakUntukDiedit() {
    if (_daftarAnak.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data anak.')));
      return;
    }
    
    if (_daftarAnak.length == 1) {
      // Jika anak cuma 1, langsung lompat ke halaman Edit
      Navigator.push(context, MaterialPageRoute(builder: (_) => EditAnakPage(dataAnak: _daftarAnak[0]))).then((_) => _fetchProfil());
    } else {
      // Jika anak lebih dari 1, munculkan pop-up pilihan di bawah
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                Text('Pilih Data Anak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _bgHitam)),
                const SizedBox(height: 16),
                ..._daftarAnak.map((anak) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.child_care, color: _primaryBlue),
                  ),
                  title: Text(anak['nama_anak'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EditAnakPage(dataAnak: anak))).then((_) => _fetchProfil());
                  },
                )).toList(),
              ],
            ),
          );
        }
      );
    }
  }

  void _keluar() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar dari Aplikasi?', style: TextStyle(color: _bgHitam, fontWeight: FontWeight.bold)),
        content: Text('Anda harus login kembali untuk mengakses data gizi.', style: TextStyle(color: _outlineColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Batal', style: TextStyle(color: _outlineColor))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Tambahkan flag loading jika diperlukan, tapi ini cukup cepat
              await AuthService().logout(); 

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginPage()), (r) => false);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
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
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1978E5), Color(0xFF005AB4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                          ),
                          padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Akun Saya', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 110, left: 20, right: 20),
                          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(color: _surfaceBg, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD6E3FF), width: 3)),
                                    child: Center(child: Text(_inisial, style: TextStyle(color: _primaryBlue, fontSize: 32, fontWeight: FontWeight.w900))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Bunda $_nama', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _bgHitam)),
                              const SizedBox(height: 4),
                              ShaderMask(
                                shaderCallback: (Rect bounds) => const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF1978E5)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds),
                                child: Text('Ibu dari $_namaAnak', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.email_outlined, color: _primaryBlue, size: 18),
                                  const SizedBox(width: 6),
                                  Text(_email.isNotEmpty ? _email : '-', style: TextStyle(color: _outlineColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 16),
                                  Icon(Icons.phone_outlined, color: _primaryBlue, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(_telepon.isNotEmpty ? _telepon : '-', style: TextStyle(color: _outlineColor, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildMenuItem('Edit Profil Ibu', Icons.person_outline, onTap: () async {
                            final refresh = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilPage()));
                            if (refresh == true) _fetchProfil();
                          }),
                          
                          // [PERBAIKAN FITUR]: Menambahkan Tombol Baru untuk Mengedit Data Anak
                          _buildMenuItem('Edit Data Anak', Icons.child_care_rounded, onTap: _pilihAnakUntukDiedit),

                          _buildMenuItem('Ubah Kata Sandi', Icons.lock_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UbahSandiPage(namaLengkap: _nama, email: _email)))),
                          _buildMenuItem('Bantuan & FAQ', Icons.help_outline, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BantuanPage()))),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _keluar,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFE4E6))),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 20),
                                  SizedBox(width: 10),
                                  Text('Keluar Akun', style: TextStyle(color: Color(0xFFE11D48), fontSize: 16, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 120), // [PERBAIKAN FITUR]: Menambah tinggi ruang bawah agar tombol logout tidak tertutup BottomNavBar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: _primaryBlue.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: _primaryBlue, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: _bgHitam, fontSize: 15, fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}