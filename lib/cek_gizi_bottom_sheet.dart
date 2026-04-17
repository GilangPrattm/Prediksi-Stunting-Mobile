import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

// Fungsi Pintu Gerbang (Validasi Umur diletakkan di sini)
void tampilDialogCekGizi(BuildContext context, Map<String, dynamic> anakAktif, int umurBulan, Function onSuccess) {
  if (umurBulan > 60) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Umur anak melebihi batas 5 tahun (60 Bulan) untuk standar pengukuran stunting balita.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Biar bisa dinaikkan saat keyboard muncul
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) {
      return CekGiziForm(anakAktif: anakAktif, umurBulan: umurBulan, onSuccess: onSuccess);
    }
  );
}

class CekGiziForm extends StatefulWidget {
  final Map<String, dynamic> anakAktif;
  final int umurBulan;
  final Function onSuccess;
  
  const CekGiziForm({super.key, required this.anakAktif, required this.umurBulan, required this.onSuccess});

  @override
  State<CekGiziForm> createState() => _CekGiziFormState();
}

class _CekGiziFormState extends State<CekGiziForm> {
  final TextEditingController _bbController = TextEditingController();
  final TextEditingController _tbController = TextEditingController();
  bool _isLoading = false;

  void _simpanHistori() async {
    if (_bbController.text.isEmpty || _tbController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berat dan Tinggi Badan Wajib Diisi!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Tanggal ukuran disetel otomatis HARI INI
    String tglSkrg = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    Map<String, dynamic> payload = {
      'id_anak': widget.anakAktif['_id'] ?? widget.anakAktif['id'] ?? '',
      'umur_bulan': widget.umurBulan,
      'berat_badan': double.tryParse(_bbController.text) ?? 0,
      'tinggi_badan': double.tryParse(_tbController.text) ?? 0,
      'tanggal_ukur': tglSkrg
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pengukuran'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup Pop-Up
        widget.onSuccess(); // Perintahkan Beranda me-refresh
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Histori Pengukuran Berhasil Disimpan & Dikalkulasi!'), backgroundColor: Color(0xFFBFDBFE)));
      } else {
        final dataErr = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${dataErr['pesan'] ?? 'Server menolak'}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kegegalan sambungan jaringan.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2563EB);
    // Karena dipanggil sebagai modal bottom sheet dengan input text,
    // kita perlu menambahkan padding bottom sejumlah ukuran keyboard (viewInsets)
    double keyboardArea = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: keyboardArea + 25),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Bungkus se-ukuran isi
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.monitor_weight, color: Colors.blue)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Berapa Angka Timbangan ${widget.anakAktif['nama_anak']} Hari Ini?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Umur Tercatat: ${widget.umurBulan} Bulan', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Baris 1: Berat Badan
          const Text('Berat Badan Saat Ini (kg)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bbController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.grey[50], hintText: 'Misal: 11.2',
              prefixIcon: const Icon(Icons.fitness_center, color: primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
            ),
          ),
          const SizedBox(height: 20),

          // Baris 2: Tinggi Badan
          const Text('Tinggi Badan Saat Ini (cm)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tbController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.grey[50], hintText: 'Misal: 95',
              prefixIcon: const Icon(Icons.straighten, color: primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simpanHistori, 
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Color(0xFF1E293B))
                : const Text('Simpan Pengukuran (Panggil AI)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ),
          ),
        ],
      ),
    );
  }
}
