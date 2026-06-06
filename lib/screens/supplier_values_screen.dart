import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/supplier.dart';
import '../models/criteria.dart';
import '../services/api_service.dart';

/// Halaman input nilai kriteria per supplier — match desain web supplier-value-manager.
class SupplierValuesScreen extends StatefulWidget {
  final Supplier supplier;
  const SupplierValuesScreen({super.key, required this.supplier});
  @override
  State<SupplierValuesScreen> createState() => _SupplierValuesScreenState();
}

class _SupplierValuesScreenState extends State<SupplierValuesScreen> with SingleTickerProviderStateMixin {
  List<Criteria> _criterias = [];
  List<Map<String, dynamic>> _allValues = [];
  Map<int, TextEditingController> _scoreControllers = {};
  Map<int, int?> _existingValueIds = {}; // criteria_id -> supplier_value id
  bool _isLoading = true;
  bool _isSaving = false;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>> _entrySlides;
  static const int _sectionCount = 2;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFades = List.generate(_sectionCount, (i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _entrySlides = List.generate(_sectionCount, (i) => Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _loadData();
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(opacity: _entryFades[index], child: SlideTransition(position: _entrySlides[index], child: child));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getCriteria(),
        ApiService.getSupplierValues(),
      ]);
      _criterias = results[0] as List<Criteria>;
      _allValues = results[1] as List<Map<String, dynamic>>;

      // Build controllers + match existing values
      _scoreControllers.forEach((_, c) => c.dispose());
      _scoreControllers = {};
      _existingValueIds = {};

      for (final c in _criterias) {
        final existing = _allValues.where((v) =>
            v['id_supplier'] == widget.supplier.id &&
            v['id_criteria'] == c.id).toList();
        if (existing.isNotEmpty) {
          _scoreControllers[c.id] = TextEditingController(text: existing.first['score'].toString());
          _existingValueIds[c.id] = existing.first['id'] as int;
        } else {
          _scoreControllers[c.id] = TextEditingController();
          _existingValueIds[c.id] = null;
        }
      }
      setState(() => _isLoading = false);
      _entryCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);
    try {
      for (final c in _criterias) {
        final text = _scoreControllers[c.id]?.text.trim() ?? '';
        if (text.isEmpty) continue;
        final score = double.tryParse(text);
        if (score == null) continue;

        final existingId = _existingValueIds[c.id];
        if (existingId != null) {
          await ApiService.updateSupplierValue(existingId, {
            'id_supplier': widget.supplier.id,
            'id_criteria': c.id,
            'score': score,
          });
        } else {
          await ApiService.upsertSupplierValue({
            'id_supplier': widget.supplier.id,
            'id_criteria': c.id,
            'score': score,
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Nilai berhasil disimpan!', style: TextStyle(fontFamily: 'Inter')),
            ]),
            backgroundColor: AppColors.primaryContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _loadData(); // refresh existing IDs
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  int get _filledCount => _scoreControllers.values.where((c) => c.text.trim().isNotEmpty).length;

  @override
  void dispose() {
    _entryCtrl.dispose();
    _scoreControllers.forEach((_, c) => c.dispose());
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nilai Kriteria', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text('Input skor per kriteria', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.secondary)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: mq.padding.bottom + 100),
              child: Column(children: [
                // ── Supplier Info Card (green card like web) ──
                _buildAnimated(0, Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.supplier.supplierName, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        if (widget.supplier.address != null)
                          Text(widget.supplier.address!, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white.withValues(alpha: 0.70))),
                      ]),
                    ),
                    Column(children: [
                      Text('$_filledCount/${_criterias.length}', style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('Terisi', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70), letterSpacing: 1)),
                    ]),
                  ]),
                )),
                const SizedBox(height: 20),

                // ── Criteria Score List ──
                _buildAnimated(1, Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.20)),
                    boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Input Nilai Kriteria', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                        Text('$_filledCount dari ${_criterias.length} terisi', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.secondary)),
                      ]),
                    ),
                    Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.15)),

                    if (_criterias.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(children: [
                          const Icon(Icons.rule_outlined, size: 40, color: AppColors.onSurfaceVariant),
                          const SizedBox(height: 12),
                          const Text('Belum ada kriteria', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant)),
                        ]),
                      )
                    else
                      ...List.generate(_criterias.length, (i) {
                        final c = _criterias[i];
                        final isBenefit = c.type == 'benefit';
                        return Container(
                          decoration: BoxDecoration(
                            border: i < _criterias.length - 1
                                ? Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.10)))
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isBenefit ? AppColors.primaryContainer.withValues(alpha: 0.15) : AppColors.errorContainer.withValues(alpha: 0.30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isBenefit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: isBenefit ? AppColors.primaryContainer : AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.criteriaName, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isBenefit ? AppColors.primaryContainer.withValues(alpha: 0.12) : AppColors.errorContainer.withValues(alpha: 0.40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(c.type.toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w800, color: isBenefit ? AppColors.primaryContainer : AppColors.error)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Bobot: ${(c.weight.toDouble() * 100).toStringAsFixed(0)}%', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.secondary)),
                                ]),
                              ]),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _scoreControllers[c.id],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.30)),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLow,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.20))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.20))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                              ),
                            ),
                          ]),
                        );
                      }),

                    // Save Button
                    Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)))),
                      padding: const EdgeInsets.all(20),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.40)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Batal', style: TextStyle(fontFamily: 'Inter', color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveAll,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Simpan Nilai', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                )),
              ]),
            ),
    );
  }
}
