import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product; // Jika null = Tambah Baru, jika ada = Edit
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _UnitInputItem {
  final TextEditingController nameController;
  final TextEditingController factorController;
  final TextEditingController priceController;

  _UnitInputItem({
    required String name,
    required double factor,
    required double price,
  })  : nameController = TextEditingController(text: name),
        factorController = TextEditingController(text: factor.toStringAsFixed(factor.truncateToDouble() == factor ? 0 : 3)),
        priceController = TextEditingController(text: price.toStringAsFixed(0));
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _baseUnitCtrl = TextEditingController(text: 'pcs');
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '5');

  int? _selectedCategoryId;
  bool _allowNominal = false;
  bool _isSaving = false;
  final List<_UnitInputItem> _unitRows = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _barcodeCtrl.text = p.barcode ?? '';
      _nameCtrl.text = p.name;
      _baseUnitCtrl.text = p.baseUnit;
      _buyPriceCtrl.text = p.baseBuyPrice.toStringAsFixed(0);
      _sellPriceCtrl.text = p.baseSellPrice.toStringAsFixed(0);
      _stockCtrl.text = p.currentStock.toStringAsFixed(p.currentStock.truncateToDouble() == p.currentStock ? 0 : 2);
      _minStockCtrl.text = p.minStockAlert.toStringAsFixed(0);
      _selectedCategoryId = p.categoryId;
      _allowNominal = p.allowNominalBuy;

      for (var u in p.units) {
        _unitRows.add(_UnitInputItem(name: u.unitName, factor: u.conversionFactor, price: u.sellPrice));
      }
    } else {
      // Default satuan eceran dasar saat barang baru
      _unitRows.add(_UnitInputItem(name: '1 Pcs', factor: 1.0, price: 0));
    }
  }

  void _addUnitRow() {
    setState(() {
      _unitRows.add(_UnitInputItem(name: '', factor: 1.0, price: 0));
    });
  }

  void _removeUnitRow(int index) {
    setState(() {
      _unitRows.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unitRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajib membuat minimal 1 satuan jual!')));
      return;
    }

    setState(() => _isSaving = true);

    final unitsPayload = _unitRows.map((u) {
      final factor = double.tryParse(u.factorController.text) ?? 1.0;
      return {
        'unit_name': u.nameController.text.trim(),
        'conversion_factor': factor,
        'sell_price': double.tryParse(u.priceController.text) ?? 0.0,
        'is_base_unit': factor == 1.0,
      };
    }).toList();

    final payload = {
      'barcode': _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      'category_id': _selectedCategoryId,
      'name': _nameCtrl.text.trim(),
      'base_unit': _baseUnitCtrl.text.trim(),
      'base_buy_price': double.tryParse(_buyPriceCtrl.text) ?? 0.0,
      'base_sell_price': double.tryParse(_sellPriceCtrl.text) ?? 0.0,
      'current_stock': double.tryParse(_stockCtrl.text) ?? 0.0,
      'min_stock_alert': double.tryParse(_minStockCtrl.text) ?? 5.0,
      'allow_nominal_buy': _allowNominal,
      'units': unitsPayload,
    };

    try {
      if (widget.product == null) {
        await ApiService.createProduct(payload);
      } else {
        await ApiService.updateProduct(widget.product!.id, payload);
      }

      if (mounted) {
        await Provider.of<ProductProvider>(context, listen: false).loadData();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConstants.primaryGreen,
            content: Text(widget.product == null ? 'Produk berhasil ditambahkan!' : 'Produk berhasil diperbarui!'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<ProductProvider>(context).categories;

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Barang' : 'Edit Barang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Data Pokok Barang
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConstants.borderGrey)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Dasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.primaryGreen)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Barang *', hintText: 'Cth: Beng-Beng Coklat 25g', border: OutlineInputBorder(), isDense: true),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama barang wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _barcodeCtrl,
                            decoration: const InputDecoration(labelText: 'Barcode / SKU', hintText: 'Cth: BNG-001', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(), isDense: true),
                            value: _selectedCategoryId,
                            items: [
                              const DropdownMenuItem<int>(value: null, child: Text('Umum')),
                              ...categories.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (val) => setState(() => _selectedCategoryId = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Satuan Dasar, Modal, dan Stok
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConstants.borderGrey)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Satuan Dasar & Stok Fisik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.primaryGreen)),
                    const SizedBox(height: 6),
                    const Text('Satuan dasar adalah unit terkecil eceran (pcs, bungkus, kg, liter).', style: TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _baseUnitCtrl,
                            decoration: const InputDecoration(labelText: 'Satuan Terkecil *', hintText: 'pcs / kg', border: OutlineInputBorder(), isDense: true),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stok Masuk *', border: OutlineInputBorder(), isDense: true),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Wajib' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _buyPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Modal Dasar / HPP *', prefixText: 'Rp ', border: OutlineInputBorder(), isDense: true),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _sellPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Harga Jual Standar *', prefixText: 'Rp ', border: OutlineInputBorder(), isDense: true),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Wajib' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Izinkan Beli Nominal (Rp)?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Aktifkan untuk barang curah/timbangan (minyak curah, beras, telur).', style: TextStyle(fontSize: 10)),
                      value: _allowNominal,
                      activeColor: AppConstants.accentGreen,
                      onChanged: (val) => setState(() => _allowNominal = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Multi-Satuan (Box, Dus, Pack, Renteng)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConstants.borderGrey)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daftar Satuan Jual (UOM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.primaryGreen)),
                            Text('Contoh: 1 Box isi 20 Pcs seharga Rp 46.000', style: TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addUnitRow,
                          icon: const Icon(LucideIcons.plus, size: 14),
                          label: const Text('Satuan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._unitRows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: row.nameController,
                                decoration: const InputDecoration(labelText: 'Nama Satuan', hintText: '1 Box (20)', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: row.factorController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Isi (Faktor)', hintText: '20', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: row.priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Harga Jual', prefixText: 'Rp ', border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            if (_unitRows.length > 1)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                onPressed: () => _removeUnitRow(idx),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.product == null ? 'Simpan Barang Baru' : 'Perbarui Data Barang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}