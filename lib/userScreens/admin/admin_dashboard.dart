import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../DashBoard/admin/accept_vendors.dart';

class AdminDashBoard extends StatefulWidget {
  const AdminDashBoard({super.key});

  @override
  State<AdminDashBoard> createState() => _AdminDashBoardState();
}

class _AdminDashBoardState extends State<AdminDashBoard> {
  late Future<QuerySnapshot> _vendorList;
  User? currentUser;
  late Future<int> _vendorCount;
  late Future<int> _vendorIncomingVendorsCount;
  late Future<String> _adminName;

  @override
  void initState() {
    super.initState();
    _vendorList = _fetchVendors();
    _vendorCount = _fetchVendorCount();
    _vendorIncomingVendorsCount = _fetchIncomingVendorCount();
    _adminName = _getAdminName();
  }

  Future<QuerySnapshot> _fetchVendors() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .where('isVendor', isEqualTo: true)
        .where('isVendorApproved', isEqualTo: true)
        .get();
  }

  Future<String> _getAdminName() async {
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        return userDoc['name'];
      }
    }
    return 'Admin';
  }

  Future<int> _fetchVendorCount() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isVendor', isEqualTo: true)
        .where('isVendorApproved', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _fetchIncomingVendorCount() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isVendor', isEqualTo: true)
        .where('isVendorApproved', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<String>(
          future: _adminName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            return Text(
              "Welcome, ${snapshot.data}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            );
          },
        ),
        backgroundColor: const Color(0xFF37B943),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.green[100]!],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVendorCountCard(),
                _buildIncomingVendorCountCard(),
              ],
            ),

            // const SizedBox(height: 20),
            Expanded(child: _buildVendorList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(const AcceptVendors()),
        label: const Text("Accept Vendors", style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.person_add, color: Colors.white,),
        backgroundColor: const Color(0xFF37B943),
      ),
    );
  }

  Widget _buildVendorCountCard() {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: FutureBuilder<int>(
          future: _vendorCount,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No vendor data found.'));
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registered Vendors: ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${snapshot.data}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIncomingVendorCountCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: FutureBuilder<int>(
          future: _vendorIncomingVendorsCount,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No vendor data found.'));
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Incoming vendors: ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${snapshot.data}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVendorList() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: FutureBuilder<QuerySnapshot>(
        future: _vendorList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors found.'));
          }

          var vendors = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: vendors.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              var vendor = vendors[index];
              return ListTile(
                title: Text(
                  vendor['name'] ?? 'No Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(vendor['email'] ?? 'No Email'),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    (vendor['name'] as String?)?.isNotEmpty == true
                        ? vendor['name'][0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showVendorDetails(context, vendor);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showVendorDetails(BuildContext context, DocumentSnapshot vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: VendorDetailsBottomSheet(vendorId: vendor.id),
          );
        },
      ),
    );
  }
}

class VendorDetailsBottomSheet extends StatelessWidget {
  final String vendorId;

  const VendorDetailsBottomSheet({super.key, required this.vendorId});

  Future<Map<String, int>> _fetchVendorStats() async {
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: vendorId)
        .get();

    final ordersSnapshot = await FirebaseFirestore.instance
        .collectionGroup('sellerOrders')
        .where('userId', isEqualTo: vendorId)
        .get();

    final attendedOrdersSnapshot = await FirebaseFirestore.instance
        .collectionGroup('sellerOrders')
        .where('userId', isEqualTo: vendorId)
        .where('acceptOrder', isEqualTo: true)
        // .where('acceptOrder', isEqualTo: 'attended')  // Assuming 'attended' is the status for attended orders
        .get();

    return {
      'productsCreated': productsSnapshot.docs.length,
      'ordersReceived': ordersSnapshot.docs.length,
      'ordersAttended': attendedOrdersSnapshot.docs.length,
    };
  }


  Future<void> _denialVendor(BuildContext context, String vendorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(vendorId)
          .update({
        'isVendorApproved': false
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content: Text(
                'Vendor Blacklisted')),
      );
    } catch (e) {
      print('Failed to update vendor: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor Info',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, int>>(
            future: _fetchVendorStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final stats = snapshot.data!;

              return Column(
                children: [
                  _buildStatCard('Products Created', '${stats['productsCreated']}', Icons.inventory),
                  const SizedBox(height: 10),
                  _buildStatCard('Orders Received', '${stats['ordersReceived']}', Icons.shopping_bag),
                  const SizedBox(height: 10),
                  _buildStatCard('Orders Attended', '${stats['ordersAttended']}', Icons.check_circle),
                  _buildStatCard('Item delivered', '${stats['ordersAttended']}', Icons.check_circle),
                  const SizedBox(height: 15,),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                    label: const Text('Blacklist vendor'),
                    onPressed: () => _denialVendor(context, vendorId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}