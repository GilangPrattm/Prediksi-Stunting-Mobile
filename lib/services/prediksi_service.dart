import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service untuk semua operasi prediksi stunting ke Laravel API.
/// Laravel yang kemudian meneruskan ke Python FastAPI ML Server.
class PrediksiService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Mendapatkan token dari SharedPreferences
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Mengirim data pengukuran & meminta prediksi stunting dari ML Server
  /// melalui Laravel backend.
  ///
  /// [idAnak]     - MongoDB _id dari anak
  /// [umurBulan]  - Umur anak dalam satuan bulan
  /// [beratBadan] - Berat badan dalam kg (misal: 11.5)
  /// [tinggiBadan]- Tinggi badan dalam cm (misal: 85.0)
  ///
  /// Returns map berisi:
  /// {
  ///   'sukses': bool,
  ///   'hasil': String,         // "Normal" / "Berisiko Stunting" / "Stunting"
  ///   'probabilitas': double,  // contoh: 0.9234
  ///   'namaAnak': String,
  ///   'idPrediksi': String,
  ///   'pesan': String,         // pesan error jika sukses == false
  /// }
  Future<Map<String, dynamic>> hitungPrediksi({
    required String idAnak,
    required int umurBulan,
    required double beratBadan,
    required double tinggiBadan,
  }) async {
    final String? token = await _getToken();

    final Map<String, dynamic> payload = {
      'id_anak': idAnak,
      'umur_bulan': umurBulan,
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
    };

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/prediksi/hitung'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => http.Response(
              jsonEncode({'pesan': 'Koneksi timeout. Server ML mungkin sedang dimuat.'}),
              408,
            ),
          );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = responseBody['data'] as Map<String, dynamic>;
        return {
          'sukses': true,
          'hasil': data['hasil'] ?? 'Tidak diketahui',
          'probabilitas': (data['probabilitas'] as num?)?.toDouble() ?? 0.0,
          'namaAnak': data['anak'] ?? 'Anak',
          'idPrediksi': data['id_prediksi']?.toString() ?? '',
          'detailAi': data['detail_ai'],
        };
      } else if (response.statusCode == 503) {
        // ML Server tidak aktif
        return {
          'sukses': false,
          'pesan': 'Server AI belum aktif. Hubungi admin untuk mengaktifkan.',
        };
      } else {
        return {
          'sukses': false,
          'pesan': responseBody['pesan'] ?? 'Terjadi kesalahan pada server.',
        };
      }
    } catch (e) {
      return {
        'sukses': false,
        'pesan': 'Tidak dapat terhubung ke server. Periksa koneksi internet kamu.',
      };
    }
  }

  /// Mengambil semua riwayat prediksi milik user yang login
  Future<Map<String, dynamic>> getRiwayatPrediksi() async {
    final String? token = await _getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prediksi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'sukses': true,
          'data': responseBody['data'] as List<dynamic>,
        };
      } else {
        return {
          'sukses': false,
          'pesan': responseBody['pesan'] ?? 'Gagal mengambil riwayat.',
          'data': <dynamic>[],
        };
      }
    } catch (e) {
      return {
        'sukses': false,
        'pesan': 'Koneksi gagal: $e',
        'data': <dynamic>[],
      };
    }
  }

  /// Menghapus satu riwayat prediksi berdasarkan ID
  Future<bool> hapusPrediksi(String idPrediksi) async {
    final String? token = await _getToken();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/prediksi/$idPrediksi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
