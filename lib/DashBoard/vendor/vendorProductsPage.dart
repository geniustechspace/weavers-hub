import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProductsPage extends StatelessWidget {
  const UserProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors Products'),
      ),
      body: const UserProductsList(),
    );
  }
}

class UserProductsList extends StatelessWidget {
  const UserProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your products.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You haven\'t created any products yet.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot product;

  ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: product['image_url'] != null
            ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.image_not_supported),
        title: Text(product['name']),
        subtitle: Text('Price: \$${product['price']}'),
        trailing: Text('Quantity: ${product['quantity']}'),
        onTap: () {

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Image.network(product['image_url']),
              content: Column(
                children: [
                  Text(product['name']),
                  Text(product['description']),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}