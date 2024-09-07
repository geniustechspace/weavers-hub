import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class CartItem {
  final QueryDocumentSnapshot product;
  int quantity;
  double price;

  CartItem({required this.product, this.quantity = 1, this.price = 0.0});
}

class Cart extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  void updateItemQuantity(QueryDocumentSnapshot product, int newQuantity) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      if (newQuantity > 0) {
        _items[existingIndex].quantity = newQuantity;
      } else {
        _items.removeAt(existingIndex);
      }
    } else if (newQuantity > 0) {
      _items.add(CartItem(product: product, quantity: newQuantity));
    }
    notifyListeners();
  }

  int getItemQuantity(QueryDocumentSnapshot product) {
    final existingItem = _items.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 1),
    );
    return existingItem.quantity;
  }

  bool removeItem(String productId) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      _items.removeAt(existingIndex);
      notifyListeners();
      return true;
    }
    return false;
  }

  void clear() {
    for (var item in _items) {
      item.quantity = 1;
    }
    _items = [];
    notifyListeners();
  }

  double getTotalAmount() {
    double total = 0.0;
    for (var cartItem in _items) {
      total += cartItem.quantity * cartItem.product['price'];
    }
    return total;
  }

  void resetProductQuantity(String productId) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = 1;
    }
  }
}
