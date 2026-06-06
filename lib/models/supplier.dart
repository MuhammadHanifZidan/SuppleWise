import 'category.dart';

/// Model untuk data supplier.
/// Merepresentasikan tabel `suppliers` dari database.
class Supplier {
  final int id;
  final String supplierName;
  final String? contact;
  final String? address;
  final int? categoryId;
  final Category? category;

  const Supplier({
    required this.id,
    required this.supplierName,
    this.contact,
    this.address,
    this.categoryId,
    this.category,
  });

  /// Membuat instance Supplier dari JSON response API.
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      supplierName: json['supplier_name'] as String,
      contact: json['contact'] as String?,
      address: json['address'] as String?,
      categoryId: json['category_id'] as int?,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Mengkonversi instance ke Map untuk request API.
  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      'contact': contact,
      'address': address,
      'category_id': categoryId,
    };
  }
}
