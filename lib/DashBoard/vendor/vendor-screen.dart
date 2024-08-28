import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weavershub/DashBoard/vendor/product-creation.dart';
import 'package:weavershub/DashBoard/vendor/vendor-orders-page.dart';
import 'package:weavershub/DashBoard/vendor/vendorProductsPage.dart';
import 'package:weavershub/DashBoard/vendor/view-accepted-orders.dart';

class VendorDashboard extends StatelessWidget {
  const VendorDashboard({super.key});

  Future<Map<String, int>> fetchVendorStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'productsCreated': 0, 'ordersReceived': 0};
    }

    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: user.uid)
        .get();

    final ordersSnapshot = await FirebaseFirestore.instance
        .collectionGroup('sellerOrders')
        .where('userId', isEqualTo: user.uid)
        .get();

    return {
      'productsCreated': productsSnapshot.docs.length,
      'ordersReceived': ordersSnapshot.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade300, Colors.green.shade800],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<Map<String, int>>(
              future: fetchVendorStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                final stats = snapshot.data!;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader('Vendor Dashboard'),
                          const SizedBox(height: 20),
                          _buildStatCards(stats),
                          const SizedBox(height: 30),
                          _buildSectionTitle("Products"),
                          const SizedBox(height: 10),
                          _buildActionButton('Create a new product', Icons.add, () {
                            Get.to(() => const VendorProductCreation());
                          }),
                          const SizedBox(height: 16),
                          _buildActionButton('View all products', Icons.visibility, () {
                            Get.to(() => const UserProductsPage());
                          }),
                          const SizedBox(height: 30),
                          _buildSectionTitle("Orders"),
                          const SizedBox(height: 10),
                          _buildActionButton('View all orders', Icons.shopping_cart, () {
                            Get.to(() => const VendorOrdersPage());
                          }),
                          const SizedBox(height: 16),
                          _buildActionButton('Attended orders', Icons.check_circle, () {
                            Get.to(() => const VendorAcceptedOrdersPage());
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child:  Center(
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Products Created', '${stats['productsCreated']}', Icons.inventory)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Orders Received', '${stats['ordersReceived']}', Icons.shopping_bag)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.green,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}