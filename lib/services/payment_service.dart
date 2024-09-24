import 'dart:convert';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  void makePayment({
    required BuildContext context,
    required String email,
    required double amount,
    required Function(String) onSuccess,
    required VoidCallback onFailure,
  }) async {

    final uniqueTransRef = PayWithPayStack().generateUuidV4();
    await FirebaseFirestore.instance.collection('orders').doc(uniqueTransRef).set({
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });

    PayWithPayStack().now(
      context: context,
      secretKey: "sk_test_fc20a32819750f37fbf5177e193a76455bdecca2",
      customerEmail: email,
      reference: uniqueTransRef,
      callbackUrl: "https://amp.amalitech-dev.net/",
      currency: "GHS",
      paymentChannel: ["mobile_money", "card"],
      amount: amount,
      transactionCompleted: () async {
        bool isVerified = await _verifyPaymentOnServer(uniqueTransRef);
        if (isVerified) {
          onSuccess(uniqueTransRef);
        } else {
          onFailure();
        }
      },
      transactionNotCompleted: onFailure,
    );
  }

  Future<bool> _verifyPaymentOnServer(String reference) async {
    final response = await http.get(
      Uri.parse("https://api.paystack.co/transaction/verify/$reference"),
      headers: {
        'Authorization': 'Bearer sk_test_fc20a32819750f37fbf5177e193a76455bdecca2',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] != null && data['data']['status'] == 'success';
    }
    return false;
  }
}