import 'dart:html';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';

@JS('openRazorpayCheckoutDart')
external void openRazorpayCheckoutDart(
  String key,
  String orderId,
  int amount,
  String currency,
  String name,
  String description,
  String userName,
  String userEmail,
  String userContact,
  String themeColor,
);

class RazorpayWebHandler {
  static void start(Map<String, dynamic> backendResponse) {
    if (!kIsWeb) return;

    openRazorpayCheckoutDart(
      backendResponse['razorpayKey'] ?? '',
      backendResponse['orderId'] ?? '',
      ((backendResponse['amount'] ?? 0) * 100).toInt(),
      backendResponse['currency'] ?? 'INR',
      backendResponse['name'] ?? 'FilmBit',
      backendResponse['description'] ?? '',
      backendResponse['userName'] ?? '',
      backendResponse['userEmail'] ?? '',
      backendResponse['userContact'] ?? '',
      backendResponse['themeColor'] ?? '#F4B400',
    );

    // Listen for success/failure
    window.addEventListener('razorpay-success', (event) {
      final data = (event as CustomEvent).detail;
      print('Payment Success: $data');
    });

    window.addEventListener('razorpay-failure', (event) {
      final data = (event as CustomEvent).detail;
      print('Payment Failure: $data');
    });
  }
}
