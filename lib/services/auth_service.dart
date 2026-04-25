import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {

  final String baseUrl = ApiConfig.baseUrl; // IP Pusat

  // 1. Fungsi Login
  Future<bool> login(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier,
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

  // 2. Fungsi Register (Nama Anak Dihapus)
  Future<Map<String, dynamic>> register(String namaBunda, String noHp, String email, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': namaBunda, 
          'no_hp': noHp,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      // Laravel biasanya membalas dengan status 201 (Created) atau 200 (OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Pendaftaran berhasil'};
      } else {
        // Coba ambil pesan error dari response backend jika ada
        String errorMessage = 'Pendaftaran gagal! Coba lagi.';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) {
            errorMessage = data['message'];
          } else if (data['errors'] != null) {
            // Gabungkan semua pesan error validasi
            final errors = data['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.map((v) => v[0]).join(', ');
          }
        } catch (_) {
          // Jika gagal parse JSON, gunakan default message ditambah status code
          errorMessage = 'Gagal (Status: ${response.statusCode}). Detail: ${response.body}';
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Error Register: $e');
      return {'success': false, 'message': 'Tidak dapat mendaftar: $e'};
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
