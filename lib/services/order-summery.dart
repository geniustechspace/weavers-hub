import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../DashBoard/Users/users-cart/cart.dart';

class OrderSummaryItem extends StatelessWidget {
  final CartItem item;

  const OrderSummaryItem({super.key, required this.item});

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