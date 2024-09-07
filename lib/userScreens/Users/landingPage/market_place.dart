import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:weavershub/userScreens/Users/landingPage/product_details.dart';

import '../cart/cart.dart';
import '../cart/cart_screen.dart';


class MarketPlace extends StatelessWidget {
  const MarketPlace({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        title: const Text('Market Place', style: TextStyle(color: Colors.white),),
        actions: [
          Consumer<Cart>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, size: 35, color: Colors.white,),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green[50]!, Colors.green[100]!],
            ),
          ),
          child: const AllProductsGrid()),
    );
  }
}

class AllProductsGrid extends StatelessWidget {
  const AllProductsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products available.'));
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
                  ),
                );
              },
              child: ProductCard(product: product),
            );
          },
        );
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final QueryDocumentSnapshot product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<Cart>(context, listen: false);
    _quantity = cart.getItemQuantity(widget.product);
  }

  void _addToCart() {
    final cart = Provider.of<Cart>(context, listen: false);
    cart.updateItemQuantity(widget.product, _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.product['name']} updated in cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Hero(
                tag: 'product-${widget.product.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.product['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'GHC ${widget.product['price']}',
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () => _showQuantityDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('Buy', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Update Quantity',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      color: Colors.red,
                      onPressed: () {
                        if (_quantity > 0) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.green,
                      onPressed: () {
                        if (_quantity < widget.product['quantity']) {
                          setState(() => _quantity++);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },


            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                iconColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:  (){
                Navigator.of(context).pop();
                _addToCart();
              },
              child: const Text("Add to Cart"),
            ),
          ],
        );
      },
    );
  }




}