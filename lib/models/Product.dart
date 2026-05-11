class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final String createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      // Proses parsing harga dari String ke double
      price: double.parse(json['price'].toString()),
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
