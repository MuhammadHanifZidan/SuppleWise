import 'supplier.dart';

/// Model untuk hasil ranking COPRAS dari API.
/// Merepresentasikan satu baris ranking supplier beserta skor-skornya.
class RankingResult {
  final Supplier supplier;
  final double sPlus;
  final double sMinus;
  final double q;
  final double utility;
  final int rank;
  final List<CriteriaScore> criteriaScores;

  const RankingResult({
    required this.supplier,
    required this.sPlus,
    required this.sMinus,
    required this.q,
    required this.utility,
    required this.rank,
    required this.criteriaScores,
  });

  /// Membuat instance RankingResult dari JSON response API.
  factory RankingResult.fromJson(Map<String, dynamic> json) {
    return RankingResult(
      supplier: Supplier.fromJson(json['supplier'] as Map<String, dynamic>),
      sPlus: (json['s_plus'] as num).toDouble(),
      sMinus: (json['s_minus'] as num).toDouble(),
      q: (json['q'] as num).toDouble(),
      utility: (json['utility'] as num).toDouble(),
      rank: json['rank'] as int,
      criteriaScores: (json['criteria_scores'] as List<dynamic>)
          .map((e) => CriteriaScore.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Model untuk skor individu per kriteria dalam ranking.
class CriteriaScore {
  final int criteriaId;
  final String criteriaName;
  final String type;
  final num raw;
  final double normalized;
  final double weighted;

  const CriteriaScore({
    required this.criteriaId,
    required this.criteriaName,
    required this.type,
    required this.raw,
    required this.normalized,
    required this.weighted,
  });

  /// Membuat instance CriteriaScore dari JSON response API.
  factory CriteriaScore.fromJson(Map<String, dynamic> json) {
    return CriteriaScore(
      criteriaId: json['criteria_id'] as int,
      criteriaName: json['criteria_name'] as String,
      type: json['type'] as String,
      raw: json['raw'] as num,
      normalized: (json['normalized'] as num).toDouble(),
      weighted: (json['weighted'] as num).toDouble(),
    );
  }
}
