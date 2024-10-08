import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

import '../../../services/notification_service.dart';


class MyOrders extends StatefulWidget {
  const MyOrders({super.key});

  @override
  State<MyOrders> createState() => _MyOrdersState();
}

class _MyOrdersState extends State<MyOrders> {

  @override


  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: const Text(
          'My Orders',
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
                final orderDoc = snapshot.data!.docs[index];
                final orderData =
                    orderDoc.data() as Map<String, dynamic>;

                final totalAmount = orderData['totalAmount'] as double;
                final itemsCount = orderData['itemsCount'] as int;


                Timestamp timestamp = orderData['orderDate'] as Timestamp;
                DateTime dateTime = timestamp.toDate();
                String timeAgo = timeago.format(dateTime, locale: 'en');
                String formattedDate = DateFormat('MMM d, y').format(dateTime);


                final orderId =
                    snapshot.data!.docs[index].id.substring(0, 5).toUpperCase();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showOrderDetails(context, orderData),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID and Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #$orderId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              _buildStatusChip(orderData['status']),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Time and Date Info
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Placed $timeAgo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Total Amount
                          Text(
                            'GHC ${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Items Count, Checkbox, and Delivery Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$itemsCount ${itemsCount == 1 ? 'item' : 'items'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if(!orderData['acceptOrder'])
                                  Card(
                                    margin: const EdgeInsets.only(top: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Checkbox(
                                        activeColor: Colors.green,
                                        value: orderData['isDelivered'] ?? false,
                                        onChanged: (bool? value) {
                                          _updateOrderStatus(
                                            context,
                                            orderDoc.reference,
                                            value ?? false,
                                            orderData['userId'],
                                          );
                                        },
                                      ),
                                    ),
                                  ),


                                ],
                              ),

                              // Delivery Status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildAcceptanceStatusChip(orderData['acceptOrder'] ?? false),
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
      BuildContext context, // add context parameter here
      DocumentReference orderRef, bool accepted, String receiverId) {

    final notificationService = NotificationService();
    final user = FirebaseAuth.instance.currentUser;

    orderRef.update({'acceptOrder': accepted}).then((_) async {
      String orderId = orderRef.id;

      // Retrieve order data
      DocumentSnapshot orderSnapshot = await orderRef.get();
      Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
      String buyerId = orderData['userId'];

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'acceptOrder': accepted});

      // Querying and updating collectionGroup
      FirebaseFirestore.instance
          .collectionGroup('sellerOrders')
          .where('userId', isEqualTo: user?.uid)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({'acceptOrder': accepted});
        }
      });

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? "You've confirm that your order has been received": ' '),
          duration: const Duration(seconds: 1),
        ),
      );

      // Send notification to the buyer
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
          duration: const Duration(seconds: 50),
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



  Widget productDeliveredChip(bool isDelivered, Function(String, bool) updateOrderStatus, String orderId) {
    return ElevatedButton(
      onPressed: isDelivered
         ? () {
        updateOrderStatus(orderId, !isDelivered);
      }
    : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isDelivered ?  Colors.green[700]: Colors.white,
        minimumSize: const Size(25, 25),
        padding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Icon(
        isDelivered ? Icons.check : Icons.check_box,
        color: isDelivered ? Colors.white : Colors.white,
        size: 15,
      ),
    );
  }

  Future<void> updateOrderStatus(String orderId, bool isDelivered) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'isDelivered': isDelivered});
    // You might want to show a success message or update other parts of your UI here
  }

  Widget _buildAcceptanceStatusChip(bool accepted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accepted ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accepted ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            accepted ? Icons.check_circle : Icons.hourglass_empty,
            size: 10,
            color: accepted ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            accepted ? 'order accepted by seller' : 'Waiting for Acceptance',
            style: TextStyle(
              fontSize: 10,
              color: accepted ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> orderData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {

        Timestamp timestamp = orderData['orderDate'] as Timestamp;
        DateTime dateTime = timestamp.toDate();
        String timeAgo = timeago.format(dateTime, locale: 'en');
        String formattedDate = DateFormat('MMMM d, y').format(dateTime);

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
                _buildDetailRow('Date', '$formattedDate ($timeAgo)'),
                _buildDetailRow(
                    'Total Amount', 'GHC ${orderData['totalAmount']}'),
                _buildDetailRow(
                    'Delivery Charge', 'GHC ${orderData['deliveryCharge']}'),
                _buildDetailRow('Items Count', '${orderData['itemsCount']}'),
                _buildDetailRow('Customer', orderData['userName']),
                _buildDetailRow('Location', orderData['location']),
                _buildDetailRow('Phone', orderData['phone']),
                _buildDetailRow('Email', orderData['email']),
                _buildDetailRow(
                    'Status', orderData['status'] ? 'Completed' : 'Pending'),
                const SizedBox(height: 16),
                const Text('Products:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._buildProductList(orderData['products']),
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

  List<Widget> _buildProductList(List<dynamic> products) {
    return products.map((product) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
                imageUrl: product['image_url'],

                placeholder: (context, url) =>
                    const CircularProgressIndicator(),

                errorWidget: (context, url, error) => const Icon(Icons.error)),
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