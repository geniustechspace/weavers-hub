import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> createAccount(String name, String phone, String location, String email,   String password,  bool isVendor) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Create the user account
  UserCredential userCredential = await auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // Get the FCM token
  String? fcmToken = await FirebaseMessaging.instance.getToken();

  // Add user details to Firestore
  await firestore.collection('users').doc(userCredential.user!.uid).set({
    'name': name,
    'phone': phone,
    'fcmToken': fcmToken,
    'location': location,
    'email': email,
    'isVendor': isVendor,
    'isVendorApproved': false,
    'isAdmin': false
  });
}
