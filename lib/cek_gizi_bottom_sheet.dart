import 'package:flutter/material.dart';
import 'services/prediksi_service.dart';

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
    isScrollControlled: true,
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

  // Fungsi utama: Panggil PrediksiService (memanggil ML melalui Laravel)
  void _simpanDanPrediksi() async {
    if (_bbController.text.isEmpty || _tbController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat dan Tinggi Badan Wajib Diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Ambil ID anak (MongoDB bisa mengembalikan _id atau id)
    final String idAnak = widget.anakAktif['_id']?.toString() ??
        widget.anakAktif['id']?.toString() ?? '';

    final double beratBadan  = double.tryParse(_bbController.text) ?? 0;
    final double tinggiBadan = double.tryParse(_tbController.text) ?? 0;

    // Panggil service yang sudah terhubung ke Laravel → Python ML
    final result = await PrediksiService().hitungPrediksi(
      idAnak:      idAnak,
      umurBulan:   widget.umurBulan,
      beratBadan:  beratBadan,
      tinggiBadan: tinggiBadan,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    Navigator.pop(context); // Tutup bottom sheet
    widget.onSuccess();     // Refresh data beranda

    if (result['sukses'] == true) {
      final String hasil        = result['hasil']        ?? 'Tidak diketahui';
      final double probabilitas = result['probabilitas'] ?? 0.0;
      final String namaAnak     = result['namaAnak']     ?? widget.anakAktif['nama_anak'] ?? 'Anak';
      _tampilHasilPrediksi(context, namaAnak, hasil, probabilitas);
    } else {
      // Tampilkan pesan error (termasuk jika ML Server mati)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['pesan'] ?? 'Terjadi kesalahan.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Tampilkan dialog hasil prediksi AI (dengan probabilitas)
  void _tampilHasilPrediksi(BuildContext context, String namaAnak, String hasil, double probabilitas) {
    Color warnaBg;
    Color warnaText;
    IconData ikon;
    String pesan;

    String hasilLower = hasil.toLowerCase();
    if (hasilLower.contains('normal')) {
      warnaBg   = const Color(0xFFDCFAE6);
      warnaText = const Color(0xFF166534);
      ikon      = Icons.check_circle_rounded;
      pesan     = 'Luar biasa! Tumbuh kembang $namaAnak sesuai standar WHO. Pertahankan pola makan & aktivitasnya ya Bunda!';
    } else if (hasilLower.contains('resiko') || hasilLower.contains('risiko') || hasilLower.contains('berisiko')) {
      warnaBg   = const Color(0xFFFFF7CD);
      warnaText = const Color(0xFF92400E);
      ikon      = Icons.warning_amber_rounded;
      pesan     = 'Perlu perhatian lebih Bunda. $namaAnak berisiko mengalami stunting. Segera konsultasikan ke dokter atau Puskesmas terdekat.';
    } else {
      warnaBg   = const Color(0xFFFFE4E4);
      warnaText = const Color(0xFF991B1B);
      ikon      = Icons.dangerous_rounded;
      pesan     = '$namaAnak terdeteksi mengalami stunting. Jangan panik Bunda, segera konsultasikan ke tenaga medis untuk penanganan lebih lanjut.';
    }

    // Format probabilitas ke persentase (misal: 0.9234 → "92.34%")
    final String persenStr = '${(probabilitas * 100).toStringAsFixed(1)}%';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: warnaBg, shape: BoxShape.circle),
                child: Icon(ikon, color: warnaText, size: 50),
              ),
              const SizedBox(height: 20),
              Text(
                'Hasil Analisis Kila AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: warnaBg, borderRadius: BorderRadius.circular(15)),
                child: Text(
                  hasil,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: warnaText),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              // Tampilkan probabilitas dari ML model
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Tingkat Keyakinan AI: $persenStr',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                pesan,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFDBFE),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    'Mengerti, Terima Kasih',
                    style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2563EB);
    double keyboardArea = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: keyboardArea + 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: const Icon(Icons.monitor_weight, color: Colors.blue),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berapa Angka Timbangan ${widget.anakAktif['nama_anak']} Hari Ini?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Umur Tercatat: ${widget.umurBulan} Bulan',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Info chip: Kila AI akan menganalisis
          Container(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kila AI akan menganalisis status stunting secara otomatis setelah data disimpan.',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Baris 1: Berat Badan
          const Text('Berat Badan Saat Ini (kg)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bbController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.grey[50], hintText: 'Misal: 11.2',
              prefixIcon: const Icon(Icons.fitness_center, color: primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simpanDanPrediksi,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Kila AI sedang menganalisis...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text(
                      'Analisis dengan Kila AI 🤖',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
