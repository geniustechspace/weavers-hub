import 'package:flutter/material.dart';


import '../userScreens/Users/cart/cart.dart';
import 'cart_summery.dart';
import 'order_summery.dart';

class OrderSummaryDialog extends StatelessWidget {
  final Cart cart;
  final CartSummary cartSummary;
  final VoidCallback onConfirm;

  const OrderSummaryDialog({super.key, required this.cart, required this.cartSummary, required this.onConfirm});

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
            ...cart.items.map((item) => OrderSummaryItem(item: item)),
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