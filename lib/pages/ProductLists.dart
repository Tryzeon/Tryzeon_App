import 'package:flutter/material.dart';

class ProductLists extends ChangeNotifier {
  final List<Map<String, dynamic>> _products = [];

  List<Map<String, dynamic>> get products => _products;

  void addProduct(Map<String, dynamic> product) {
    _products.add(product);
    notifyListeners();
  }

  void removeProduct(int index) {
    _products.removeAt(index);
    notifyListeners();
  }


  void clearAll() {
    _products.clear();
    notifyListeners();
  }
}