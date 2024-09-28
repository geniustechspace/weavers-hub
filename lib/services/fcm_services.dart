// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class FCMService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   Future<void> init() async {
//     // Request permission
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission');

//       // Initialize local notifications
//       const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//       // final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
//       const InitializationSettings initializationSettings = InitializationSettings(
//         android: initializationSettingsAndroid,
//         // iOS: initializationSettingsIOS,
//       );
//       await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

//       // Handle incoming messages
//       FirebaseMessaging.onMessage.listen(_handleMessage);
//       FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
//       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//       // Get the token
//       String? token = await _firebaseMessaging.getToken();
//       print('FCM Token: $token');

//       // Save the token to Firestore
//       await _saveFCMToken(token);
//     } else {
//       print('User declined or has not accepted permission');
//     }
//   }

//   Future<void> _saveFCMToken(String? token) async {
//     if (token != null) {
//       String? userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId != null) {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userId)
//             .update({'fcmToken': token});
//       }
//     }
//   }

//   void _handleMessage(RemoteMessage message) {
//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;

//     if (notification != null && android != null) {
//       _flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'channel_id',
//             'channel_name',
//             channelDescription: 'channel_description',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//         ),
//       );
//     }
//   }

//   static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     print("Handling a background message: ${message.messageId}");
//   }

//   Future<void> subscribeToTopic(String topic) async {
//     await _firebaseMessaging.subscribeToTopic(topic);
//   }

//   Future<void> unsubscribeFromTopic(String topic) async {
//     await _firebaseMessaging.unsubscribeFromTopic(topic);
//   }
// }

