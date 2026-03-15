import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ⚠️ PENTING BANGET, LANG!
  // Kalau kamu tes pakai Emulator Android: pakai http://10.0.2.2:8000/api
  // Kalau kamu tes pakai HP Fisik pakai kabel data: pakai IP Laptopmu (misal: http://192.168.1.5:8000/api)
  final String baseUrl = 'http://192.168.1.7:8000/api'; 

  // 1. Fungsi Login
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Tangkap token dari balasan Laravel
        // (Pastikan key 'token' ini sama dengan response JSON dari AuthController-mu)
        String token = data['token']; 

        // Simpan token ke brankas HP (SharedPreferences)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return true; // Login sukses!
      } else {
        return false; // Login gagal (password salah / email gak ada)
      }
    } catch (e) {
      print('Error Login: $e');
      return false;
    }
  }

  // 2. Fungsi Register
  Future<bool> register(String namaBunda, String namaAnak, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': namaBunda, 
          'nama_anak': namaAnak,
          'email': email,
          'password': password,
        }),
      );

      // Laravel biasanya membalas dengan status 201 (Created) atau 200 (OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true; // Register sukses!
      } else {
        return false; // Register gagal
      }
    } catch (e) {
      print('Error Register: $e');
      return false;
    }
  }

  // 3. Fungsi Cek Brankas (Buat ngecek user udah punya token atau belum)
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 4. Fungsi Logout (Buang token dari brankas)
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}