import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _payMethod = 'cash';
  final _customerController = TextEditingController();
  final _cashController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    _cashController.text = cart.grandTotal.toStringAsFixed(0);
  }

  Future<void> _submit(CartProvider cart) async {
    final grandTotal = cart.grandTotal;
    final cashGiven = double.tryParse(_cashController.text) ?? grandTotal;

    if (_payMethod == 'cash' && cashGiven < grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang tunai pembayaran kurang!')));
      return;
    }
    if (_payMethod == 'debt' && _customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama pelanggan wajib diisi untuk Kasbon!')));
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'payment_method': _payMethod,
      'discount_amount': cart.discount,
      'cash_tendered': _payMethod == 'cash' ? cashGiven : grandTotal,
      'customer_name': _payMethod == 'debt' ? _customerController.text.trim() : null,
      'items': cart.items.values.map((i) => i.toApiJson()).toList(),
    };

    try {
      final OrderModel order = await ApiService.checkout(payload);
      cart.clear();
      if (!mounted) return;

      // Refresh stok di katalog
      Provider.of<ProductProvider>(context, listen: false).loadData();

      Navigator.pop(context); // Tutup dialog checkout
      _showSuccessDialog(order);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showSuccessDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: AppConstants.accentGreen),
            SizedBox(width: 8),
            Text('Transaksi Berhasil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No Faktur: ${order.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Total: ${CurrencyFormat.toIdr(order.grandTotal)}'),
            if (order.paymentMethod == 'cash') ...[
              Text('Diterima: ${CurrencyFormat.toIdr(order.cashTendered)}'),
              Text('Kembalian: ${CurrencyFormat.toIdr(order.changeAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryGreen)),
            ],
            if (order.paymentMethod == 'debt')
              Text('Pelanggan: ${order.customerName ?? "-"} (Tercatat di Kasbon)', style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pembayaran Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppConstants.lightGreen, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Tagihan:', style: TextStyle(fontSize: 12)),
                  Text(CurrencyFormat.toIdr(cart.grandTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryGreen)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Metode Pembayaran:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _choiceChip('Tunai', 'cash'),
                _choiceChip('QRIS', 'qris'),
                _choiceChip('Transfer', 'transfer'),
                _choiceChip('Kasbon', 'debt'),
              ],
            ),
            const SizedBox(height: 12),
            if (_payMethod == 'cash') ...[
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Uang Diterima Kasir (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            if (_payMethod == 'debt') ...[
              TextField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan (Wajib)',
                  hintText: 'Cth: Ibu Hj. Maryam RT 03',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryGreen, foregroundColor: Colors.white),
          onPressed: _isSubmitting ? null : () => _submit(cart),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Proses Bayar'),
        ),
      ],
    );
  }

  Widget _choiceChip(String label, String value) {
    final isSelected = _payMethod == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppConstants.primaryGreen,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (_) => setState(() => _payMethod = value),
    );
  }
}