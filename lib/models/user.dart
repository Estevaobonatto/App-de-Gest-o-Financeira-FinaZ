class User {
  final int? id;
  final String name;
  final String email;
  String? password; // Opcional, usado apenas no registro

  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
    );
  }
}
