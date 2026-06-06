/// Model untuk data kriteria penilaian supplier.
/// Merepresentasikan tabel `criterias` dari database.
class Criteria {
  final int id;
  final String criteriaName;
  final String type; // 'benefit' atau 'cost'
  final num weight;

  const Criteria({
    required this.id,
    required this.criteriaName,
    required this.type,
    required this.weight,
  });

  /// Cek apakah kriteria bertipe benefit.
  bool get isBenefit => type == 'benefit';

  /// Cek apakah kriteria bertipe cost.
  bool get isCost => type == 'cost';

  /// Membuat instance Criteria dari JSON response API.
  factory Criteria.fromJson(Map<String, dynamic> json) {
    return Criteria(
      id: json['id'] as int,
      criteriaName: json['criteria_name'] as String,
      type: json['type'] as String,
      weight: json['weight'] as num,
    );
  }

  /// Mengkonversi instance ke Map untuk request API.
  Map<String, dynamic> toJson() {
    return {
      'criteria_name': criteriaName,
      'type': type,
      'weight': weight,
    };
  }
}
