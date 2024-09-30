import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/firebase_auth.dart';
import '../widgets/buttons.dart';
import '../auth/login.dart';

class SplashScreen extends StatelessWidget {
   SplashScreen({super.key});

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
   final AuthService _authService = AuthService();
  bool isUserLogin() {
    User? user = _firebaseAuth.currentUser;
    return user != null;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomNavigationBar: const Text(
          textAlign: TextAlign.center,
          "By: Weavers HUB LTD.",
          style: TextStyle(fontWeight: FontWeight.w300, fontSize: 15)),
      backgroundColor: const Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Image(
              image: AssetImage('assets/overlapping_circles.png'),
            ),
            const Center(
              child: Text(
                'Weavers HUB',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30),
              ),
            ),
            SizedBox(height: size * 0.01),
            const Center(
              child: Image(
                image: AssetImage('assets/lady_next_to_phone.png'),
              ),
            ),
            SizedBox(
              height: size * 0.1,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                textAlign: TextAlign.center,
                'E-commerce mobile application for locally handwoven smock, kente and baskets',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 40),
              child: Text(
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  'To create a market for local handwoven smock, kente and baskets digitally'),
            ),
            const SizedBox(
              height: 30,
            ),
            Center(
                child: CustomButton(
              buttonName: 'Get Started',
              onTap: () => _authService.checkLoginStatus(),
              // isUserLogin() ? const SignInScreen() : SplashScree(),
              // onTap: () {
              //   Get.to(const SignInScreen());
              // },
            )),
          ],
        ),
      ),
    );
  }
}
