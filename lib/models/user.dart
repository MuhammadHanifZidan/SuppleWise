/// Model user — merepresentasikan tabel `users` dari database.
class User {
  final int id;
  final String name;
  final String email;
  final String? googleId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.googleId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      googleId: json['google_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'google_id': googleId,
  };
}
