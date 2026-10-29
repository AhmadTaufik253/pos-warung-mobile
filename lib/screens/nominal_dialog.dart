import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class NominalDialog extends StatefulWidget {
  final ProductModel product;
  const NominalDialog({super.key, required this.product});

  @override
  State<NominalDialog> createState() => _NominalDialogState();
}

class _NominalDialogState extends State<NominalDialog> {
  final _nominalController = TextEditingController(text: '5000');
  double _calculatedQty = 0.0;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final money = double.tryParse(_nominalController.text) ?? 0.0;
    final price = widget.product.baseSellPrice;
    setState(() {
      _calculatedQty = price > 0 ? (money / price) : 0.0;
    });
  }

  void _setPreset(double val) {
    _nominalController.text = val.toStringAsFixed(0);
    _recalculate();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Beli Sesuai Uang (Rp)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(widget.product.name, style: const TextStyle(fontSize: 12, color: AppConstants.textMuted)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilihan Cepat:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [2000, 3000, 5000, 10000, 15000, 20000].map((nominal) {
                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _setPreset(nominal.toDouble()),
                  child: Text(CurrencyFormat.toIdr(nominal), style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) => _recalculate(),
              decoration: const InputDecoration(
                labelText: 'Nominal Uang Belanja',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dapat Takaran:', style: TextStyle(fontSize: 12)),
                  Text(
                    '${_calculatedQty.toStringAsFixed(3)} ${widget.product.baseUnit}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final money = double.tryParse(_nominalController.text) ?? 0.0;
            if (money <= 0) return;
            try {
              Provider.of<CartProvider>(context, listen: false).addNominal(widget.product, money, _calculatedQty);
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text('Tambah ke Keranjang'),
        ),
      ],
    );
  }
}