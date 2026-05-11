import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tugas_pbm/models/Product.dart';
import 'package:tugas_pbm/pages/add_product_page.dart';
import 'package:tugas_pbm/pages/submit_page.dart';
import 'package:tugas_pbm/pages/login_page.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'https://task.itprojects.web.id';

  // Future disimpan di variabel agar tidak re-fetch setiap rebuild
  late Future<List<Product>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = _fetchProducts();
  }

  // Method untuk mengambil data produk dari server
  Future<List<Product>> _fetchProducts() async {
    final String? token = await _storage.read(key: 'token');

    final url = Uri.parse('$baseUrl/api/products');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Proses DECODING: Mengonversi String mentah ke Map
        Map<String, dynamic> body = json.decode(response.body);

        // Proses MAPPING: Mengonversi Map dynamic ke List<Product>
        List<dynamic> data = body['data']['products'] ?? [];
        return data.map((product) => Product.fromJson(product)).toList();
      } else {
        throw Exception('Gagal mengambil data produk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan jaringan: $e');
    }
  }

  void _refresh() {
    setState(() {
      _futureProducts = _fetchProducts();
    });
  }

  Future<void> _deleteProduct(int productId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Produk',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        content: const Text(
          'Yakin ingin menghapus produk ini?',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C2C2C)),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFEF9A9A))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final String? token = await _storage.read(key: 'token');
      final url = Uri.parse('$baseUrl/api/products/$productId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Color(0xFF424242),
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Color(0xFFE0E0E0))),
        content: const Text(
          'Yakin ingin keluar dari aplikasi?',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C2C2C)),
            child: const Text('Logout', style: TextStyle(color: Color(0xFFEF9A9A))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _storage.deleteAll();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Format harga ke format Rupiah
  String _formatHarga(double price) {
    final String priceStr = price.toStringAsFixed(0);
    final StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write('.');
      result.write(priceStr[i]);
      count++;
    }
    return 'Rp ${result.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Katalog Produk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Color(0xFFBDBDBD)),
            tooltip: 'Submit Tugas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubmitPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFBDBDBD)),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info user
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${widget.userName}!',
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daftar draft produk Anda',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // FutureBuilder untuk memuat list produk - mengikuti pola pbm10
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _futureProducts,
              builder: (context, snapshot) {
                // Evaluasi status snapshot
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFBDBDBD)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFF757575),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Terjadi kesalahan pada server:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF757575)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF424242),
                            ),
                            child: const Text(
                              'Coba Lagi',
                              style: TextStyle(color: Color(0xFFE0E0E0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  final products = snapshot.data!;

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Color(0xFF424242),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada produk',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap + untuk menambah produk',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    color: const Color(0xFFBDBDBD),
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        // Akses data menggunakan mekanisme indeks
                        final item = products[index];
                        return _buildProductCard(item);
                      },
                    ),
                  );
                }

                return const Center(child: Text('Tidak ada produk tersedia.'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          // Refresh list jika produk berhasil ditambah
          if (result == true) {
            _refresh();
          }
        },
        backgroundColor: const Color(0xFF424242),
        foregroundColor: const Color(0xFFE0E0E0),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }

  Widget _buildProductCard(Product item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon produk
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xFF757575),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Info produk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFE0E0E0),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatHarga(item.price),
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Tombol hapus
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF616161)),
              onPressed: () => _deleteProduct(item.id),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }
}
