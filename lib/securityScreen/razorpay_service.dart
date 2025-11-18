import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();

  RazorpayService({required this.onSuccess, required this.onFailure});

  final Function(String paymentId, String orderId) onSuccess;
  final Function(String message) onFailure;

  void init() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  /// 🔹 Opens Razorpay with dynamic values
  Future<void> openCheckout({
    required String razorpayKey,
    required String orderId,
    required double amount,
    required String userName,
    required String userEmail,
    required String userContact,
    required String description,
  }) async {
    final options = {
      'key': razorpayKey, // ✅ dynamic test/live key
      'order_id': orderId, // ✅ from backend
      'amount': (amount * 100).toInt(), // ✅ in paise
      'name': 'FilmBit',
      'description': description,
      'prefill': {'name': userName, 'email': userEmail, 'contact': userContact},
      'theme': {'color': '#F4B400'},
    };

    debugPrint("🟡 Opening Razorpay with: $options");
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ Payment Successful: ${response.paymentId}");
    onSuccess(response.paymentId ?? '', response.orderId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ Payment Failed: ${response.message}");
    onFailure(response.message ?? 'Payment failed');
  }

  void dispose() {
    _razorpay.clear();
  }
}
