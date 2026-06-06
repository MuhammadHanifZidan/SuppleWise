import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../models/criteria.dart';
import '../models/ranking_result.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  User? _user;

  // Data dari API
  List<Supplier> _suppliers = [];
  List<Criteria> _criteriaList = [];
  List<Category> _categories = [];
  List<RankingResult> _rankings = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>> _entrySlides;
  static const int _sectionCount = 5;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryFades = List.generate(
      _sectionCount,
      (i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(i * 0.12, (i * 0.12 + 0.4).clamp(0, 1),
            curve: Curves.easeOut),
      )),
    );
    _entrySlides = List.generate(
      _sectionCount,
      (i) =>
          Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(i * 0.12, (i * 0.12 + 0.4).clamp(0, 1),
            curve: Curves.easeOut),
      )),
    );
    _loadUser();
    _loadDashboardData();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getSuppliers(),
        ApiService.getCriteria(),
        ApiService.getCategories(),
      ]);
      _suppliers = results[0] as List<Supplier>;
      _criteriaList = results[1] as List<Criteria>;
      _categories = results[2] as List<Category>;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
        await _loadRankings(_selectedCategory!.id);
      }
      setState(() => _isLoading = false);
      _entryCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Gagal terhubung ke server.\nPastikan server Laravel berjalan.';
      });
    }
  }

  Future<void> _loadRankings(int categoryId) async {
    try {
      final result = await ApiService.getResults(categoryId);
      setState(() => _rankings = result['rankings'] as List<RankingResult>);
    } catch (e) {
      setState(() => _rankings = []);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(
      opacity: _entryFades[index],
      child: SlideTransition(position: _entrySlides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppColors.surface,
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ));
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.secondaryContainer,
                        child: Icon(Icons.person,
                            color: AppColors.onSecondaryContainer, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('SuppleWise',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.22,
                        )),
                  ]),
                  GestureDetector(
                    onTap: _loadDashboardData,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.30),
                        ),
                      ),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            )
                          : const Icon(Icons.refresh_rounded,
                              color: AppColors.onSurfaceVariant, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 24, bottom: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimated(0, _buildWelcome()),
                          const SizedBox(height: 24),
                          _buildAnimated(1, _buildAddSupplierButton()),
                          const SizedBox(height: 24),
                          _buildAnimated(2, _buildSummaryGrid()),
                          const SizedBox(height: 24),
                          if (_categories.isNotEmpty) ...[
                            _buildAnimated(3, _buildCategoryChips()),
                            const SizedBox(height: 24),
                          ],
                          _buildAnimated(4, _buildFeaturedSupplier()),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ─── Welcome Section ────────────────────────────────────────────────────
  Widget _buildWelcome() {
    final name = _user?.name ?? 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Halo, $name 👋',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 36 / 28,
            )),
        const SizedBox(height: 4),
        Text('Pantau performa supplier Anda hari ini.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
              height: 20 / 14,
            )),
      ],
    );
  }

  // ─── Add Supplier Button ────────────────────────────────────────────────
  Widget _buildAddSupplierButton() {
    return GestureDetector(
      onTap: () => widget.onNavigate(1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Tambah Supplier',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 28 / 20,
                )),
          ],
        ),
      ),
    );
  }

  // ─── Summary Grid ──────────────────────────────────────────────────────
  Widget _buildSummaryGrid() {
    return Column(children: [
      Row(children: [
        Expanded(
            child: _SummaryCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primary,
                iconBg: AppColors.primary.withValues(alpha: 0.10),
                label: 'Total Supplier',
                value: '${_suppliers.length}')),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryCard(
                icon: Icons.rule_outlined,
                iconColor: AppColors.tertiary,
                iconBg: AppColors.tertiaryContainer.withValues(alpha: 0.10),
                label: 'Kriteria Aktif',
                value: '${_criteriaList.length}')),
      ]),
      const SizedBox(height: 12),
      _SummaryCard(
        icon: Icons.category_outlined,
        iconColor: AppColors.success,
        iconBg: AppColors.success.withValues(alpha: 0.10),
        label: 'Kategori',
        value: '${_categories.length}',
        fullWidth: true,
      ),
    ]);
  }

  // ─── Category Chips ────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final sel = _selectedCategory?.id == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () async {
                    setState(() => _selectedCategory = cat);
                    await _loadRankings(cat.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : AppColors.outlineVariant
                                .withValues(alpha: 0.40),
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(cat.categoryName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                          letterSpacing: 0.2,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Featured Supplier ─────────────────────────────────────────────────
  Widget _buildFeaturedSupplier() {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Supplier Terbaik Saat Ini',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                height: 28 / 20,
              )),
          GestureDetector(
            onTap: () => widget.onNavigate(3),
            child: const Text('Lihat Semua',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                )),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_rankings.isEmpty)
        _buildEmptyRanking()
      else
        ..._rankings.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RankingCard(ranking: r),
            )),
    ]);
  }

  Widget _buildEmptyRanking() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.30)),
      ),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.analytics_outlined,
              color: AppColors.onSurfaceVariant, size: 28),
        ),
        const SizedBox(height: 16),
        const Text('Belum Ada Ranking',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            )),
        const SizedBox(height: 4),
        Text(
          'Tambahkan supplier dan isi nilai kriteria\nuntuk melihat hasil perhitungan COPRAS.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.70),
            height: 18 / 13,
          ),
        ),
      ]),
    );
  }

  // ─── Loading & Error States ────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Memuat data...',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Menghubungkan ke server',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.60),
            )),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 36),
          ),
          const SizedBox(height: 24),
          const Text('Koneksi Gagal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              )),
          const SizedBox(height: 8),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 20 / 14,
              )),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadDashboardData,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Coba Lagi',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

}

// ─── Summary Card Widget ──────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  final bool fullWidth;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: fullWidth
          ? Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.6,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                      letterSpacing: -0.24,
                    )),
              ]),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 16),
              Text(label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.6,
                    height: 16 / 12,
                  )),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: -0.24,
                    height: 32 / 24,
                  )),
            ]),
    );
  }
}

// ─── Ranking Card ─────────────────────────────────────────────────────────────
class _RankingCard extends StatelessWidget {
  final RankingResult ranking;
  const _RankingCard({required this.ranking});

  @override
  Widget build(BuildContext context) {
    final cardColor = ranking.rank == 1
        ? AppColors.primary
        : ranking.rank == 2
            ? AppColors.tertiaryContainer
            : AppColors.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ranking.rank == 1
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      ranking.rank == 1
                          ? Icons.stars_rounded
                          : Icons.workspace_premium_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text('RANK #${ranking.rank}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        )),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(ranking.supplier.supplierName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.22,
                      height: 28 / 22,
                    )),
                const SizedBox(height: 4),
                if (ranking.supplier.category != null)
                  Text(ranking.supplier.category!.categoryName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 20 / 14,
                      )),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(ranking.utility.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 36 / 28,
                )),
            Text('Utility Score',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.70),
                  letterSpacing: 0.6,
                )),
          ]),
        ]),
        const SizedBox(height: 20),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
        const SizedBox(height: 16),
        Row(children: [
          _StatChip(
              icon: Icons.trending_up_rounded,
              label: 'S+ ${ranking.sPlus.toStringAsFixed(3)}'),
          const SizedBox(width: 12),
          _StatChip(
              icon: Icons.trending_down_rounded,
              label: 'S- ${ranking.sMinus.toStringAsFixed(3)}'),
          const SizedBox(width: 12),
          _StatChip(
              icon: Icons.functions_rounded,
              label: 'Q ${ranking.q.toStringAsFixed(3)}'),
        ]),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
