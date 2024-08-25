import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class MyOrders extends StatelessWidget {
  const MyOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Orders'),
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser?.uid)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final orderData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final totalAmount = orderData['totalAmount'] as double;
              final itemsCount = orderData['itemsCount'] as int;

              Timestamp timestamp = orderData['orderDate'] as Timestamp;
              DateTime dateTime = timestamp.toDate();
              String timeAgo = timeago.format(dateTime, locale: 'en');
              String formattedDate = DateFormat('MMM d, y').format(dateTime);

              final orderId = snapshot.data!.docs[index].id.substring(0, 8).toUpperCase();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _showOrderDetails(context, orderData),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #$orderId',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            _buildStatusChip(orderData['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Placed $timeAgo',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'GHC ${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('$itemsCount ${itemsCount == 1 ? 'item' : 'items'}'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(bool status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status ? 'Completed' : 'Pending',
        style: TextStyle(
          color: status ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {

        Timestamp timestamp = orderData['orderDate'] as Timestamp;
        DateTime dateTime = timestamp.toDate();
        String timeAgo = timeago.format(dateTime, locale: 'en');
        String formattedDate = DateFormat('MMMM d, y').format(dateTime);
        return AlertDialog(
          title: const Text('Order Details'),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Date', '$formattedDate ($timeAgo)'),
                _buildDetailRow('Total Amount', 'GHC ${orderData['totalAmount']}'),
                _buildDetailRow('Delivery Charge', 'GHC ${orderData['deliveryCharge']}'),
                _buildDetailRow('Items Count', '${orderData['itemsCount']}'),
                _buildDetailRow('Customer', orderData['userName']),
                _buildDetailRow('Location', orderData['location']),
                _buildDetailRow('Phone', orderData['phone']),
                _buildDetailRow('Email', orderData['email']),
                _buildDetailRow('Status', orderData['status'] ? 'Completed' : 'Pending'),
                const SizedBox(height: 16),
                const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._buildProductList(orderData['products']),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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

  List<Widget> _buildProductList(List<dynamic> products) {
    return products.map((product) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product['image_url'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            ),
          ),
          title: Text(
            product['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price: GHC ${product['price']}'),
              Text('Quantity: ${product['quantity']}'),
            ],
          ),
        ),
      );
    }).toList();
  }
}