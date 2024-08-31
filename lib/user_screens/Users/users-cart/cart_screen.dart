import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../landing_page/landing_page.dart';
import 'cart.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your Cart', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
        ),
        child: Consumer<Cart>(
          builder: (context, cart, _) => cart.items.isEmpty
              ? const _EmptyCartView()
              : _CartContent(cart: cart),
        ),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Your cart is empty!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  final Cart cart;

  const _CartContent({required this.cart});

  @override
  Widget build(BuildContext context) {
    final cartSummary = _calculateCartSummary(cart);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.items.length,
            itemBuilder: (context, index) => _CartItemCard(
              item: cart.items[index],
              onRemove: () => cart.removeItem(cart.items[index].product.id),
            ),
          ),
        ),
        _CartSummary(
          cartSummary: cartSummary,
          onCheckout: () => _showOrderSummary(context, cart, cartSummary),
        ),
      ],
    );
  }

  void _showOrderSummary(BuildContext context, Cart cart, CartSummary cartSummary) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _OrderSummaryDialog(
        cart: cart,
        cartSummary: cartSummary,
        onConfirm: () => _processPayment(context, cart, cartSummary.amountToPay),
      ),
    );
  }

  void _processPayment(BuildContext context, Cart cart, double amount) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      PaymentService().makePayment(
        context: context,
        email: user.email!,
        amount: amount,
        onSuccess: (String reference) => _handleSuccessfulPayment(context, cart, reference),
        onFailure: () => _handleFailedPayment(context),
      );
    }
  }

  void _handleSuccessfulPayment(BuildContext context, Cart cart, String reference) async {
    try {
      await OrderService().createOrder(cart, reference);
      cart.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      Get.to(const NavigationHome());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error placing order: $e')),
      );
    }
  }

  void _handleFailedPayment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment verification failed")),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
              imageUrl:  item.product['image_url'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error)),

        ),
        title: Text(item.product['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('Price: GHC ${item.product['price']}', style: const TextStyle(color: Colors.deepPurple)),
            const SizedBox(height: 5),
            Text('Quantity: ${item.quantity}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartSummary cartSummary;
  final VoidCallback onCheckout;

  const _CartSummary({required this.cartSummary, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
        ),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Total Items: ${cartSummary.itemCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Amount: GHC ${cartSummary.totalAmount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('Delivery Charge: GHC ${CartSummary.deliveryCharge}', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Text('Total: GHC ${cartSummary.amountToPay}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Checkout', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryDialog extends StatelessWidget {
  final Cart cart;
  final CartSummary cartSummary;
  final VoidCallback onConfirm;

  const _OrderSummaryDialog({required this.cart, required this.cartSummary, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Order Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected Products:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...cart.items.map((item) => _OrderSummaryItem(item: item)),
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),
            Text('Subtotal: GHC ${cartSummary.totalAmount}', style: const TextStyle(fontSize: 16)),
            const Text('Delivery Charge: GHC ${CartSummary.deliveryCharge}', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Total Amount: GHC ${cartSummary.amountToPay}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 20),
            const Text('Delivery Information:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Your order will be delivered within 24-48 hours.'),
            const SizedBox(height: 10),
            const Text('Payment Information:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('You can pay using various methods on Paystack: credit/debit cards, mobile money.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.of(context).pop(),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Confirm Order', style: TextStyle(color: Colors.white)),
          onPressed: () {
            // Navigator.of(context).pop();
            onConfirm();

          },
        ),
      ],
    );
  }
}

class _OrderSummaryItem extends StatelessWidget {
  final CartItem item;

  const _OrderSummaryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
                imageUrl: item.product['image_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Quantity: ${item.quantity}'),
                Text('Price: GHC ${item.product['price'] * item.quantity}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartSummary {
  final int itemCount;
  final double totalAmount;
  final double amountToPay;
  static const double deliveryCharge = 10.0;

  CartSummary({required this.itemCount, required this.totalAmount})
      : amountToPay = totalAmount + deliveryCharge;
}

CartSummary _calculateCartSummary(Cart cart) {
  int itemCount = cart.items.length;
  double totalAmount = cart.items.fold(0, (sum, item) => sum + item.product['price'] * item.quantity);
  return CartSummary(itemCount: itemCount, totalAmount: totalAmount);
}

class PaymentService {
  void makePayment({
    required BuildContext context,
    required String email,
    required double amount,
    required Function(String) onSuccess,
    required VoidCallback onFailure,
  }) async {
    final uniqueTransRef = PayWithPayStack().generateUuidV4();
    await FirebaseFirestore.instance.collection('orders').doc(uniqueTransRef).set({
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });

    PayWithPayStack().now(
      context: context,
      secretKey: "sk_test_fc20a32819750f37fbf5177e193a76455bdecca2",
      customerEmail: email,
      reference: uniqueTransRef,
      callbackUrl: "https://amp.amalitech-dev.net/",
      currency: "GHS",
      paymentChannel: ["mobile_money", "card"],
      amount: amount,
      transactionCompleted: () async {
        bool isVerified = await _verifyPaymentOnServer(uniqueTransRef);
        if (isVerified) {
          onSuccess(uniqueTransRef);
        } else {
          onFailure();
        }
      },
      transactionNotCompleted: onFailure,
    );
  }

  Future<bool> _verifyPaymentOnServer(String reference) async {
    final response = await http.get(
      Uri.parse("https://api.paystack.co/transaction/verify/$reference"),
      headers: {
        'Authorization': 'Bearer sk_test_fc20a32819750f37fbf5177e193a76455bdecca2',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] != null && data['data']['status'] == 'success';
    }
    return false;
  }
}

class OrderService {
  Future<void> createOrder(Cart cart, String reference) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Fetch user details from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw Exception('User document not found');

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> productsBought = cart.items.map((
          CartItem item) =>
      {
        'userId': item.product['userId'],
        'name': item.product['name'],
        'price': item.product['price'],
        'image_url': item.product['image_url'],
        'quantity': item.quantity,
      }).toList();

      double totalAmount = cart.getTotalAmount();
      const double deliveryCharge = 10.0;
      double amountToPay = totalAmount + deliveryCharge;

      Map<String, dynamic> orderData = {
        'products': productsBought,
        'totalAmount': amountToPay,
        'userName': userData['name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'location': userData['location'],
        'deliveryCharge': deliveryCharge,
        'itemsCount': cart.items.length,
        'orderDate': FieldValue.serverTimestamp(),
        'status': true,
        'acceptOrder': false,
        'userId': user.uid,
      };

      DocumentReference orderRef = FirebaseFirestore.instance.collection(
          'orders').doc(reference);
      await orderRef.set(orderData);

      // Create individual order items for each seller
      for (var product in productsBought) {
        // print("Creating seller order for userId: ${product['userId']}");
        await orderRef.collection('sellerOrders').doc(reference).set({
          'products': productsBought,
          'userId': product['userId'],
          'userName': userData['name'],
          'email': userData['email'],
          'orderDate': FieldValue.serverTimestamp(),
          'phone': userData['phone'],
          'location': userData['location'],
          'totalAmount': amountToPay,
          'productName': product['name'],
          'quantity': product['quantity'],
          'deliveryCharge': deliveryCharge,
          'status': true,
          'acceptOrder': false,
        });
      }
    } catch (e) {
      print("Error creating order: $e");
      throw e;
    }
  }
}
