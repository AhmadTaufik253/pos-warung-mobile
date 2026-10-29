import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'receipt_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedMethod = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getOrders();
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter transaksi berdasarkan metode bayar
    final filteredOrders = _orders.where((o) {
      if (_selectedMethod == 'ALL') return true;
      return o.paymentMethod.toLowerCase() == _selectedMethod.toLowerCase();
    }).toList();

    // Kalkulasi Total Omset & Jumlah Transaksi
    final totalOmset = filteredOrders.fold(0.0, (sum, o) => sum + o.grandTotal);
    final totalInvoices = filteredOrders.length;

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Daftar Penjualan Warung', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
          : RefreshIndicator(
              color: AppConstants.primaryGreen,
              onRefresh: _fetchOrders,
              child: Column(
                children: [
                  // Kartu Ringkasan Penjualan
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.borderGrey),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Omset Terhitung', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormat.toIdr(totalOmset),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryGreen),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppConstants.lightGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.receipt, size: 14, color: AppConstants.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                '$totalInvoices Nota',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips Metode Pembayaran
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _filterChip('Semua', 'ALL'),
                        const SizedBox(width: 6),
                        _filterChip('Tunai', 'cash'),
                        const SizedBox(width: 6),
                        _filterChip('QRIS', 'qris'),
                        const SizedBox(width: 6),
                        _filterChip('Transfer', 'transfer'),
                        const SizedBox(width: 6),
                        _filterChip('Kasbon', 'debt'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Daftar Transaksi
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.inbox, size: 40, color: AppConstants.textMuted),
                                SizedBox(height: 8),
                                Text('Belum ada transaksi pada filter ini', style: TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final order = filteredOrders[idx];
                              return _buildOrderCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(order.transactionDate);
    final isDebt = order.paymentMethod.toLowerCase() == 'debt';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => ReceiptDialog(order: order),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.borderGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Nomor Faktur & Badge Metode
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDebt ? Colors.red.shade50 : AppConstants.lightGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.paymentMethod.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDebt ? Colors.red.shade700 : AppConstants.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Baris Tengah: Info Tanggal & Pelanggan
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 12, color: AppConstants.textMuted),
                const SizedBox(width: 4),
                Text(dateStr, style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                const SizedBox(width: 12),
                const Icon(LucideIcons.user, size: 12, color: AppConstants.textMuted),
                const SizedBox(width: 4),
                Text(order.customerName ?? 'Pelanggan Umum', style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
              ],
            ),
            const SizedBox(height: 8),

            // Baris Bawah: Total Item & Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} Macam Barang',
                  style: const TextStyle(fontSize: 11, color: AppConstants.textDark),
                ),
                Text(
                  CurrencyFormat.toIdr(order.grandTotal),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppConstants.primaryGreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedMethod == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppConstants.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedMethod = value),
    );
  }
}