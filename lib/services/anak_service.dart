import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AnakService {
  // Mengambil dari pusat kontrol IP
  final String baseUrl = ApiConfig.baseUrl;

  Future<bool> simpanData(Map<String, dynamic> dataAnak) async {
    try {
      // 1. Ambil Token dari brankas HP
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 2. Kirim data ke Laravel bawa Token
      final response = await http.post(
        Uri.parse('$baseUrl/anak'), // Nanti kita buat rute ini di Laravel
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Ini Surat Izinnya!
        },
        body: jsonEncode(dataAnak),
      );

      // 3. Cek respon Laravel (201 = Created, 200 = OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Gagal dari server: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error kirim data anak: $e');
      return false;
    }
  }

  // Menerbangkan data Edit (PUT) ke Server
  Future<bool> editData(String idAnak, Map<String, dynamic> dataAnak) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$baseUrl/anak/$idAnak'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataAnak),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
