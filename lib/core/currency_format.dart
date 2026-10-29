import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String toIdr(dynamic val) {
    if (val == null) return 'Rp 0';
    double number = double.tryParse(val.toString()) ?? 0.0;
    return _idr.format(number);
  }

  static String formatStock(dynamic val) {
    if (val == null) return '0';
    double number = double.tryParse(val.toString()) ?? 0.0;
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    return number.toStringAsFixed(3).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
  }
}