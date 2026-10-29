class ProductUnit {
  final int id;
  final String unitName;
  final double conversionFactor;
  final double sellPrice;
  final bool isBaseUnit;

  ProductUnit({
    required this.id,
    required this.unitName,
    required this.conversionFactor,
    required this.sellPrice,
    required this.isBaseUnit,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['id'],
      unitName: json['unit_name'] ?? '',
      conversionFactor: double.parse(json['conversion_factor'].toString()),
      sellPrice: double.parse(json['sell_price'].toString()),
      isBaseUnit: json['is_base_unit'] == 1 || json['is_base_unit'] == true,
    );
  }
}

class ProductModel {
  final int id;
  final String? barcode;
  final String name;
  final String baseUnit;
  final double baseBuyPrice;
  final double baseSellPrice;
  final double currentStock;
  final double minStockAlert;
  final bool allowNominalBuy;
  final int? categoryId;
  final List<ProductUnit> units;

  ProductModel({
    required this.id,
    this.barcode,
    required this.name,
    required this.baseUnit,
    required this.baseBuyPrice,
    required this.baseSellPrice,
    required this.currentStock,
    required this.minStockAlert,
    required this.allowNominalBuy,
    this.categoryId,
    required this.units,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var rawUnits = (json['units'] as List? ?? [])
        .map((u) => ProductUnit.fromJson(u))
        .toList();

    return ProductModel(
      id: json['id'],
      barcode: json['barcode'],
      name: json['name'] ?? '',
      baseUnit: json['base_unit'] ?? 'pcs',
      baseBuyPrice: double.parse((json['base_buy_price'] ?? 0).toString()),
      baseSellPrice: double.parse((json['base_sell_price'] ?? 0).toString()),
      currentStock: double.parse((json['current_stock'] ?? 0).toString()),
      minStockAlert: double.parse((json['min_stock_alert'] ?? 5).toString()),
      allowNominalBuy: json['allow_nominal_buy'] == 1 || json['allow_nominal_buy'] == true,
      categoryId: json['category_id'],
      units: rawUnits,
    );
  }
}