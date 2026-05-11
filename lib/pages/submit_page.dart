import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubmitPage extends StatefulWidget {
  const SubmitPage({super.key});

  @override
  State<SubmitPage> createState() => _SubmitPageState();
}

class _SubmitPageState extends State<SubmitPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isSubmitted = false;
  String? _errorMessage;

  final String baseUrl = 'https://task.itprojects.web.id';

  Future<void> _submitTugas() async {
    final String name = _nameController.text.trim();
    final String priceStr = _priceController.text.trim();
    final String description = _descriptionController.text.trim();
    final String githubUrl = _githubController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || description.isEmpty || githubUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Semua field wajib diisi';
      });
      return;
    }

    final int? price = int.tryParse(priceStr);
    if (price == null) {
      setState(() {
        _errorMessage = 'Harga harus berupa angka';
      });
      return;
    }

    if (!githubUrl.startsWith('https://github.com/')) {
      setState(() {
        _errorMessage = 'URL GitHub tidak valid. Harus diawali https://github.com/';
      });
      return;
    }

    // Dialog konfirmasi sebelum submit ke server
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Submit',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        content: const Text(
          'Pastikan semua data sudah benar.\nSetelah submit, data tidak dapat diubah.',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF424242)),
            child: const Text('Submit', style: TextStyle(color: Color(0xFFE0E0E0))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? token = await _storage.read(key: 'token');

      final url = Uri.parse('$baseUrl/api/products/submit');

      // Semua request setelah login wajib menyertakan token pada header Authorization
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'price': price,
          'description': description,
          'github_url': githubUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Proses DECODING: Mengonversi String mentah ke Map
        Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            _isSubmitted = true;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal submit tugas.';
          });
        }
      } else {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Gagal submit: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Submit Tugas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE0E0E0)),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Color(0xFFBDBDBD)),
        elevation: 0,
      ),
      body: _isSubmitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E4A2E)),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Color(0xFF81C784),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tugas Berhasil Dikumpulkan!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE0E0E0),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Waktu submit telah tercatat otomatis oleh sistem.',
              style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Beranda'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBDBDBD),
                  side: const BorderSide(color: Color(0xFF424242)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2010),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A3A10)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Color(0xFFFFB74D), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pastikan data sudah benar. Endpoint API tidak menyediakan fitur edit setelah submit.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFFB74D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nama Produk'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Contoh: Laptop Gaming Asus ROG',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 18),

                _buildLabel('Harga (Rp)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                  decoration: _inputDecoration('Contoh: 15000000', Icons.attach_money_outlined),
                ),
                const SizedBox(height: 18),

                _buildLabel('Deskripsi'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                  decoration: _inputDecoration('Tulis deskripsi produk...', Icons.description_outlined),
                ),
                const SizedBox(height: 18),

                _buildLabel('Link Repository GitHub'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _githubController,
                  hint: 'https://github.com/username/repo',
                  icon: Icons.link,
                ),

                const SizedBox(height: 12),

                // Pesan error
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF5C2C2C)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFEF9A9A),
                        fontSize: 13,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitTugas,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Color(0xFFE0E0E0),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isLoading ? 'Mengumpulkan...' : 'Kumpulkan Tugas',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: const Color(0xFFE0E0E0),
                      disabledBackgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFFBDBDBD),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFE0E0E0)),
      decoration: _inputDecoration(hint, icon),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF616161)),
      prefixIcon: Icon(icon, color: const Color(0xFF757575)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
    );
  }
}
