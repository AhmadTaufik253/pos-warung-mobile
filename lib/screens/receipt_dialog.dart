import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/order_model.dart';

class ReceiptDialog extends StatelessWidget {
  final OrderModel order;
  const ReceiptDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(order.transactionDate);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Warung
              const Text(
                'WARUNG PAING',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Jl. Pasar Senen No. 45, Jakarta\nWA: 0812-3456-7890',
                style: TextStyle(fontSize: 10, color: AppConstants.textMuted),
                textAlign: TextAlign.center,
              ),
              const Divider(thickness: 1, height: 16),

              // Metadata Nota
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('No. Faktur:', style: TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                  Text(order.invoiceNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Waktu:', style: TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                  Text(dateFormatted, style: const TextStyle(fontSize: 10)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pelanggan:', style: TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                  Text(order.customerName ?? 'Umum', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(thickness: 1, height: 16),

              // Daftar Item yang Dibeli
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.unitName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(
                              '${CurrencyFormat.formatStock(item.quantity)} x ${CurrencyFormat.toIdr(item.sellingPrice)}',
                              style: const TextStyle(fontSize: 9, color: AppConstants.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(CurrencyFormat.toIdr(item.subtotal), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              const Divider(thickness: 1, height: 16),

              // Ringkasan Pembayaran
              _rowSummary('Subtotal', CurrencyFormat.toIdr(order.totalAmount)),
              if (order.discountAmount > 0)
                _rowSummary('Diskon', '- ${CurrencyFormat.toIdr(order.discountAmount)}', color: Colors.green),
              _rowSummary('TOTAL TAGIHAN', CurrencyFormat.toIdr(order.grandTotal), isBold: true),
              _rowSummary('Metode Bayar', order.paymentMethod.toUpperCase()),
              if (order.paymentMethod == 'cash') ...[
                _rowSummary('Uang Diterima', CurrencyFormat.toIdr(order.cashTendered)),
                _rowSummary('Kembalian', CurrencyFormat.toIdr(order.changeAmount), isBold: true, color: AppConstants.primaryGreen),
              ],
              if (order.paymentMethod == 'debt')
                _rowSummary('Status Bayar', 'TEMPO / KASBON', isBold: true, color: Colors.red),

              const SizedBox(height: 14),
              const Text(
                '*** TERIMA KASIH ***\nBarang yang sudah dibeli tidak dapat ditukar',
                style: TextStyle(fontSize: 9, color: AppConstants.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _rowSummary(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}