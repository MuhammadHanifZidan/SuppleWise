import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/supplier.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'supplier_values_screen.dart';

/// Halaman kelola supplier — CRUD lengkap, match desain web supplier-manager.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> with SingleTickerProviderStateMixin {
  List<Supplier> _suppliers = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>> _entrySlides;
  static const int _sectionCount = 1;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFades = List.generate(_sectionCount, (i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _entrySlides = List.generate(_sectionCount, (i) => Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _loadData();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(opacity: _entryFades[index], child: SlideTransition(position: _entrySlides[index], child: child));
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getSuppliers(),
        ApiService.getCategories(),
      ]);
      setState(() {
        _suppliers = results[0] as List<Supplier>;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
      _entryCtrl.forward(from: 0);
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _showSupplierDialog({Supplier? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.supplierName ?? '');
    final contactCtrl = TextEditingController(text: existing?.contact ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    int? selectedCategoryId = existing?.categoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? 'Tambah Supplier' : 'Edit Supplier',
            style: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _DialogField(controller: nameCtrl, label: 'Nama Supplier', icon: Icons.store_outlined),
              const SizedBox(height: 16),
              _DialogField(controller: contactCtrl, label: 'Kontak', icon: Icons.phone_outlined),
              const SizedBox(height: 16),
              _DialogField(controller: addressCtrl, label: 'Alamat', icon: Icons.location_on_outlined, maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.30)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedCategoryId,
                          hint: const Text('Pilih Kategori', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant)),
                          items: _categories.isNotEmpty
                              ? _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)))).toList()
                              : [const DropdownMenuItem(value: -1, child: Text('Belum ada kategori', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.error)))],
                          onChanged: _categories.isNotEmpty ? (v) => setDialogState(() => selectedCategoryId = v) : null,
                          dropdownColor: AppColors.surfaceContainerLowest,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.onPrimaryContainer),
                      onPressed: () => _showAddCategoryDialog((newId) {
                        setDialogState(() {
                          selectedCategoryId = newId;
                        });
                      }),
                    ),
                  ),
                ],
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(fontFamily: 'Inter', color: AppColors.secondary)),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nama supplier wajib diisi'), backgroundColor: AppColors.error));
                  }
                  return;
                }
                if (selectedCategoryId == null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kategori wajib dipilih'), backgroundColor: AppColors.error));
                  }
                  return;
                }
                final data = {
                  'supplier_name': nameCtrl.text.trim(),
                  'contact': contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                  'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                  'category_id': selectedCategoryId,
                };
                try {
                  if (existing == null) {
                    await ApiService.createSupplier(data);
                  } else {
                    await ApiService.updateSupplier(existing.id, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(existing == null ? 'Tambah' : 'Simpan', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _showAddCategoryDialog(Function(int) onAdded) async {
    final catCtrl = TextEditingController();
    final result = await showDialog<Category>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kategori Baru', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: _DialogField(controller: catCtrl, label: 'Nama Kategori', icon: Icons.category_outlined),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Inter', color: AppColors.secondary)),
          ),
          FilledButton(
            onPressed: () async {
              if (catCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nama kategori wajib diisi'), backgroundColor: AppColors.error));
                return;
              }
              try {
                final newCat = await ApiService.createCategory(catCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, newCat);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tambah', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result != null) {
      await _loadData();
      onAdded(result.id);
    }
  }

  Future<void> _deleteSupplier(Supplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Supplier?', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: Text('Supplier "${s.supplierName}" akan dihapus permanen.', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(fontFamily: 'Inter', color: AppColors.secondary))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hapus', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteSupplier(s.id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suppliers', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            Text('Kelola data semua supplier Anda', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.secondary)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSupplierDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  const SizedBox(height: 16),
                  FilledButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'), style: FilledButton.styleFrom(backgroundColor: AppColors.primary)),
                ]))
              : _suppliers.isEmpty
                  ? _buildAnimated(0, _buildEmpty())
                  : _buildAnimated(0, RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: _suppliers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildSupplierCard(_suppliers[i]),
                      ),
                    )),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.storefront_outlined, size: 36, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        const Text('Belum Ada Supplier', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        const SizedBox(height: 8),
        Text('Tap tombol + untuk menambahkan supplier baru.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.70))),
      ]),
    );
  }

  Widget _buildSupplierCard(Supplier s) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.20)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupplierValuesScreen(supplier: s))).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.supplierName, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                    if (s.category != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primaryContainer.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(s.category!.categoryName, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryContainer)),
                      ),
                  ]),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: AppColors.surfaceContainerLowest,
                  onSelected: (val) {
                    if (val == 'edit') _showSupplierDialog(existing: s);
                    if (val == 'delete') _deleteSupplier(s);
                    if (val == 'values') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupplierValuesScreen(supplier: s)));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'values', child: Row(children: [Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary), SizedBox(width: 8), Text('Isi Nilai', style: TextStyle(fontFamily: 'Inter', fontSize: 14))])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppColors.tertiary), SizedBox(width: 8), Text('Edit', style: TextStyle(fontFamily: 'Inter', fontSize: 14))])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.error))])),
                  ],
                ),
              ]),
              if (s.contact != null || s.address != null) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                const SizedBox(height: 12),
                if (s.contact != null)
                  Row(children: [
                    Icon(Icons.phone_outlined, size: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.60)),
                    const SizedBox(width: 6),
                    Text(s.contact!, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant.withValues(alpha: 0.70))),
                  ]),
                if (s.address != null) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.60)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s.address!, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.onSurfaceVariant.withValues(alpha: 0.70)))),
                  ]),
                ],
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  const _DialogField({required this.controller, required this.label, required this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.60)),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.30))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.30))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
