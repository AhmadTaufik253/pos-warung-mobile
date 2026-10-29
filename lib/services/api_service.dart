import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/debt_model.dart';

class ApiService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // 1. Kategori
  static Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/categories'), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat kategori dari server');
  }

  // 2. Produk
  static Future<List<ProductModel>> getProducts({String? search, int? categoryId}) async {
    String url = '${AppConstants.baseUrl}/products?';
    if (search != null && search.isNotEmpty) url += 'search=$search&';
    if (categoryId != null) url += 'category_id=$categoryId&';

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => ProductModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat produk dari server');
  }

  // 3. Checkout Kasir
  static Future<OrderModel> checkout(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/orders/checkout'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    final json = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return OrderModel.fromJson(json['data']);
    }
    throw Exception(json['message'] ?? 'Gagal memproses checkout kasir');
  }

  // 4. Tahan Antrean (Hold Cart)
  static Future<void> holdCart(String label, List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/orders/hold'),
      headers: _headers,
      body: jsonEncode({
        'hold_label': label,
        'items': items,
      }),
    );
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal menahan antrean');
    }
  }

  // 5. Daftar Antrean Ditahan
  static Future<List<dynamic>> getHoldList() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/orders/hold/list'), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    }
    throw Exception('Gagal memuat antrean kasir');
  }

  // 6. Hapus Antrean Ditahan
  static Future<void> deleteHold(int orderId) async {
    await http.delete(Uri.parse('${AppConstants.baseUrl}/orders/hold/$orderId'), headers: _headers);
  }

  // 7. Ambil Daftar Riwayat Transaksi (Orders)
  static Future<List<OrderModel>> getOrders() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/orders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data']['data']; // Laravel paginate membungkus di data.data
      return data.map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat riwayat transaksi dari server');
  }

  // 8. Ambil Daftar Kasbon & Total Piutang
  static Future<Map<String, dynamic>> getDebts() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/debts'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      final List<DebtModel> debts = data.map((e) => DebtModel.fromJson(e)).toList();

      return {
        'total_unpaid': double.parse((json['total_unpaid'] ?? 0).toString()),
        'debts': debts,
      };
    }
    throw Exception('Gagal memuat catatan kasbon dari server');
  }

  // 9. Bayar Cicilan / Pelunasan Kasbon
  static Future<void> payDebt(int debtId, double amount, {String method = 'cash', String? notes}) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/debts/$debtId/pay'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'payment_method': method,
        'notes': notes ?? 'Cicilan kasbon via mobile',
      }),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal memproses pembayaran kasbon');
    }
  }

  // Simpan Produk Baru
  static Future<void> createProduct(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/products'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal menambahkan produk');
    }
  }

  // Update Data Produk
  static Future<void> updateProduct(int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/products/$id'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal memperbarui produk');
    }
  }

  // Hapus Produk
  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/products/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal menghapus produk');
    }
  }

  // Restock Kilat
  static Future<void> quickRestock(int id, double addedStock) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/products/$id/stock'),
      headers: _headers,
      body: jsonEncode({'added_stock': addedStock}),
    );
    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Gagal menambah stok');
    }
  }
}