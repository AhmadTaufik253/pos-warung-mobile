class DebtPaymentModel {
  final int id;
  final double paymentAmount;
  final String paymentMethod;
  final String? notes;
  final DateTime paidAt;

  DebtPaymentModel({
    required this.id,
    required this.paymentAmount,
    required this.paymentMethod,
    this.notes,
    required this.paidAt,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'],
      paymentAmount: double.parse(json['payment_amount'].toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      notes: json['notes'],
      paidAt: DateTime.parse(json['paid_at']),
    );
  }
}

class DebtModel {
  final int id;
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final String? invoiceNumber;
  final double originalAmount;
  final double remainingBalance;
  final String status;
  final DateTime createdAt;
  final List<DebtPaymentModel> payments;

  DebtModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.invoiceNumber,
    required this.originalAmount,
    required this.remainingBalance,
    required this.status,
    required this.createdAt,
    required this.payments,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    var rawPayments = (json['payments'] as List? ?? [])
        .map((p) => DebtPaymentModel.fromJson(p))
        .toList();

    return DebtModel(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer'] != null ? json['customer']['name'] : 'Pelanggan',
      customerPhone: json['customer'] != null ? json['customer']['phone'] : null,
      invoiceNumber: json['order'] != null ? json['order']['invoice_number'] : null,
      originalAmount: double.parse((json['original_amount'] ?? 0).toString()),
      remainingBalance: double.parse((json['remaining_balance'] ?? 0).toString()),
      status: json['status'] ?? 'unpaid',
      createdAt: DateTime.parse(json['created_at']),
      payments: rawPayments,
    );
  }
}