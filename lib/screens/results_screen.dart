import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/category.dart';
import '../models/criteria.dart';
import '../models/ranking_result.dart';
import '../services/api_service.dart';

/// Halaman hasil COPRAS — match desain web result-manager.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<RankingResult> _rankings = [];
  List<Criteria> _criterias = [];
  int _supplierCount = 0;
  bool _isLoading = true;
  bool _isLoadingResults = false;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>> _entrySlides;
  static const int _sectionCount = 5;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFades = List.generate(_sectionCount, (i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _entrySlides = List.generate(_sectionCount, (i) => Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _loadInitial();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(opacity: _entryFades[index], child: SlideTransition(position: _entrySlides[index], child: child));
  }

  Future<void> _loadInitial() async {
    setState(() => _isLoading = true);
    try {
      _categories = await ApiService.getCategories();
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
        await _loadResults(_selectedCategory!.id);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadResults(int categoryId) async {
    setState(() => _isLoadingResults = true);
    try {
      final result = await ApiService.getResults(categoryId);
      setState(() {
        _rankings = result['rankings'] as List<RankingResult>;
        _supplierCount = result['supplier_count'] as int;
        // Parse criterias from response
        final critList = result['criterias'] as List<dynamic>?;
        if (critList != null) {
          _criterias = critList.map((c) => Criteria.fromJson(c as Map<String, dynamic>)).toList();
        }
        _isLoadingResults = false;
      });
      _entryCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _rankings = [];
        _isLoadingResults = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hasil Keputusan', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
          Text('Analisis COPRAS', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.secondary)),
        ]),
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: _isLoadingResults
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.refresh_rounded, color: AppColors.onSurfaceVariant),
              onPressed: _isLoadingResults ? null : () => _loadResults(_selectedCategory!.id),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadInitial,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: mq.padding.bottom + 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── Category Selector ──
                  if (_categories.isNotEmpty) ...[
                    _buildAnimated(0, SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _categories.map((cat) {
                        final sel = _selectedCategory?.id == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () async {
                              setState(() => _selectedCategory = cat);
                              await _loadResults(cat.id);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: sel ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.40)),
                              ),
                              child: Text(cat.categoryName, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.onSurfaceVariant)),
                            ),
                          ),
                        );
                      }).toList()),
                    )),
                    const SizedBox(height: 20),
                  ],

                  if (_rankings.isNotEmpty) ...[
                    // ── Featured #1 Card ──
                    _buildAnimated(1, _buildTopCard(_rankings.first)),
                    const SizedBox(height: 20),

                    // ── Visual Comparison ──
                    _buildAnimated(2, _buildComparisonChart()),
                    const SizedBox(height: 16),

                    // ── Stats Row ──
                    _buildAnimated(3, Row(children: [
                      Expanded(child: _StatMini(icon: Icons.groups_outlined, label: 'Total Supplier', value: '$_supplierCount')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatMini(icon: Icons.balance_rounded, label: 'Kriteria', value: '${_criterias.length}')),
                    ])),
                    const SizedBox(height: 20),

                    // ── Full Rankings ──
                    _buildAnimated(4, _buildFullRankings()),
                  ] else ...[
                    // ── Empty State ──
                    const SizedBox(height: 40),
                    _buildAnimated(1, _buildEmptyState()),
                  ],
                ]),
              ),
            ),
    );
  }

  Widget _buildTopCard(RankingResult top) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text('REKOMENDASI UTAMA', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.90), letterSpacing: 1.2)),
          ]),
        ),
        const SizedBox(height: 12),
        Text(top.supplier.supplierName, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
        const SizedBox(height: 4),
        if (top.supplier.address != null || top.supplier.contact != null)
          Text(
            [top.supplier.address, top.supplier.contact].where((e) => e != null).join(' • '),
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white.withValues(alpha: 0.70)),
          ),
        const SizedBox(height: 20),
        Row(children: [
          Column(children: [
            Text('${top.utility.toStringAsFixed(1)}%', style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('Utilitas', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70), letterSpacing: 1)),
          ]),
          const SizedBox(width: 24),
          Container(width: 1, height: 48, color: Colors.white.withValues(alpha: 0.20)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(children: [
              ...top.criteriaScores.take(2).map((cs) {
                final pct = (cs.weighted * 100 * 4).clamp(0, 100).toInt();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(cs.criteriaName, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.80))),
                      Text('$pct%', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.80))),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct / 100, minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.20),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildComparisonChart() {
    final top5 = _rankings.take(5).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.20)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Perbandingan Visual', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 16),
        ...top5.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final barWidth = item.utility.round().clamp(0, 100);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text(item.supplier.supplierName, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: idx == 0 ? FontWeight.w700 : FontWeight.w500, color: AppColors.onSurface), overflow: TextOverflow.ellipsis)),
                Text('${item.utility.toStringAsFixed(1)}%', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: idx == 0 ? FontWeight.w700 : FontWeight.w500, color: idx == 0 ? AppColors.primary : AppColors.secondary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: barWidth / 100, minHeight: 10,
                  backgroundColor: AppColors.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation(idx == 0 ? AppColors.primary : AppColors.secondaryFixedDim),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildFullRankings() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.20)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Daftar Lengkap Peringkat', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        ),
        Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ...List.generate(_rankings.length, (i) {
          final item = _rankings[i];
          String status;
          Color statusColor, statusBg;
          if (item.utility >= 80) { status = 'Sangat Baik'; statusColor = AppColors.primaryContainer; statusBg = AppColors.primaryContainer.withValues(alpha: 0.12); }
          else if (item.utility >= 60) { status = 'Baik'; statusColor = AppColors.primaryContainer; statusBg = AppColors.primaryContainer.withValues(alpha: 0.12); }
          else if (item.utility >= 40) { status = 'Rata-rata'; statusColor = AppColors.secondary; statusBg = AppColors.secondaryContainer.withValues(alpha: 0.30); }
          else { status = 'Kurang'; statusColor = AppColors.error; statusBg = AppColors.errorContainer.withValues(alpha: 0.30); }

          return Container(
            decoration: BoxDecoration(border: i < _rankings.length - 1 ? Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.10))) : null),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(children: [
              // Rank badge
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: item.rank == 1 ? AppColors.primary : item.rank <= 3 ? AppColors.primaryContainer.withValues(alpha: 0.18) : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(child: Text('${item.rank}', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w800, color: item.rank == 1 ? Colors.white : item.rank <= 3 ? AppColors.primary : AppColors.secondary))),
              ),
              const SizedBox(width: 14),

              // Name + address
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.supplier.supplierName, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                Row(children: [
                  Text('S+ ${item.sPlus.toStringAsFixed(3)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.secondary)),
                  const SizedBox(width: 6),
                  Text('S- ${item.sMinus.toStringAsFixed(3)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.secondary)),
                  const SizedBox(width: 6),
                  Text('Q ${item.q.toStringAsFixed(3)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.secondary)),
                ]),
              ])),

              // Utility + Status
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${item.utility.toStringAsFixed(1)}%', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w800, color: item.rank == 1 ? AppColors.primary : AppColors.onSurface)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.analytics_outlined, size: 36, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        const Text('Belum Ada Data untuk Dihitung', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 8),
        Text('Pastikan sudah menambahkan Supplier,\nKriteria, dan mengisi Nilai Supplier.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.70), height: 20 / 14)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _InfoChip(icon: Icons.storefront_outlined, label: 'Supplier: $_supplierCount'),
          const SizedBox(width: 12),
          _InfoChip(icon: Icons.tune_outlined, label: 'Kriteria: ${_criterias.length}'),
        ]),
      ]),
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatMini({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary, letterSpacing: 0.5)),
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
        ]),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.30))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
      ]),
    );
  }
}
