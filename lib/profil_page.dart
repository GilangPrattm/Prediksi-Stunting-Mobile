import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.get(Uri.parse('$_baseUrl/profil'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _nama = data['name'] ?? 'Pengguna';
          _email = data['email'] ?? '';
          if (_nama.isNotEmpty) {
            var splitted = _nama.split(' ');
            _inisial = splitted.length > 1 ? '${splitted[0][0]}${splitted[1][0]}'.toUpperCase() : _nama[0].toUpperCase();
          }
        });
      }
    } catch (e) {
      // Ignored for UI
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _keluar() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Aplikasi?'),
        content: const Text('Anda harus login kembali untuk mengakses data gizi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginPage()), (r) => false);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }

  void _ubahKataSandi() {
    TextEditingController sandiCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ubah Kata Sandi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: sandiCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: 'Masukkan Kata Sandi Baru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (sandiCtrl.text.isEmpty) return;
                        setModalState(() => isSaving = true);
                        
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        String? token = prefs.getString('token');
                        
                        try {
                           await http.put(
                            Uri.parse('$_baseUrl/profil'),
                            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                            body: jsonEncode({'name': _nama, 'email': _email, 'password': sandiCtrl.text}), // Menggunakan endpoint profil yg ada
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kata sandi berhasil diubah!'), backgroundColor: Colors.green));
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah sandi.'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A11CB), 
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Sandi Baru', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0052cc); // Warna biru khas dari gambar referensi

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB), // Warna latar belakang abu-abu sangat muda/kebiruan
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
              onPressed: () {
                // Biasanya AppBar otomatis menangani Pop, tapi karena diletakkan di HomePage (IndexedStack),
                // Poping akan keluar dari App. Jika dalam navigation bar biasa, leading sering kali disembunyikan.
                // Tapi kita sediakan untuk interaksi manual bila perlu.
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text('My Account', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: primaryBlue)) 
      : RefreshIndicator(
        onRefresh: _fetchProfil,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Profil Biru
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: primaryBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                  ]
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(_inisial, style: const TextStyle(color: primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_nama, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final refresh = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilPage()));
                        if (refresh == true) _fetchProfil();
                      },
                      icon: const Icon(Icons.edit_square, color: Colors.white),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // General Settings
              _buildSectionTitle('General Settings'),
              _buildMenuCard(context, children: [
                _buildListTile(icon: Icons.person_outline, title: 'Personal Info', onTap: () {}),
                _buildDivider(),
                _buildListTile(icon: Icons.notifications_none, title: 'Notification', onTap: () {}),
                _buildDivider(),
                _buildListTile(icon: Icons.settings_outlined, title: 'Preferences', onTap: () {}),
                _buildDivider(),
                _buildListTile(icon: Icons.lock_outline, title: 'Security', onTap: _ubahKataSandi),
              ]),

              // Accessibility
              _buildSectionTitle('Accessibility'),
              _buildMenuCard(context, children: [
                _buildListTile(icon: Icons.flag_outlined, title: 'Language', onTap: () {}),
                _buildDivider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.visibility_outlined, color: Colors.black87, size: 20),
                  ),
                  title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  trailing: Switch(
                    value: false, // Default false sementara
                    onChanged: (val) {},
                    activeColor: primaryBlue,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                ),
              ]),

              // Help & Support
              _buildSectionTitle('Help & Support'),
              _buildMenuCard(context, children: [
                _buildListTile(icon: Icons.help_outline, title: 'About', onTap: () {}),
                _buildDivider(),
                _buildListTile(icon: Icons.message_outlined, title: 'Help Center', onTap: () {}),
                _buildDivider(),
                _buildListTile(icon: Icons.phone_outlined, title: 'Contact Us', onTap: () {}),
              ]),

              // Sign Out
              _buildSectionTitle('Sign Out'),
              _buildMenuCard(context, children: [
                _buildListTile(icon: Icons.logout, title: 'Sign Out', onTap: _keluar),
              ]),

              // Danger Zone
              _buildSectionTitle('Danger Zone'),
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  ),
                  title: const Text('Delete Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Delete Account belum tersedia.')));
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 5.0),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))
        ]
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 50);
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      onTap: onTap,
    );
  }
}
