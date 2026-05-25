import 'package:flutter/material.dart';

// ─── Color Tokens (Diselaraskan dengan main.dart) ──────────────────────────────
const kPrimary                = Color(0xFF006948);
const kOnPrimary              = Color(0xFFFFFFFF);
const kSurface                = Color(0xFFF8F9FF);
const kSurfaceContainerLowest = Color(0xFFFFFFFF);
const kOnSurface              = Color(0xFF0B1C30);
const kOnSurfaceVariant       = Color(0xFF3D4A42);
const kOutlineVariant         = Color(0xFFBCCAC0);
const kSecondaryContainer     = Color(0xFFD5E0F8);
const kOnSecondaryContainer   = Color(0xFF586377);

class SupplierScreen extends StatelessWidget {
  const SupplierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Daftar Supplier',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AddSmallButton(),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: 8, // Contoh jumlah data
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SupplierCard(
              name: index == 0 ? 'Global Logistics Co.' : 'Supplier Sinar Jaya ${index + 1}',
              category: 'Distribusi Logistik',
              score: (90.0 + (index * 1.2)).clamp(0, 100).toDouble(),
              status: index % 3 == 0 ? 'Prioritas' : 'Aktif',
            ),
          );
        },
      ),
    );
  }
}

// ─── Tombol Tambah di Atas ────────────────────────────────────────────────────
class _AddSmallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: kOnPrimary, size: 18),
              SizedBox(width: 4),
              Text(
                'Tambah',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supplier Card Component ──────────────────────────────────────────────────
class SupplierCard extends StatelessWidget {
  final String name;
  final String category;
  final double score;
  final String status;

  const SupplierCard({
    super.key,
    required this.name,
    required this.category,
    required this.score,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant.withOpacity(0.30), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kOnSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kOnSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol Titik Tiga (Option)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: kOnSurfaceVariant.withOpacity(0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {},
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Supplier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Badge Skor
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: kPrimary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          score.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Badge Status
                  _StatusChip(status: status),
                ],
              ),
              const Icon(Icons.chevron_right, color: kOutlineVariant, size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPriority = status == 'Prioritas';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPriority
            ? const Color(0xFF0058BE).withOpacity(0.1)
            : kSecondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPriority ? const Color(0xFF0058BE) : kOnSecondaryContainer,
        ),
      ),
    );
  }
}