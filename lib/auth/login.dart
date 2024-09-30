import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weavershub/auth/signup.dart';
import '../DashBoard/admin/admin_dash_board.dart';
import '../userScreens/Users/landingPage/landing_page.dart';
import '../userScreens/vendor/vendor_screen.dart';
import '../widgets/buttons.dart';
import '../widgets/custom_text_feild.dart';
import '../widgets/custom_loader.dart';
import '../widgets/footer_button.dart';
import 'firebase_auth.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Stack(children: [
        SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Image(
                  image: AssetImage('assets/overlapping_circles.png'),
                ),
                const Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    'Log-in to Weavers HUB!',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 25),
                  ),
                ),
                SizedBox(height: size * 0.05),
                const Center(
                  child: Image(
                    image: AssetImage('assets/man_next_to_phone.png'),
                  ),
                ),
                SizedBox(height: size * 0.1),
                Center(
                  child: CustomInputField(
                    hintText: 'Email address',
                    textEditingController: email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      } else if (!value.contains("@")) {
                        return 'Email does not Contain @';
                      }
                      return null;
                    },
                    keyboardType:
                        TextInputType.emailAddress, // Use emailAddress type
                  ),
                ),
                SizedBox(height: size * 0.05),
                Center(
                  child: CustomInputField(
                      obscureText: true,
                      hintText: 'Password',
                      textEditingController: password,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide a password';
                        }
                        return null;
                      },
                      showVisibilityToggle: true,
                      keyboardType: TextInputType.text),
                ),
                FooterButton(
                  question: "Don't have an account?",
                  buttonText: 'Sign Up',
                  onTap: () {
                    Get.to(const RegistrationScreen());
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: CustomButton(
                      buttonName: 'Log - in',
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            _authService.handleLogin(
                              email.text,
                              password.text,
                            );
                            // Attempt to log in the user
                            // UserCredential userCredential = await FirebaseAuth
                            //     .instance
                            //     .signInWithEmailAndPassword(
                            //   email: email.text,
                            //   password: password.text,
                            // );

                            // Retrieve user document from Firestore
                            // DocumentSnapshot userDoc = await FirebaseFirestore
                            //     .instance
                            //     .collection('users')
                            //     .doc(userCredential.user?.uid)
                            //     .get();

                            // if (userDoc.exists) {
                            //   bool isAdmin = userDoc['isAdmin'];
                            //
                            //   // vendor = true and isApprove is false ==> users page
                            //   // vendor = true and isApprove is true ==> vendors page
                            //   // vendor = false and isApprove is true or false ==> users page
                            //
                            //   if (isAdmin) {
                            //     Get.to(() => const AdminDashBoard());
                            //   } else {
                            //     bool isVendor = userDoc['isVendor'];
                            //     bool isVendorApproved = userDoc['isVendorApproved'];
                            //     if (isVendor && isVendorApproved) {
                            //       Get.to(() =>  const VendorDashboard());
                            //     } else {
                            //       Get.to(() =>  const NavigationHome());
                            //     }
                            //   }
                            // }
                          } catch (e) {
                            // Handle errors
                            Get.snackbar('Error', 'Failed to log in: $e');
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      }),
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CustomLoader(
                size: 20,
                color: Colors.green,
              ),
            ),
          ),
      ]),
    );
  }
}
