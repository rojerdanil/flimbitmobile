import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class RazorpayWallMoneyHandler {
  late final Razorpay _razorpay;
  final BuildContext context;
  final Map<String, dynamic> response; // backend response

  RazorpayWallMoneyHandler({required this.context, required this.response});

  /// ✅ Start Razorpay flow
  void startPayment() {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

      final options = {
        'key': response['razorpayKey'],
        'order_id': response['orderId'],
        'amount': (response['amount'] * 100).toInt(), // amount in paise
        'currency': response['currency'] ?? 'INR',
        'name': response['name'] ?? 'FilmBit',
        'description': response['description'] ?? 'Wallet Top-up',
        'prefill': {
          'name': response['userName'] ?? '',
          'email': response['userEmail'] ?? '',
          'contact': response['userContact'] ?? '',
        },
        'theme': {'color': response['themeColor'] ?? '#F4B400'},
      };

      debugPrint("🟡 Opening Razorpay Checkout: $options");
      _razorpay.open(options);
    } catch (e) {
      debugPrint("❌ Razorpay Init Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to start payment: $e")));
    }
  }

  /// ✅ Payment success callback
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse success) async {
    debugPrint("✅ Razorpay Payment Success: ${success.paymentId}");

    try {
      final verifyResponse = await ApiService.post(
        ApiEndpoints.walletMonyeySuccess,
        body: {
          "paymentId": success.paymentId,
          "orderId": success.orderId,
          "paymentMethod": "RAZORPAY",
          "signature": success.signature,
        },
        context: context,
        isFullBody: true, // your endpoint
      );

      debugPrint("🟢 Backend verify response: $verifyResponse");

      if (verifyResponse != null && verifyResponse['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment verified successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment verification failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error verifying payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error verifying payment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      dispose();
    }
  }

  /// ❌ Payment failure callback
  void _handlePaymentError(PaymentFailureResponse failure) {
    debugPrint("❌ Razorpay Payment Failed: ${failure.message}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${failure.message ?? 'Unknown error'}"),
        backgroundColor: Colors.red,
      ),
    );

    dispose();
  }

  /// 🧹 Clean up listeners
  void dispose() {
    _razorpay.clear();
  }
}
