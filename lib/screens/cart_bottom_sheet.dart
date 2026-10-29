import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'checkout_dialog.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shoppingCart, size: 20, color: AppConstants.primaryGreen),
                  const SizedBox(width: 8),
                  Text('Keranjang (${cart.totalItemCount} Item)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  // Tahan Antrean
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppConstants.amberWarning),
                    icon: const Icon(LucideIcons.pauseCircle, size: 16),
                    label: const Text('Tahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: cart.items.isEmpty ? null : () => _holdCart(context, cart),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                    onPressed: cart.items.isEmpty ? null : () => cart.clear(),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            ],
          ),
          const Divider(),

          // Daftar Item Keranjang
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView(
                    children: cart.items.values.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppConstants.borderGrey),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('${item.unitName} @ ${CurrencyFormat.toIdr(item.price)}', style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(CurrencyFormat.toIdr(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.primaryGreen)),
                                ],
                              ),
                            ),
                            if (!item.isNominal) ...[
                              IconButton(
                                icon: const Icon(LucideIcons.minusCircle, size: 18),
                                onPressed: () => cart.updateQuantity(item.cartKey, -1),
                              ),
                              Text('${item.qty.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              IconButton(
                                icon: const Icon(LucideIcons.plusCircle, size: 18),
                                onPressed: () {
                                  try {
                                    cart.updateQuantity(item.cartKey, 1);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                },
                              ),
                            ] else
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                onPressed: () => cart.removeItem(item.cartKey),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Total & Checkout CTA
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bersih:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(CurrencyFormat.toIdr(cart.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConstants.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: cart.items.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context); // Tutup bottom sheet
                      showDialog(context: context, builder: (_) => const CheckoutDialog());
                    },
              child: const Text('Lanjutkan ke Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
    );
  }

  void _holdCart(BuildContext context, CartProvider cart) {
    final labelCtrl = TextEditingController(text: 'Antrean #${DateTime.now().minute}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tahan Belanjaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: labelCtrl,
          decoration: const InputDecoration(labelText: 'Nama/Keterangan Antrean', isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.amberWarning, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await ApiService.holdCart(
                  labelCtrl.text.trim(),
                  cart.items.values.map((i) => i.toApiJson()).toList(),
                );
                cart.clear();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Simpan Antrean'),
          ),
        ],
      ),
    );
  }
}