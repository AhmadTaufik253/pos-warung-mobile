import 'product_model.dart';

class CartItemModel {
  final String cartKey;
  final ProductModel product;
  final int? productUnitId;
  final String unitName;
  final double conversionFactor;
  final double price;
  double qty;
  final bool isNominal;

  CartItemModel({
    required this.cartKey,
    required this.product,
    this.productUnitId,
    required this.unitName,
    required this.conversionFactor,
    required this.price,
    required this.qty,
    this.isNominal = false,
  });

  double get subtotal => price * qty;

  Map<String, dynamic> toApiJson() {
    return {
      'product_id': product.id,
      'product_unit_id': productUnitId,
      'unit_name': unitName,
      'quantity': qty,
      'conversion_factor': conversionFactor,
      'selling_price': price,
      'subtotal': subtotal,
    };
  }
}