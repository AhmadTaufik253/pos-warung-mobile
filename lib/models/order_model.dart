class OrderItemModel {
  final int id;
  final String unitName;
  final double quantity;
  final double sellingPrice;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.unitName,
    required this.quantity,
    required this.sellingPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      unitName: json['unit_name'] ?? '',
      quantity: double.parse(json['quantity'].toString()),
      sellingPrice: double.parse(json['selling_price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class OrderModel {
  final int id;
  final String invoiceNumber;
  final String? customerName;
  final double totalAmount;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod;
  final double cashTendered;
  final double changeAmount;
  final String status;
  final DateTime transactionDate;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.invoiceNumber,
    this.customerName,
    required this.totalAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.cashTendered,
    required this.changeAmount,
    required this.status,
    required this.transactionDate,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = (json['items'] as List? ?? [])
        .map((it) => OrderItemModel.fromJson(it))
        .toList();

    return OrderModel(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      customerName: json['customer'] != null ? json['customer']['name'] : null,
      totalAmount: double.parse((json['total_amount'] ?? 0).toString()),
      discountAmount: double.parse((json['discount_amount'] ?? 0).toString()),
      grandTotal: double.parse((json['grand_total'] ?? 0).toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      cashTendered: double.parse((json['cash_tendered'] ?? 0).toString()),
      changeAmount: double.parse((json['change_amount'] ?? 0).toString()),
      status: json['status'] ?? 'completed',
      transactionDate: DateTime.parse(json['transaction_date']),
      items: rawItems,
    );
  }
}