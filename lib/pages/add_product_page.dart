import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;

  final String baseUrl = 'https://task.itprojects.web.id';

  Future<void> _simpanProduk() async {
    final String name = _nameController.text.trim();
    final String priceStr = _priceController.text.trim();
    final String description = _descriptionController.text.trim();

    if (name.isEmpty || priceStr.isEmpty || description.isEmpty) {
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? token = await _storage.read(key: 'token');

      final url = Uri.parse('$baseUrl/api/products');

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
        }),
      );

      if (response.statusCode == 201) {
        // Proses DECODING: Mengonversi String mentah ke Map
        Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil disimpan!'),
              backgroundColor: Color(0xFF424242),
            ),
          );
          Navigator.pop(context, true); // true = refresh list di HomePage
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal menyimpan produk.';
          });
        }
      } else {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Gagal menyimpan produk: ${response.statusCode}';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE0E0E0)),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Color(0xFFBDBDBD)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card draft
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF757575), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Data produk yang disimpan bersifat draft dan hanya dapat dilihat oleh Anda sendiri.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
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
                    hint: 'Contoh: Macbook Pro M5 2026',
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
                    decoration: _inputDecoration('Contoh: 32450000', Icons.attach_money_outlined),
                  ),
                  const SizedBox(height: 18),

                  _buildLabel('Deskripsi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: Color(0xFFE0E0E0)),
                    decoration: _inputDecoration('Tulis deskripsi produk...', Icons.description_outlined),
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

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _simpanProduk,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Color(0xFFE0E0E0),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isLoading ? 'Menyimpan...' : 'Simpan Draft Produk',
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
