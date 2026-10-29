import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'cart_bottom_sheet.dart';
import 'nominal_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).loadData());
  }

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Warung Paing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Aplikasi Kasir Mobile POS', style: TextStyle(fontSize: 10, color: Colors.white70)),
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
          : Column(
              children: [
                // Pencarian & Filter Kategori
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => productProv.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Cari beras, minyak, mie, gula...',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          filled: true,
                          fillColor: AppConstants.bgLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Semua', style: TextStyle(fontSize: 11)),
                              selected: productProv.selectedCategoryId == null,
                              selectedColor: AppConstants.primaryGreen,
                              labelStyle: TextStyle(color: productProv.selectedCategoryId == null ? Colors.white : Colors.black87),
                              onSelected: (_) => productProv.filterCategory(null),
                            ),
                            const SizedBox(width: 6),
                            ...productProv.categories.map((c) {
                              final isSel = productProv.selectedCategoryId == c.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(c.name, style: const TextStyle(fontSize: 11)),
                                  selected: isSel,
                                  selectedColor: AppConstants.primaryGreen,
                                  labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                                  onSelected: (_) => productProv.filterCategory(c.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Grid Katalog Produk
                Expanded(
                  child: productProv.products.isEmpty
                      ? const Center(child: Text('Barang sembako tidak ditemukan'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            // childAspectRatio: 0.65,
                            childAspectRatio: 0.88,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: productProv.products.length,
                          itemBuilder: (ctx, idx) {
                            final product = productProv.products[idx];
                            return _ProductCard(product: product);
                          },
                        ),
                ),
              ],
            ),

      // Ubah dari bottomNavigationBar menjadi bottomSheet
      bottomSheet: cartProv.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppConstants.borderGrey)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${cartProv.totalItemCount} Item Terpilih', style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                        Text(CurrencyFormat.toIdr(cartProv.grandTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryGreen)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CartBottomSheet(),
                      );
                    },
                    icon: const Icon(LucideIcons.shoppingBag, size: 16),
                    label: const Text('Keranjang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
      // Floating Bottom Navigation Bar (Keranjang Ringkas)
      // bottomNavigationBar: cartProv.items.isEmpty
      //     ? null
      //     : Container(
      //         padding: const EdgeInsets.all(12),
      //         decoration: BoxDecoration(
      //           color: Colors.white,
      //           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
      //         ),
      //         child: SafeArea(
      //           child: Row(
      //             children: [
      //               Expanded(
      //                 child: Column(
      //                   mainAxisSize: MainAxisSize.min,
      //                   crossAxisAlignment: CrossAxisAlignment.start,
      //                   children: [
      //                     Text('${cartProv.totalItemCount} Item Terpilih', style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
      //                     Text(CurrencyFormat.toIdr(cartProv.grandTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryGreen)),
      //                   ],
      //                 ),
      //               ),
      //               ElevatedButton.icon(
      //                 style: ElevatedButton.styleFrom(
      //                   backgroundColor: AppConstants.accentGreen,
      //                   foregroundColor: Colors.white,
      //                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //                 ),
      //                 onPressed: () {
      //                   showModalBottomSheet(
      //                     context: context,
      //                     isScrollControlled: true,
      //                     backgroundColor: Colors.transparent,
      //                     builder: (_) => const CartBottomSheet(),
      //                   );
      //                 },
      //                 icon: const Icon(LucideIcons.shoppingBag, size: 18),
      //                 label: const Text('Buka Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  // Simpan ID unit yang dipilih (tipe data int, bukan objek utuh)
  late int _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _initDefaultUnit();
  }

  @override
  void didUpdateWidget(covariant _ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika data produk di-refresh, pastikan ID unit tetap valid
    if (!widget.product.units.any((u) => u.id == _selectedUnitId)) {
      _initDefaultUnit();
    }
  }

  void _initDefaultUnit() {
    if (widget.product.units.isNotEmpty) {
      _selectedUnitId = widget.product.units.first.id;
    } else {
      _selectedUnitId = 0;
    }
  }

  ProductUnit get _currentUnit {
    return widget.product.units.firstWhere(
      (u) => u.id == _selectedUnitId,
      orElse: () => ProductUnit(
        id: 0,
        unitName: widget.product.baseUnit,
        conversionFactor: 1.0,
        sellPrice: widget.product.baseSellPrice,
        isBaseUnit: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final isOutOfStock = widget.product.currentStock <= 0;
    final unitToUse = _currentUnit;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Jaga tata letak tetap seimbang tanpa Spacer kosong
        children: [
          // 1. Bagian Atas: Barcode, Stok, dan Nama Produk
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product.barcode ?? '-',
                    style: const TextStyle(fontSize: 9, color: AppConstants.textMuted, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? Colors.red.shade50 : AppConstants.lightGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOutOfStock ? 'Habis' : '${CurrencyFormat.formatStock(widget.product.currentStock)} ${widget.product.baseUnit}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? Colors.red.shade700 : AppConstants.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),

          // 2. Bagian Bawah: Dropdown Satuan & Tombol Aksi
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.units.length > 1)
                DropdownButton<int>(
                  isExpanded: true,
                  isDense: true, // Dropdown lebih ramping dan rapat
                  underline: const SizedBox(),
                  value: _selectedUnitId,
                  items: widget.product.units.map((u) {
                    return DropdownMenuItem<int>(
                      value: u.id,
                      child: Text(
                        '${u.unitName} - ${CurrencyFormat.toIdr(u.sellPrice)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }).toList(),
                  onChanged: (newId) {
                    if (newId != null) {
                      setState(() => _selectedUnitId = newId);
                    }
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    CurrencyFormat.toIdr(unitToUse.sellPrice),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.primaryGreen),
                  ),
                ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              try {
                                cart.addProduct(widget.product, unitToUse);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            },
                      child: const Text('+ Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (widget.product.allowNominalBuy && !isOutOfStock) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => NominalDialog(product: widget.product),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Rp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
    // return Container(
    //   padding: const EdgeInsets.all(10),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(14),
    //     border: Border.all(color: AppConstants.borderGrey),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //         children: [
    //           Text(
    //             widget.product.barcode ?? '-',
    //             style: const TextStyle(fontSize: 9, color: AppConstants.textMuted, fontWeight: FontWeight.bold),
    //           ),
    //           Container(
    //             padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    //             decoration: BoxDecoration(
    //               color: isOutOfStock ? Colors.red.shade50 : AppConstants.lightGreen,
    //               borderRadius: BorderRadius.circular(6),
    //             ),
    //             child: Text(
    //               isOutOfStock ? 'Habis' : '${CurrencyFormat.formatStock(widget.product.currentStock)} ${widget.product.baseUnit}',
    //               style: TextStyle(
    //                 fontSize: 9,
    //                 fontWeight: FontWeight.bold,
    //                 color: isOutOfStock ? Colors.red.shade700 : AppConstants.primaryGreen,
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(height: 6),
    //       Text(
    //         widget.product.name,
    //         maxLines: 2,
    //         overflow: TextOverflow.ellipsis,
    //         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    //       ),
    //       const Spacer(),

    //       // Dropdown menggunakan tipe int (ID unik)
    //       if (widget.product.units.length > 1)
    //         DropdownButton<int>(
    //           isExpanded: true,
    //           underline: const SizedBox(),
    //           value: _selectedUnitId,
    //           items: widget.product.units.map((u) {
    //             return DropdownMenuItem<int>(
    //               value: u.id,
    //               child: Text(
    //                 '${u.unitName} - ${CurrencyFormat.toIdr(u.sellPrice)}',
    //                 style: const TextStyle(fontSize: 10),
    //               ),
    //             );
    //           }).toList(),
    //           onChanged: (newId) {
    //             if (newId != null) {
    //               setState(() => _selectedUnitId = newId);
    //             }
    //           },
    //         )
    //       else
    //         Padding(
    //           padding: const EdgeInsets.symmetric(vertical: 4),
    //           child: Text(
    //             CurrencyFormat.toIdr(unitToUse.sellPrice),
    //             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.primaryGreen),
    //           ),
    //         ),

    //       Row(
    //         children: [
    //           Expanded(
    //             child: ElevatedButton(
    //               style: ElevatedButton.styleFrom(
    //                 backgroundColor: AppConstants.accentGreen,
    //                 foregroundColor: Colors.white,
    //                 padding: const EdgeInsets.symmetric(vertical: 6),
    //                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //               ),
    //               onPressed: isOutOfStock
    //                   ? null
    //                   : () {
    //                       try {
    //                         cart.addProduct(widget.product, unitToUse);
    //                       } catch (e) {
    //                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    //                       }
    //                     },
    //               child: const Text('+ Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    //             ),
    //           ),
    //           if (widget.product.allowNominalBuy && !isOutOfStock) ...[
    //             const SizedBox(width: 4),
    //             InkWell(
    //               onTap: () => showDialog(
    //                 context: context,
    //                 builder: (_) => NominalDialog(product: widget.product),
    //               ),
    //               child: Container(
    //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    //                 decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(8)),
    //                 child: const Text('Rp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    //               ),
    //             ),
    //           ],
    //         ],
    //       ),
    //     ],
    //   ),
    // );
  }
}