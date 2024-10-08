import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../userScreens/Users/cart/cart.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> createOrder(Cart cart, String reference) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User document not found');

      final userData = userDoc.data() as Map<String, dynamic>;
      final productsBought = _mapCartItems(cart);

      const double deliveryCharge = 10.0;
      final double amountToPay = cart.getTotalAmount() + deliveryCharge;

      final orderData = _buildOrderData(
        productsBought: productsBought,
        userData: userData,
        amountToPay: amountToPay,
        deliveryCharge: deliveryCharge,
        itemCount: cart.items.length,
        userId: user.uid,
      );

      final orderRef = _firestore.collection('orders').doc(reference);
      await orderRef.set(orderData);

      for (var product in productsBought) {
        await orderRef
            .collection('sellerOrders')
            .doc(reference)
            .set({...orderData, 'userId': product['userId']});
      }

      await _sendNotifications(
        productsBought: productsBought,
        userName: userData['name'],
      );
    } catch (e) {
      print("Error creating order: $e");
      rethrow;
    }
  }

  List<Map<String, dynamic>> _mapCartItems(Cart cart) {
    return cart.items.map((CartItem item) {
      return {
        'userId': item.product['userId'],
        'name': item.product['name'],
        'price': item.product['price'],
        'image_url': item.product['image_url'],
        'quantity': item.quantity,
      };
    }).toList();
  }

  Map<String, dynamic> _buildOrderData({
    required List<Map<String, dynamic>> productsBought,
    required Map<String, dynamic> userData,
    required double amountToPay,
    required double deliveryCharge,
    required int itemCount,
    required String userId,
  }) {
    return {
      'products': productsBought,
      'totalAmount': amountToPay,
      'userName': userData['name'],
      'email': userData['email'],
      'phone': userData['phone'],
      'location': userData['location'],
      'deliveryCharge': deliveryCharge,
      'itemsCount': itemCount,
      'orderDate': FieldValue.serverTimestamp(),
      'status': true,
      'acceptOrder': false,
      'userId': userId,
      'isDelivered': false,
    };
  }

  Future<void> _sendNotifications({
    required List<Map<String, dynamic>> productsBought,
    required String userName,
  }) async {
    for (var product in productsBought) {
      await _notificationService.sendNotification(
        receiverUserId: product['userId'],
        title: 'New Order Received from $userName',
        body: 'You have a new order for ${product['name']}',
      );
    }
  }
}
