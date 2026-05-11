import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tugas_pbm/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final String baseUrl = 'https://task.itprojects.web.id';

  Future<void> _login() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username dan password tidak boleh kosong';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('$baseUrl/api/auth/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Proses DECODING: Mengonversi String mentah ke Map
        Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          // Ambil token dari response
          String token = data['data']['token'];
          String name = data['data']['user']['name'];

          // Simpan token menggunakan flutter_secure_storage
          // agar dapat digunakan pada request berikutnya
          await _storage.write(key: 'token', value: token);
          await _storage.write(key: 'name', value: name);

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userName: name),
            ),
          );
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Login gagal';
          });
        }
      } else {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Login gagal: ${response.statusCode}';
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon aplikasi
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 60,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Katalog Produk',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masuk menggunakan NIM Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 36),

                // Card form login
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: Column(
                    children: [
                      // TextField Username
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                        decoration: InputDecoration(
                          labelText: 'Username (NIM)',
                          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                          hintText: 'Masukkan NIM Anda',
                          hintStyle: const TextStyle(color: Color(0xFF616161)),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF9E9E9E),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFBDBDBD),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // TextField Password
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                        decoration: InputDecoration(
                          labelText: 'Password (NIM)',
                          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                          hintText: 'Masukkan password Anda',
                          hintStyle: const TextStyle(color: Color(0xFF616161)),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF9E9E9E),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF9E9E9E),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFBDBDBD),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                        ),
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

                      // Tombol Login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF424242),
                            foregroundColor: const Color(0xFFE0E0E0),
                            disabledBackgroundColor: const Color(0xFF2C2C2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFE0E0E0),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Gunakan NIM sebagai username dan password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF616161),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
