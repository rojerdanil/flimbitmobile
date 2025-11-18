import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../PaymentHandler/Wallet_AddMoney_razorpay_handler.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../PaymentHandler/razorpay_web.dart';

class WalletPaymentSummaryDialog extends StatefulWidget {
  final double amount;
  final String paymentOption;

  const WalletPaymentSummaryDialog({
    super.key,
    required this.amount,
    required this.paymentOption,
  });

  @override
  State<WalletPaymentSummaryDialog> createState() =>
      _WalletPaymentSummaryDialogState();
}

class _WalletPaymentSummaryDialogState
    extends State<WalletPaymentSummaryDialog> {
  Map<String, dynamic>? summaryData;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.walletAddMoneySummary,
        body: {"amount": widget.amount, "paymentType": widget.paymentOption},
      );

      if (response != null) {
        setState(() {
          summaryData = response;
          isLoading = false;
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> verifyWalletPayment(
    BuildContext context,
    double amount,
    String paymentOption,
    Map<String, dynamic> summaryData,
  ) async {
    try {
      final verificationRequest = {
        "amount": amount,
        "paymentType": paymentOption,
        "paymentCalculated": summaryData,
      };

      final verifyResponse = await ApiService.post(
        ApiEndpoints.walletVerifyPaymentSummary,
        body: verificationRequest,
        isFullBody: true,
      );

      if (verifyResponse != null && verifyResponse['status'] == 'success') {
        // TODO: Proceed with payment flow (like Razorpay or other)
        final result =
            verifyResponse['result']; // your backend success response

        if (kIsWeb) {
          // Stop further mobile Razorpay flow and use Web Razorpay
          try {
            final verifyResponse = await ApiService.post(
              ApiEndpoints.walletMonyeySuccess,
              body: {
                "paymentId": "test",
                "orderId": result['orderId'],
                "paymentMethod": "RAZORPAY",
                "signature": "test",
              },
              isFullBody: true, // your endpoint
            );

            debugPrint("🟢 Backend verify response: $verifyResponse");

            if (verifyResponse != null &&
                verifyResponse['status'] == 'success') {
              print("comming inside");

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment verified successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment verification failed."),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pop(context, true);
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

          return; // Stop mobile Razorpay flow
        }

        final razorpayHandler = RazorpayWallMoneyHandler(
          context: context,
          response: result,
        );
        razorpayHandler.startPayment();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Verification failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error verifying payment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Call Razorpay checkout on Web

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : isError
            ? const Center(child: Text("Failed to load payment summary"))
            : _buildSummary(),
      ),
    );
  }

  Widget _buildSummary() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.amber,
            size: 50,
          ),
          const SizedBox(height: 12),
          const Text(
            "Payment Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _row(
            "Amount",
            "₹${summaryData?['investmentAmount']?.toStringAsFixed(2) ?? '0.00'}",
          ),
          _row(
            "Gateway Fee",
            "₹${summaryData?['convenienceFee']?.toStringAsFixed(2) ?? '0.00'}",
          ),
          _row(
            "GST (${(summaryData?['gstRate'] ?? 0) * 100}%)",
            "₹${summaryData?['gst']?.toStringAsFixed(2) ?? '0.00'}",
          ),
          const Divider(height: 24, thickness: 1.2),
          _row(
            "Total Payable",
            "₹${summaryData?['totalPayable']?.toStringAsFixed(2) ?? '0.00'}",
            isBold: true,
            color: Colors.green.shade700,
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (summaryData == null) return;
                    await verifyWalletPayment(
                      context,
                      widget.amount,
                      widget.paymentOption,
                      summaryData!,
                    );
                  },
                  child: const Text(
                    "Proceed",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
