import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  int? _selectedCategoryId;
  String _searchQuery = '';

  List<ProductModel> get products {
    return _products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(_searchQuery));
      final matchCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchSearch && matchCat;
    }).toList();
  }

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  int? get selectedCategoryId => _selectedCategoryId;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cats = await ApiService.getCategories();
      final prods = await ApiService.getProducts();
      _categories = cats;
      _products = prods;
    } catch (e) {
      debugPrint('Error ProductProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterCategory(int? catId) {
    _selectedCategoryId = catId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}