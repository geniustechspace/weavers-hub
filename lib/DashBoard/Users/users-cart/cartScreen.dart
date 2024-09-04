import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../services/cart-summery.dart';
import '../../../services/notification_service.dart';
import '../../../services/order-services.dart';
import '../../../services/order-summery-dialog.dart';
import '../../../services/payment-service.dart';
import '../landing-page/landing-page.dart';
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
      builder: (BuildContext context) => OrderSummaryDialog(
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

  // void _handleSuccessfulPayment(BuildContext context, Cart cart, String reference) async {
  //   final notificationService = NotificationService();
  //   try {
  //     await OrderService().createOrder(cart, reference);
  //     cart.clear();
  //     final CartItem item;
  //
  //
  //     // await notificationService.sendNotification(
  //     //   receiverUserId: item.product['userId'],
  //     //   title: 'New Message from your admin',
  //     //   body: 'your account has been approved',
  //     // );
  //     // Send notifications to all sellers
  //     for (var item in cart.items) {
  //       print(item.product['userId']);
  //       if (item.product['userId'] != null) {
  //         await notificationService.sendNotification(
  //           receiverUserId: item.product['userId'],
  //           title: 'New Order Received',
  //           body: 'You have a new order for ${item.product['name']}',
  //         );
  //       }else{
  //         print("userId is null");
  //       }
  //     }
  //
  //     print(item.product['userId']);
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Order placed successfully!')),
  //     );
  //     Get.to(const NavigationHome());
  //
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error placing order: $e')),
  //     );
  //   }
  // }

  void _handleSuccessfulPayment(BuildContext context, Cart cart, String reference) async {
    final notificationService = NotificationService();
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

CartSummary _calculateCartSummary(Cart cart) {
  int itemCount = cart.items.length;
  double totalAmount = cart.items.fold(0, (sum, item) => sum + item.product['price'] * item.quantity);
  return CartSummary(itemCount: itemCount, totalAmount: totalAmount);
}