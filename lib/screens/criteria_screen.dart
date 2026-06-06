import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/criteria.dart';
import '../services/api_service.dart';

/// Halaman kelola kriteria — match desain web criteria-manager.
class CriteriaScreen extends StatefulWidget {
  const CriteriaScreen({super.key});
  @override
  State<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends State<CriteriaScreen>
    with SingleTickerProviderStateMixin {
  List<Criteria> _criterias = [];
  bool _isLoading = true;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>> _entrySlides;
  static const int _sectionCount = 3;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryFades = List.generate(
      _sectionCount,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(
            i * 0.15,
            (i * 0.15 + 0.5).clamp(0, 1),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    _entrySlides = List.generate(
      _sectionCount,
      (i) =>
          Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(
                i * 0.15,
                (i * 0.15 + 0.5).clamp(0, 1),
                curve: Curves.easeOut,
              ),
            ),
          ),
    );
    _loadData();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _criterias = await ApiService.getCriteria();
      setState(() => _isLoading = false);
      _entryCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _totalWeight =>
      _criterias.fold(0.0, (sum, c) => sum + c.weight.toDouble());
  bool get _isWeightValid {
    final tw = _totalWeight;
    return (tw - 1.0).abs() < 0.01 || (tw - 100).abs() < 0.5;
  }

  Future<void> _showCriteriaDialog({Criteria? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.criteriaName ?? '');
    final weightCtrl = TextEditingController(
      text: existing != null ? existing.weight.toString() : '',
    );
    String type = existing?.type ?? 'benefit';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            existing == null ? 'Tambah Kriteria' : 'Edit Kriteria',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Nama Kriteria',
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.60),
                    ),
                    prefixIcon: const Icon(
                      Icons.label_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setD(() => type = 'benefit'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: type == 'benefit'
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type == 'benefit'
                                  ? AppColors.primaryContainer
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.30,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 18,
                                color: type == 'benefit'
                                    ? Colors.white
                                    : AppColors.primaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Benefit',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: type == 'benefit'
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setD(() => type = 'cost'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: type == 'cost'
                                ? AppColors.error
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type == 'cost'
                                  ? AppColors.error
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.30,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_down_rounded,
                                size: 18,
                                color: type == 'cost'
                                    ? Colors.white
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cost',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: type == 'cost'
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Bobot (contoh: 0.25)',
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.60),
                    ),
                    prefixIcon: const Icon(
                      Icons.balance_rounded,
                      size: 20,
                      color: AppColors.tertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.30),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.secondary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    weightCtrl.text.trim().isEmpty)
                  return;
                final weight = double.tryParse(weightCtrl.text.trim());
                if (weight == null) return;
                final data = {
                  'criteria_name': nameCtrl.text.trim(),
                  'type': type,
                  'weight': weight,
                };
                try {
                  if (existing == null) {
                    await ApiService.createCriteria(data);
                  } else {
                    await ApiService.updateCriteria(existing.id, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted)
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                existing == null ? 'Tambah' : 'Simpan',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteCriteria(Criteria c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Kriteria?',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${c.criteriaName}" akan dihapus permanen.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Batal',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.secondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteCriteria(c.id);
        _loadData();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final weightPct = _totalWeight > 1
        ? _totalWeight * 100
        : _totalWeight * 100;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manajemen Kriteria',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Konfigurasi bobot dan parameter evaluasi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCriteriaDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: mq.padding.bottom + 100,
                ),
                child: Column(
                  children: [
                    // ── Weight Summary Card (green like web) ──
                    _buildAnimated(
                      0,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'STATUS VALIDASI',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.90),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Total Bobot Akumulasi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${weightPct.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isWeightValid
                                            ? Icons.check_circle
                                            : Icons.error,
                                        size: 18,
                                        color: _isWeightValid
                                            ? Colors.white
                                            : const Color(0xFFFFB4AB),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isWeightValid
                                            ? 'Valid ✓'
                                            : 'Periksa bobot',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.80,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Active count card ──
                    _buildAnimated(
                      1,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.20,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_criterias.length}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Parameter Aktif',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Criteria List ──
                    _buildAnimated(
                      2,
                      Column(
                        children: [
                          if (_criterias.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.rule_outlined,
                                    size: 48,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Belum Ada Kriteria',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tambahkan kriteria untuk mulai evaluasi supplier.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: AppColors.onSurfaceVariant
                                          .withValues(alpha: 0.70),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...List.generate(_criterias.length, (i) {
                              final c = _criterias[i];
                              final isBenefit = c.type == 'benefit';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.outlineVariant
                                          .withValues(alpha: 0.20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0F172A,
                                        ).withValues(alpha: 0.04),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () =>
                                          _showCriteriaDialog(existing: c),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isBenefit
                                                    ? AppColors.primaryContainer
                                                          .withValues(
                                                            alpha: 0.15,
                                                          )
                                                    : AppColors.errorContainer
                                                          .withValues(
                                                            alpha: 0.30,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                isBenefit
                                                    ? Icons.trending_up_rounded
                                                    : Icons
                                                          .trending_down_rounded,
                                                color: isBenefit
                                                    ? AppColors.primaryContainer
                                                    : AppColors.error,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    c.criteriaName,
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isBenefit
                                                              ? AppColors
                                                                    .primaryContainer
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    )
                                                              : AppColors
                                                                    .errorContainer
                                                                    .withValues(
                                                                      alpha:
                                                                          0.40,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          c.type.toUpperCase(),
                                                          style: TextStyle(
                                                            fontFamily: 'Inter',
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: isBenefit
                                                                ? AppColors
                                                                      .primaryContainer
                                                                : AppColors
                                                                      .error,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Bobot: ${(c.weight.toDouble() * 100).toStringAsFixed(0)}%',
                                                        style: const TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .secondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Weight bar
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: AppColors
                                                    .surfaceContainerLow,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (c.weight.toDouble() * 100)
                                                      .toStringAsFixed(0),
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 20,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              color: AppColors
                                                  .surfaceContainerLowest,
                                              onSelected: (v) {
                                                if (v == 'edit')
                                                  _showCriteriaDialog(
                                                    existing: c,
                                                  );
                                                if (v == 'delete')
                                                  _deleteCriteria(c);
                                              },
                                              itemBuilder: (_) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 18,
                                                        color:
                                                            AppColors.tertiary,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        size: 18,
                                                        color: AppColors.error,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Hapus',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.error,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
