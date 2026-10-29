import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};
  double _discount = 0.0;

  Map<String, CartItemModel> get items => _items;
  double get discount => _discount;

  int get totalItemCount => _items.values.fold(0, (sum, i) => sum + i.qty.toInt());
  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);
  double get grandTotal => (subtotal - _discount) < 0 ? 0 : (subtotal - _discount);

  void setDiscount(double val) {
    _discount = val;
    notifyListeners();
  }

  // Tambah varian satuan reguler (Sak, 1 Kg, 1/2 Kg, Dus, Bks)
  void addProduct(ProductModel product, ProductUnit unit) {
    final key = '${product.id}-${unit.id}';

    double currentDeduction = _items.values
        .where((c) => c.product.id == product.id)
        .fold(0.0, (sum, c) => sum + (c.conversionFactor * c.qty));

    if (currentDeduction + unit.conversionFactor > product.currentStock) {
      throw Exception('Stok fisik ${product.name} tidak mencukupi!');
    }

    if (_items.containsKey(key)) {
      _items[key]!.qty += 1;
    } else {
      _items[key] = CartItemModel(
        cartKey: key,
        product: product,
        productUnitId: unit.id,
        unitName: unit.unitName,
        conversionFactor: unit.conversionFactor,
        price: unit.sellPrice,
        qty: 1,
      );
    }
    notifyListeners();
  }

  // Tambah beli nominal (Rp 5.000 dll)
  void addNominal(ProductModel product, double nominalAmount, double qtyEquivalent) {
    double currentDeduction = _items.values
        .where((c) => c.product.id == product.id)
        .fold(0.0, (sum, c) => sum + (c.conversionFactor * c.qty));

    if (currentDeduction + qtyEquivalent > product.currentStock) {
      throw Exception('Stok fisik ${product.name} tidak mencukupi untuk takaran ini!');
    }

    final key = '${product.id}-nominal-${DateTime.now().millisecondsSinceEpoch}';

    _items[key] = CartItemModel(
      cartKey: key,
      product: product,
      productUnitId: null,
      unitName: 'Nominal Rp ${nominalAmount.toStringAsFixed(0)} (~${qtyEquivalent.toStringAsFixed(3)} ${product.baseUnit})',
      conversionFactor: 1.0,
      price: nominalAmount,
      qty: 1,
      isNominal: true,
    );
    notifyListeners();
  }

  void updateQuantity(String cartKey, double delta) {
    if (!_items.containsKey(cartKey)) return;
    final item = _items[cartKey]!;

    if (delta > 0) {
      double currentDeduction = _items.values
          .where((c) => c.product.id == item.product.id)
          .fold(0.0, (sum, c) => sum + (c.conversionFactor * c.qty));

      if (currentDeduction + item.conversionFactor > item.product.currentStock) {
        throw Exception('Mencapai batas stok fisik!');
      }
      item.qty += delta;
    } else {
      item.qty += delta;
      if (item.qty <= 0) {
        _items.remove(cartKey);
      }
    }
    notifyListeners();
  }

  void removeItem(String cartKey) {
    _items.remove(cartKey);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discount = 0.0;
    notifyListeners();
  }
}