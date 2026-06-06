/// Model untuk data kategori supplier.
/// Merepresentasikan tabel `categories` dari database.
class Category {
  final int id;
  final String categoryName;

  const Category({
    required this.id,
    required this.categoryName,
  });

  /// Membuat instance Category dari JSON response API.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      categoryName: json['category_name'] as String,
    );
  }

  /// Mengkonversi instance ke Map untuk request API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': categoryName,
    };
  }
}
