import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // Sesuaikan lokasi importnya ya!

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Siapkan Penangkap Ketikan
  final TextEditingController _namaBundaController = TextEditingController();
  final TextEditingController _namaAnakController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. Siapkan loading & service
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Fungsi saat tombol daftar ditekan
  void _prosesDaftar() async {
    setState(() {
      _isLoading = true;
    });

    bool sukses = await _authService.register(
      _namaBundaController.text,
      _namaAnakController.text,
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (sukses) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran sukses! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );
      // Kembali ke halaman login setelah sukses
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran gagal! Coba gunakan email lain.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF009888);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // Fungsi tombol back di pojok kiri atas
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            ),
          ),
        ),
        title: const Text('Buat Akun Baru', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)), // Diperbaiki dari withOpacity
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.monitor_heart_outlined, color: primaryColor, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lengkapi data di bawah ini untuk memulai perjalanan gizi si kecil bersama Stunt-Check.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 30),

            // Form Inputan (Menggunakan widget bantuan di bawah)
            _buildTextField('Nama Bunda', 'Bunda Siti Aminah', Icons.person_outline, _namaBundaController),
            const SizedBox(height: 20),
            _buildTextField('Nama Anak', 'Budi Kusuma', Icons.child_care_outlined, _namaAnakController),
            const SizedBox(height: 20),
            _buildTextField('Email', 'bunda@email.com', Icons.email_outlined, _emailController),
            const SizedBox(height: 20),
            _buildTextField('Password', '••••••••', Icons.lock_outline, _passwordController, isPassword: true),
            
            const SizedBox(height: 40),
            
            // Tombol Daftar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _prosesDaftar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Daftar Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Tombol Masuk
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.pop(context), // Kembali ke halaman Login
                  child: const Text('Masuk di sini', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget bantuan yang sudah ditambahkan parameter 'controller'
  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller, // Menangkap inputan ke dalam controller
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}