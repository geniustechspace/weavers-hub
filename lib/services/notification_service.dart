import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';




class NotificationService {
  final String _baseUrl = 'https://weavers-hub.onrender.com/send-notification/';

  Future<void> sendNotification({
    required String receiverUserId,
    required String title,
    required String body,
  }) async {
    try {
      // Get the receiver's FCM token from Firestore
      String? receiverToken = await _getFCMToken(receiverUserId);
      // String? token = await _firebaseMessaging.getToken();

      if (receiverToken == null) {
        // print('Receiver FCM token not found');
        return;
      }

      // Prepare the request body
      final Map<String, dynamic> notificationData = {
        'token': receiverToken,
        'title': title,
        'body': body,
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(notificationData),
      );

      if (response.statusCode == 200) {
        // print('Notification sent successfully');
      } else {
        // print('Failed to send notification. Status code: ${response.statusCode}');
        // print('Response body: ${response.body}');
      }
    } catch (e) {
      // print('Error sending notification: $e');
    }
  }

  Future<String?> _getFCMToken(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.get('fcmToken') as String?;
      }
    } catch (e) {
      // print('Error fetching FCM token: $e');
    }
    return null;
  }
}
