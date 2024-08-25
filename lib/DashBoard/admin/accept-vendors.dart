import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcceptVendors extends StatefulWidget {
  const AcceptVendors({super.key});

  @override
  State<AcceptVendors> createState() => _AcceptVendorsState();
}

class _AcceptVendorsState extends State<AcceptVendors> {
  late Future<QuerySnapshot> _vendorsAwaitingApproval;

  @override
  void initState() {
    super.initState();
    _vendorsAwaitingApproval = _fetchVendorsAwaitingApproval();
  }

  Future<QuerySnapshot> _fetchVendorsAwaitingApproval() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .where('isVendor', isEqualTo: true)
        .where('isVendorApproved', isEqualTo: false)
        .get();
  }

  void _approveVendor(String vendorId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(vendorId)
        .update({'isVendorApproved': true});

    setState(() {
      _vendorsAwaitingApproval = _fetchVendorsAwaitingApproval();
    });
  }

  void _deleteVendor(String vendorId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(vendorId)
        .delete();

    setState(() {
      _vendorsAwaitingApproval = _fetchVendorsAwaitingApproval();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accept Vendors'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _vendorsAwaitingApproval,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors awaiting approval.'));
          }

          var vendors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              var vendor = vendors[index];
              return ListTile(
                title: Text(vendor['name'] ?? 'No Name'),
                subtitle: Text(vendor['email'] ?? 'No Email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveVendor(vendor.id),
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteVendor(vendor.id),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
