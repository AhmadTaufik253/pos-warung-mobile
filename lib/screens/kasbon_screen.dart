import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../models/debt_model.dart';
import '../services/api_service.dart';

class KasbonScreen extends StatefulWidget {
  const KasbonScreen({super.key});

  @override
  State<KasbonScreen> createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  List<DebtModel> _debts = [];
  double _totalUnpaid = 0.0;
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, unpaid, paid

  @override
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getDebts();
      setState(() {
        _totalUnpaid = result['total_unpaid'];
        _debts = result['debts'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openPayDialog(DebtModel debt) {
    final amountController = TextEditingController(text: debt.remainingBalance.toStringAsFixed(0));
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.coins, color: AppConstants.accentGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bayar Kasbon: ${debt.customerName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sisa Hutang:', style: TextStyle(fontSize: 11, color: Colors.red)),
                      Text(
                        CurrencyFormat.toIdr(debt.remainingBalance),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Bayar (Rp)',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      amountController.text = debt.remainingBalance.toStringAsFixed(0);
                    },
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Bayar Lunas Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (Opsional)',
                    hintText: 'Cth: Titip tetangga / Cicilan ke-1',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final payAmount = double.tryParse(amountController.text) ?? 0.0;
                        if (payAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal yang valid!')));
                          return;
                        }
                        if (payAmount > debt.remainingBalance) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal melebihi sisa hutang!')));
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          await ApiService.payDebt(
                            debt.id,
                            payAmount,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetchDebts();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppConstants.primaryGreen,
                                content: Text('Pembayaran kasbon ${debt.customerName} berhasil dicatat!'),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Pembayaran'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDebts = _debts.where((d) {
      final matchSearch = d.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (d.customerPhone != null && d.customerPhone!.contains(_searchQuery)) ||
          (d.invoiceNumber != null && d.invoiceNumber!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final isPaid = d.remainingBalance <= 0;
      final matchStatus = _statusFilter == 'ALL' ||
          (_statusFilter == 'unpaid' && !isPaid) ||
          (_statusFilter == 'paid' && isPaid);

      return matchSearch && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppConstants.bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buku Kasbon & Piutang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Catatan Hutang Pelanggan', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: _fetchDebts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.accentGreen))
          : RefreshIndicator(
              color: AppConstants.primaryGreen,
              onRefresh: _fetchDebts,
              child: Column(
                children: [
                  // Kartu Ringkasan Total Piutang Belum Lunas
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
                            const Text('Total Piutang Belum Lunas', style: TextStyle(fontSize: 11, color: AppConstants.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormat.toIdr(_totalUnpaid),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(
                                '${_debts.where((d) => d.remainingBalance > 0).length} Orang',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search & Filter Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Cari nama langganan atau faktur...',
                            prefixIcon: const Icon(LucideIcons.search, size: 18),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.borderGrey)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.borderGrey)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _statusChip('Semua', 'ALL'),
                            const SizedBox(width: 6),
                            _statusChip('Belum Lunas', 'unpaid'),
                            const SizedBox(width: 6),
                            _statusChip('Lunas', 'paid'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List Kartu Kasbon
                  Expanded(
                    child: filteredDebts.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.bookOpen, size: 40, color: AppConstants.textMuted),
                                SizedBox(height: 8),
                                Text('Tidak ada catatan kasbon pada filter ini', style: TextStyle(fontSize: 12, color: AppConstants.textMuted)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredDebts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final debt = filteredDebts[idx];
                              return _buildDebtCard(debt);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDebtCard(DebtModel debt) {
    final isPaid = debt.remainingBalance <= 0;
    final dateStr = DateFormat('dd MMM yyyy').format(debt.createdAt);

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
          // Baris Atas: Nama Pelanggan & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                debt.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'LUNAS' : 'BELUM LUNAS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Baris Kedua: Nomor Faktur & Tanggal
          Row(
            children: [
              if (debt.invoiceNumber != null) ...[
                Text(debt.invoiceNumber!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppConstants.textMuted)),
                const SizedBox(width: 8),
              ],
              Text(dateStr, style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
              if (debt.customerPhone != null) ...[
                const SizedBox(width: 8),
                Text('• ${debt.customerPhone}', style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
              ],
            ],
          ),
          const Divider(height: 16),

          // Baris Bawah: Total Kasbon, Sisa Hutang, & Tombol Bayar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total: ${CurrencyFormat.toIdr(debt.originalAmount)}', style: const TextStyle(fontSize: 10, color: AppConstants.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    'Sisa: ${CurrencyFormat.toIdr(debt.remainingBalance)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? AppConstants.primaryGreen : Colors.red,
                    ),
                  ),
                ],
              ),
              if (!isPaid)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openPayDialog(debt),
                  icon: const Icon(LucideIcons.coins, size: 14),
                  label: const Text('Bayar / Cicil', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                const Text('Telah Selesai', style: TextStyle(fontSize: 11, color: Colors.green, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppConstants.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }
}