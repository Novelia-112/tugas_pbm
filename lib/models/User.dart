class User {
  final int id;
  final String name;
  final String username;
  final String role;
  final String className;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.className,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      // Proses mapping nested object role dan class
      role: json['role']['name'],
      className: json['class']['name'],
    );
  }
}
