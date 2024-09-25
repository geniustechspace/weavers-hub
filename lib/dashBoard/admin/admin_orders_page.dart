import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../services/notification_service.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  bool? isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Orders',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              // .collectionGroup('sellerOrders')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: SelectableText('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No orders found'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final orderDoc = snapshot.data!.docs[index];
                final order = orderDoc.data() as Map<String, dynamic>;

                final orderId = orderDoc.id.substring(0, 5).toUpperCase();

                Timestamp timestamp = order['orderDate'] as Timestamp;
                DateTime dateTime = timestamp.toDate();
                String timeAgo = timeago.format(dateTime, locale: 'en');
                String formattedDate = DateFormat('MMM d, y').format(dateTime);
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showOrderDetails(context, order),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              _buildStatusChip(order['status']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date: $formattedDate ($timeAgo)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${order["productName"]}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: GHC ${order["totalAmount"]}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quantity: ${order["quantity"]}'),
                              Column(
                                children: [
                                  Card(
                                    elevation: 5,
                                    surfaceTintColor: Colors.green,
                                    child: Checkbox(
                                      activeColor: Colors.green,
                                      value: order['acceptOrder'] ?? false,
                                      onChanged: (bool? value) {
                                        _updateOrderStatus(orderDoc.reference,
                                            value ?? false, order['userId']);
                                      },
                                    ),
                                  ),
                                  const Text("accept order",
                                      style: TextStyle(fontSize: 10)),
                                ],
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

  void _updateOrderStatus(
      DocumentReference orderRef, bool accepted, String receiverId) {
    final notificationService = NotificationService();
    orderRef.update({'acceptOrder': accepted}).then((_) async {
      String orderId = orderRef.id;

      DocumentSnapshot orderSnapshot = await orderRef.get();
      Map<String, dynamic> orderData =
          orderSnapshot.data() as Map<String, dynamic>;
      String buyerId = orderData['buyerId'];

      FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'acceptOrder': accepted});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(accepted ? 'Order accepted' : 'Order acceptance cancelled'),
          duration: const Duration(seconds: 1),
        ),
      );
      // Send notification to the user who created the order
      await notificationService.sendNotification(
        receiverUserId: buyerId,
        title: accepted ? 'Order Accepted' : 'Order Updated',
        body: accepted
            ? 'Your order #$orderId has been accepted by the vendor!'
            : 'Your order #$orderId has been updated.',
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $error'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
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

  // Widget _buildAcceptOrderCheckbox(BuildContext context, DocumentSnapshot orderDoc) {
  //   // bool isAccepted = (orderDoc.data() as Map<String, dynamic>)['acceptOrder'] ?? false;
  //   bool? isAccepted = false;
  //
  //   return Column(
  //     children: [
  //       Card(
  //         elevation: 10,
  //         surfaceTintColor: Colors.green,
  //         child: Checkbox(
  //           checkColor: Colors.white,
  //           activeColor: Colors.green,
  //           value: isAccepted,
  //           onChanged: (bool? newValue) {
  //            setState(() {
  //              isAccepted = newValue ?? false;
  //            });
  //             // write logic here
  //           },
  //         ),
  //       ),
  //       const Text("accept order", style: TextStyle(fontSize: 10)),
  //     ],
  //   );
  // }
  // _updateOrderAcceptance(context, orderDoc, newValue ?? false);

  // void _updateOrderAcceptance(BuildContext context, DocumentSnapshot orderDoc, bool newValue) async {
  //   try {
  //     await orderDoc.reference.update({'acceptOrder': newValue});
  //
  //     if (newValue) {
  //       String customerId = (orderDoc.data() as Map<String, dynamic>)['userId'];
  //       String orderId = orderDoc.id;
  //       await _sendOrderAcceptedNotification(customerId, orderId);
  //     }
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(newValue ? 'Order accepted' : 'Order acceptance cancelled')),
  //     );
  //   } catch (e) {
  //     print('Error updating order acceptance: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to update order status')),
  //     );
  //   }
  // }

  // Future<void> _sendOrderAcceptedNotification(String customerId, String orderId) async {
  //   try {
  //     final userDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
  //     final fcmToken = userDoc.data()?['fcmToken'];
  //
  //     if (fcmToken != null) {
  //       await http.post(
  //         Uri.parse('https://fcm.googleapis.com/fcm/send'),
  //         headers: <String, String>{
  //           'Content-Type': 'application/json',
  //           // 'Authorization': 'key=YOUR_SERVER_KEY', // Replace with your actual server key
  //         },
  //         body: jsonEncode(
  //           <String, dynamic>{
  //             'notification': <String, dynamic>{
  //               'body': 'Your order #$orderId has been accepted!',
  //               'title': 'Order Accepted'
  //             },
  //             'priority': 'high',
  //             'data': <String, dynamic>{
  //               'click_action': 'FLUTTER_NOTIFICATION_CLICK',
  //               'id': '1',
  //               'status': 'done'
  //             },
  //             'to': fcmToken,
  //           },
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error sending notification: $e');
  //   }
  // }

  // Future<void> _sendOrderNotification(String customerId, String orderId) async {
  //   try {
  //     final userDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
  //     final fcmToken = userDoc.data()?['fcmToken'];
  //
  //     if (fcmToken != null) {
  //       final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
  //       final headers = {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'key=YOUR_SERVER_KEY', // Replace with your server key from Firebase console
  //       };
  //       final body = {
  //         'to': fcmToken,
  //         'notification': {
  //           'title': 'Order Update',
  //           'body': 'Your order with ID $orderId has been processed.',
  //         },
  //         'data': {
  //           'orderId': orderId,
  //         },
  //       };
  //
  //       final response = await http.post(url, headers: headers, body: json.encode(body));
  //       if (response.statusCode == 200) {
  //         print('Notification sent successfully');
  //       } else {
  //         print('Failed to send notification: ${response.statusCode}');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error sending notification: $e');
  //   }
  // }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Order Details",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const Divider(),
                _buildDetailRow('Product', order["productName"]),
                _buildDetailRow('Total Amount', 'GHC ${order["totalAmount"]}'),
                _buildDetailRow('Quantity', '${order["quantity"]}'),
                _buildDetailRow('Customer', order['userName']),
                _buildDetailRow('Location', order['location']),
                _buildDetailRow('Phone', order['phone']),
                _buildDetailRow('Email', order['email']),
                _buildDetailRow(
                    'Status', order['status'] ? 'Completed' : 'Pending'),
                const SizedBox(height: 16),
                const Text('Products:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._buildProductList(order['products'] as List<dynamic>? ?? []),
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
            width: 100,
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
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product['image_url'] as String? ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          ),
          title: Text(
            product['name'] as String? ?? 'Unknown Product',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Price: GHC ${(product['price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}'),
              Text('Quantity: ${product['quantity'] ?? 'N/A'}'),
            ],
          ),
        ),
      );
    }).toList();
  }
}
