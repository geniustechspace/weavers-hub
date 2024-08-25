import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Widgets/buttons.dart';
import '../Widgets/custome-text-feild.dart';
import '../Widgets/customn-loader.dart';
import '../Widgets/footerButton.dart';
import 'firebase-auth.dart';
import 'log-in.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController location = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController isVendorApproved = TextEditingController();

  bool _isVendor = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: Stack(
        children: [
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
                      'Welcome to Weavers HUB!',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 25),
                    ),
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Text(
                        maxLines: 4,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        'Register your account with us',
                      ),
                    ),
                  ),
                  Center(
                    child: CustomInputField(
                      hintText: 'Enter full name',
                      textEditingController: name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your Name';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                  Center(
                    child: CustomInputField(
                      hintText: 'Enter Phone',
                      textEditingController: phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter phone';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                  Center(
                    child: CustomInputField(
                      hintText: 'Enter Location',
                      textEditingController: location,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter Location';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                  Center(
                    child: CustomInputField(
                      hintText: 'Email address',
                      textEditingController: email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        } else if (!value.contains("@")) {
                          return 'Email does not contain @';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
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
                          return 'Please enter your Password';
                        }
                        return null;
                      },
                      showVisibilityToggle: true,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: size * 0.05),
                  Center(
                    child: CustomInputField(
                      obscureText: true,
                      hintText: 'Confirm password',
                      textEditingController: confirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty || value != password.text) {
                          return 'Password does not match';
                        }
                        return null;
                      },
                      showVisibilityToggle: true,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Text("Register as a vendor?"),
                      Checkbox(
                        checkColor: Colors.white,
                        activeColor: Colors.green,
                        value: _isVendor,
                        onChanged: (bool? newValue) {
                          setState(() {
                            _isVendor = newValue ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: size * 0.05),
                  Center(
                    child: CustomButton(
                      buttonName: 'Sign-up',
                      onTap: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });

                          try {

                             await createAccount(
                                 name.text,
                                 phone.text,
                                 location.text,
                                 email.text,
                                 password.text,
                                 _isVendor
                            );

                            // Handle successful registration
                            Get.snackbar('Success', 'Account created successfully');
                            Get.to(() => const SignInScreen());
                          } catch (e) {
                            // Handle errors
                            Get.snackbar('Error', 'Failed to create account: $e');
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                  ),
                  FooterButton(
                    question: 'Already have an account?',
                    buttonText: 'Log In',
                    onTap: () {
                      Get.to(const SignInScreen());
                    },
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
        ],
      ),
    );
  }
}
