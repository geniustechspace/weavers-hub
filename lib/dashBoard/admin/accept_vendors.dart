import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/notification_service.dart';

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

  Future<void> _approveVendor(String vendorId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(vendorId)
        .update({'isVendorApproved': true});
    setState(() {
      _vendorsAwaitingApproval = _fetchVendorsAwaitingApproval();
    });
  }



  @override
  Widget build(BuildContext context) {

    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Accept Vendors',style: TextStyle(color: Colors.white),),
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
        child: FutureBuilder<QuerySnapshot>(
          future: _vendorsAwaitingApproval,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No vendors awaiting approval.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              );
            }
            var vendors = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                var vendor = vendors[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () =>  _showVendorInfo(context, vendor.data() as Map<String, dynamic>),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vendor['email'] ?? 'No Email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                // onPressed: () =>
                                onPressed: () async {
                  _approveVendor(vendor.id);
                  await notificationService.sendNotification(
                    receiverUserId: vendor.id,
                    title: 'New Message from your admin',
                    body: 'your account has been approved',
                  );
                                },

                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showVendorInfo(BuildContext context, Map<String, dynamic> vendorInfo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {

        return  Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Vendor Info", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20)),
                const Divider(),
                _buildDetailRow('Name', vendorInfo['name']),
                _buildDetailRow('Email', vendorInfo['email']),
                _buildDetailRow('Location', vendorInfo['location']),
                _buildDetailRow('Phone', vendorInfo['phone']),
                _buildDetailRow('Status', vendorInfo['isVendor'] == true ? 'waiting' : 'approved'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );

      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
