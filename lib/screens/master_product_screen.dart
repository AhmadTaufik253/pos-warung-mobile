import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import 'product_form_screen.dart';

class MasterProductScreen extends StatefulWidget {
  const MasterProductScreen({super.key});

  @override
  State<MasterProductScreen> createState() => _MasterProductScreenState();
}

class _MasterProductScreenState extends State<MasterProductScreen> {
  final _searchCtrl = TextEditingController();

  void _openRestockDialog(ProductModel product) {
    final qtyCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.sliders, color: AppConstants.accentGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Restock: ${product.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sisa stok sekarang: ${CurrencyFormat.formatStock(product.currentStock)} ${product.baseUnit}', style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Tambah Stok (${product.baseUnit})',
                    hintText: 'Cth: 20',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final added = double.tryParse(qtyCtrl.text) ?? 0.0;
                        if (added <= 0) return;

                        setDialogState(() => isSubmitting = true);
                        try {
                          await ApiService.quickRestock(product.id, added);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            Provider.of<ProductProvider>(context, listen: false).loadData();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok ${product.name} berhasil ditambah!')));
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Stok'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus "${product.name}"? Data barang yang pernah memiliki riwayat transaksi akan otomatis dinonaktifkan untuk menjaga arsip buku kas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService.deleteProduct(product.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  Provider.of<ProductProvider>(context, listen: false).loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barang berhasil dihapus!')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final products = productProv.products;

    // Kalkulasi total aset stok
    final totalAsset = products.fold(0.0, (sum, p) => sum + (p.baseBuyPrice * p.currentStock));

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Master Barang Sembako', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Katalog, Stok Fisik & Satuan Grosir', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => productProv.loadData(),
          ),
        ],
      ),
      body: productProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
          : RefreshIndicator(
              onRefresh: () => productProv.loadData(),
              color: AppConstants.primaryGreen,
              child: Column(
                children: [
                  // Kartu Ringkasan Inventori + Tombol Tambah Barang
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.borderGrey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Kiri: Nilai Modal Aset
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimasi Nilai Modal Aset',
                              style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormat.toIdr(totalAsset),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryGreen,
                              ),
                            ),
                          ],
                        ),

                        // Kanan: Badge SKU + Tombol Tambah Barang
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppConstants.lightGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${products.length} SKU',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppConstants.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                                );
                              },
                              icon: const Icon(LucideIcons.plus, size: 14),
                              label: const Text(
                                'Tambah',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => productProv.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama barang atau barcode...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.borderGrey)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.borderGrey)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List Item Barang
                  Expanded(
                    child: products.isEmpty
                        ? const Center(child: Text('Belum ada data barang'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: products.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final p = products[idx];
                              final isLow = p.currentStock <= p.minStockAlert;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppConstants.borderGrey),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p.barcode ?? '-', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppConstants.textMuted)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLow ? Colors.red.shade50 : AppConstants.lightGreen,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Stok: ${CurrencyFormat.formatStock(p.currentStock)} ${p.baseUnit}',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isLow ? Colors.red.shade700 : AppConstants.primaryGreen),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('Modal: ${CurrencyFormat.toIdr(p.baseBuyPrice)} / ${p.baseUnit}', style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                                    const SizedBox(height: 6),

                                    // Varian Satuan Jual Chips
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: p.units.map((u) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppConstants.bgLight, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppConstants.borderGrey)),
                                          child: Text('${u.unitName}: ${CurrencyFormat.toIdr(u.sellPrice)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        );
                                      }).toList(),
                                    ),
                                    const Divider(height: 16),

                                    // Baris Tombol Aksi (Restock, Edit, Delete)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: AppConstants.primaryGreen),
                                          icon: const Icon(LucideIcons.sliders, size: 14),
                                          label: const Text('Restock', style: TextStyle(fontSize: 11)),
                                          onPressed: () => _openRestockDialog(p),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: Colors.blue.shade700),
                                          icon: const Icon(LucideIcons.pencil, size: 14),
                                          label: const Text('Edit', style: TextStyle(fontSize: 11)),
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)));
                                          },
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: Colors.red),
                                          icon: const Icon(LucideIcons.trash2, size: 14),
                                          label: const Text('Hapus', style: TextStyle(fontSize: 11)),
                                          onPressed: () => _confirmDelete(p),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}