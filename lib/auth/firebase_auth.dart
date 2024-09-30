import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../DashBoard/admin/admin_dash_board.dart';
import '../userScreens/Users/landingPage/landing_page.dart';
import '../userScreens/vendor/vendor_screen.dart';
import 'login.dart';



class AuthService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;


  Future<void> createAccount(
      String name,
      String phone,
      String location,
      String email,
      String password,
      bool isVendor
      ) async {
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


  Future<void> handleLogin(String email, String password) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _redirectUser(userCredential.user!.uid);
    } catch (e) {
      Get.snackbar('Error', 'Failed to log in: $e');
    }
  }

  Future<void> _redirectUser(String uid) async {
    DocumentSnapshot userDoc = await firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData['isAdmin'] == true) {
        Get.offAll(() => const AdminDashBoard());
      } else if (userData['isVendor'] == true && userData['isVendorApproved'] == true) {
        Get.offAll(() => const VendorDashboard());
      } else {
        Get.offAll(() => const NavigationHome());
      }
    } else {
      Get.snackbar('Error', 'User data not found');
    }
  }

  Future<void> checkLoginStatus() async {
    User? user = auth.currentUser;
    if (user != null) {
      await _redirectUser(user.uid);
    } else {
      Get.offAll(() => const SignInScreen());
    }
  }
}
