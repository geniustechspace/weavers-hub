import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getOrdersByProductUserId(
    String userId) async {
  // Reference the 'orders' collection in Firestore
  CollectionReference orders = FirebaseFirestore.instance.collection('orders');

  // Get all orders from Firestore
  QuerySnapshot snapshot = await orders.get();

  // List to store matching orders
  List<Map<String, dynamic>> matchingOrders = [];

  // Loop through each order document
  for (var doc in snapshot.docs) {
    // Get the products array from the order
    List<dynamic> products = doc['products'];

    // Filter products by userId
    var filteredProducts = products.where((product) {
      return product['userId'] == userId;
    }).toList();

    // If any product matches the userId, add the order to the list
    if (filteredProducts.isNotEmpty) {
      matchingOrders.add({
        'orderId': doc.id,
        'filteredProducts': filteredProducts,
        'orderData': doc.data(), // Include the rest of the order data
      });
    }
  }

  return matchingOrders;
}
