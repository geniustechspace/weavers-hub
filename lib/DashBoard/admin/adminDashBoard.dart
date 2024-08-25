import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weavershub/DashBoard/admin/accept-vendors.dart';

class AdminDashBoard extends StatefulWidget {
  const AdminDashBoard({super.key});

  @override
  State<AdminDashBoard> createState() => _AdminDashBoardState();
}

class _AdminDashBoardState extends State<AdminDashBoard> {
  late Future<QuerySnapshot> _vendorList;
  User? currentUser;
  late Future<int> _vendorCount;
  late Future<String> _adminName;

  @override
  void initState() {
    super.initState();
    _vendorList = _fetchVendors();
    _vendorCount = _fetchVendorCount();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
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
      body: Column(
        children: [
          _buildVendorCountCard(),
          const SizedBox(height: 20),
          Expanded(child: _buildVendorList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(const AcceptVendors()),
        label: const Text("Accept Vendors", style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.person_add,color: Colors.white,),
        backgroundColor: const Color(0xFF37B943),
      ),
    );
  }

  Widget _buildVendorCountCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  'Total Vendors Registered:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${snapshot.data}',
                  style: TextStyle(
                    fontSize: 24,
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
                  // Add vendor details navigation here
                },
              );
            },
          );
        },
      ),
    );
  }
}