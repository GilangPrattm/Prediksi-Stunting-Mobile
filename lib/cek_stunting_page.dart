import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme/app_theme.dart';
import 'widgets/colorful_icon.dart';

class CekStuntingPage extends StatefulWidget {
  final bool isIbuDataComplete;

  const CekStuntingPage({super.key, this.isIbuDataComplete = false});

  @override
  State<CekStuntingPage> createState() => _CekStuntingPageState();
}

class _CekStuntingPageState extends State<CekStuntingPage> {
  late PageController _pageController;
  int _currentStep = 0;
  bool _isLoading = false;

  // Global Keys for Form Validation
  final _formKeyIbu = GlobalKey<FormState>();
  final _formKeyAnak = GlobalKey<FormState>();

  // Controllers - Ibu
  final TextEditingController _namaIbuCtrl = TextEditingController();
  final TextEditingController _umurIbuCtrl = TextEditingController();
  String? _pendidikanIbu;
  String? _pekerjaanIbu;

  // Controllers - Anak
  final TextEditingController _namaAnakCtrl = TextEditingController();
  final TextEditingController _umurAnakCtrl = TextEditingController();
  final TextEditingController _beratCtrl = TextEditingController();
  final TextEditingController _tinggiCtrl = TextEditingController();
  String? _jenisKelaminAnak;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.isIbuDataComplete ? 1 : 0;
    _currentStep = initialPage;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _namaIbuCtrl.dispose();
    _umurIbuCtrl.dispose();
    _namaAnakCtrl.dispose();
    _umurAnakCtrl.dispose();
    _beratCtrl.dispose();
    _tinggiCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validasi Form Ibu
    if (_currentStep == 0) {
      if (_formKeyIbu.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } 
    // Validasi Form Anak & Prediksi
    else if (_currentStep == 1) {
      if (_formKeyAnak.currentState!.validate()) {
        _submitPrediksi();
      }
    }
  }

  Future<void> _submitPrediksi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Dummy Payload - sesuaikan dengan endpoint Laravel
      final payload = {
        'nama_anak': _namaAnakCtrl.text,
        'jenis_kelamin': _jenisKelaminAnak,
        'umur_bulan': int.tryParse(_umurAnakCtrl.text) ?? 0,
        'berat_badan': double.tryParse(_beratCtrl.text) ?? 0.0,
        'tinggi_badan': double.tryParse(_tinggiCtrl.text) ?? 0.0,
        // Data ibu jika perlu dikirim lagi
        'nama_ibu': _namaIbuCtrl.text,
        'umur_ibu': int.tryParse(_umurIbuCtrl.text) ?? 0,
        'pendidikan_ibu': _pendidikanIbu,
        'pekerjaan_ibu': _pekerjaanIbu,
      };

      // TODO: Ganti URL dengan endpoint API Laravel yang sebenarnya
      /*
      final response = await http.post(
        Uri.parse('http://192.168.x.x:8000/api/prediksi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      */
      
      // Simulasi delay request
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prediksi berhasil dikirim! (Simulasi)'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigasi ke halaman hasil prediksi
        // Navigator.push(context, MaterialPageRoute(...));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper Validators
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Harus berupa angka valid';
    }
    if (number < 0) {
      return 'Angka tidak boleh minus';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Stunting'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(0, 'Data Ibu', Icons.pregnant_woman),
                Container(
                  width: 50,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: _currentStep >= 1 ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
                _buildStepIndicator(1, 'Data Anak', Icons.child_care),
              ],
            ),
          ),
          
          // Page View Form
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe manual
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildFormIbu(),
                _buildFormAnak(),
              ],
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(_currentStep == 0 ? 'Lanjut ke Data Anak' : 'Prediksi Sekarang'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    bool isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        ColorfulIcon(
          icon: icon,
          color: isActive ? AppTheme.primaryColor : Colors.grey,
          size: 28,
          padding: 14,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFormIbu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKeyIbu,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lengkapi Data Diri Ibu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('Data ini membantu kami memberikan hasil yang lebih akurat.', style: TextStyle(color: AppTheme.textLight)),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _namaIbuCtrl,
              label: 'Nama Lengkap Ibu',
              hint: 'Contoh: Siti Aminah',
              validator: (v) => _validateRequired(v, 'Nama'),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _umurIbuCtrl,
              label: 'Umur Ibu (Tahun)',
              hint: 'Contoh: 28',
              keyboardType: TextInputType.number,
              validator: (v) => _validateNumber(v, 'Umur'),
            ),
            const SizedBox(height: 16),
            
            _buildDropdownField(
              label: 'Pendidikan Terakhir',
              value: _pendidikanIbu,
              items: const ['SD', 'SMP', 'SMA', 'D3', 'S1', 'S2', 'Lainnya'],
              onChanged: (v) => setState(() => _pendidikanIbu = v),
              validator: (v) => _validateRequired(v, 'Pendidikan'),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Pekerjaan Ibu',
              value: _pekerjaanIbu,
              items: const ['Ibu Rumah Tangga', 'Karyawan Swasta', 'PNS', 'Wiraswasta', 'Lainnya'],
              onChanged: (v) => setState(() => _pekerjaanIbu = v),
              validator: (v) => _validateRequired(v, 'Pekerjaan'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormAnak() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKeyAnak,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Pertumbuhan Anak', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('Masukkan hasil pengukuran terakhir si kecil.', style: TextStyle(color: AppTheme.textLight)),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _namaAnakCtrl,
              label: 'Nama Panggilan Anak',
              hint: 'Contoh: Budi',
              validator: (v) => _validateRequired(v, 'Nama Anak'),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Jenis Kelamin',
              value: _jenisKelaminAnak,
              items: const ['Laki-laki', 'Perempuan'],
              onChanged: (v) => setState(() => _jenisKelaminAnak = v),
              validator: (v) => _validateRequired(v, 'Jenis Kelamin'),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _umurAnakCtrl,
              label: 'Umur Anak (Bulan)',
              hint: 'Contoh: 12',
              keyboardType: TextInputType.number,
              validator: (v) => _validateNumber(v, 'Umur'),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _beratCtrl,
                    label: 'Berat (kg)',
                    hint: 'Misal: 9.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateNumber(v, 'Berat'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _tinggiCtrl,
                    label: 'Tinggi (cm)',
                    hint: 'Misal: 75',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateNumber(v, 'Tinggi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            errorStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
