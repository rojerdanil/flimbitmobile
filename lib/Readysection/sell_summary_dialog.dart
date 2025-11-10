import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../securityScreen/pin_verification_dialog.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class SellSummaryDialog {
  static Future<bool> show({
    required BuildContext context,
    required int movieId,
    required int enteredShares,
    required Map<String, dynamic> selectedPayment,
  }) async {
    // ---------------- API CALL ----------------
    Map<String, dynamic>? result;
    try {
      final requestBody = {"movieId": movieId, "numberOfShare": enteredShares};
      final response = await ApiService.post(
        ApiEndpoints.verifySellSharesSummary,
        body: requestBody,
      );
      if (response != null) {
        result = response;
      } else {
        throw Exception("Failed to fetch sell summary");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Error fetching sell summary: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    // ---------------- Extract Values ----------------
    final movieName = result?['movieName'] ?? 'Unknown';
    final shareTypeName =
        (result?['sharNames'] != null && result!['sharNames'].isNotEmpty)
        ? result['sharNames'][0]
        : 'N/A';
    final double pricePerShare =
        (result?['pricePerShare'] as num?)?.toDouble() ?? 0.0;
    final double totalValue =
        (result?['totalValue'] as num?)?.toDouble() ?? 0.0;
    final double totalDiscount =
        (result?['totalDiscount'] as num?)?.toDouble() ?? 0.0;
    final double totalWallet =
        (result?['totalWallet'] as num?)?.toDouble() ?? 0.0;
    final int totalFreeShare = result?['totalFreeShare'] ?? 0;
    final bool platformCommission = result?['plaftormCommision'] ?? false;
    final bool profitCommission = result?['profitCommision'] ?? false;
    final double extra = (result?['extra'] as num?)?.toDouble() ?? 0.0;
    final double finalTotal =
        (result?['finalTotal'] as num?)?.toDouble() ?? totalValue;

    // ---------------- Dialog UI ----------------
    final bool? dialogResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.yellow.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Sell Summary",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Divider(color: Colors.grey.shade300),
                _infoRow("🎬 Movie", movieName),
                _infoRow("💠 Share Type", shareTypeName),
                _infoRow("📦 Shares to Sell", "$enteredShares"),
                _infoRow(
                  "💳 Payment",
                  "${selectedPayment['type'].toString().toUpperCase()} – ${selectedPayment['name'] ?? 'N/A'}",
                ),
                const Divider(height: 25, color: Colors.black54),
                _summaryRow("Total Value", "₹${totalValue.toStringAsFixed(2)}"),
                _summaryRow("Free Shares", "$totalFreeShare"),
                _summaryRow(
                  "Discount",
                  "- ₹${totalDiscount.toStringAsFixed(2)}",
                ),
                _summaryRow(
                  "Wallet Bonus",
                  "- ₹${totalWallet.toStringAsFixed(2)}",
                ),
                _summaryRow(
                  "Extra Charges (Gateway Fees)",
                  "- ₹${extra.toStringAsFixed(2)}",
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: _summaryRow(
                    "💰 Final Amount",
                    "₹${finalTotal.toStringAsFixed(2)}",
                    isFinal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Platform Commission: ${platformCommission ? 'No' : 'Yes'}\nProfit Commission: ${profitCommission ? 'No' : 'Yes'}",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        // ---------------- CHANGE HERE ----------------
                        // Remove the early pop
                        final rootContext = Navigator.of(context).context;

                        final accessKey = await showPinVerificationDialog(
                          rootContext,
                        );

                        if (accessKey.isEmpty) {
                          if (rootContext.mounted) {
                            ScaffoldMessenger.of(rootContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "❌ Transaction cancelled or invalid PIN.",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return;
                        }

                        if (rootContext.mounted) {
                          final paymentSelection = {
                            "paymentType": selectedPayment['type'],
                            "id": selectedPayment['id'],
                          };

                          final success = await _startPayment(
                            context: rootContext,
                            movieId: movieId,
                            enteredShares: enteredShares,
                            shareTypeName: shareTypeName,
                            accessKey: accessKey,
                            result: result!,
                            payout: paymentSelection,
                          );

                          if (rootContext.mounted) {
                            Navigator.of(
                              rootContext,
                            ).pop(success); // Pass result back
                          }
                        }
                      },
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return dialogResult ?? false; // ✅ properly return true/false
  }

  // ---------------- startPayment remains unchanged ----------------
  static Future<bool> _startPayment({
    required BuildContext context,
    required int movieId,
    required int enteredShares,
    required String shareTypeName,
    required String accessKey,
    required Map<String, dynamic> result,
    required Map<String, dynamic> payout,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      final paymentRequest = {
        "movieId": movieId,
        "numberOfShare": enteredShares,
        "accessKey": accessKey,
        "payout": payout,
        "sellResponse": result.map((key, value) {
          if (value is num) return MapEntry(key, value.toString());
          return MapEntry(key, value);
        }),
      };

      final paymentResponse = await ApiService.post(
        ApiEndpoints.startShellShare,
        body: paymentRequest,
      );

      Navigator.pop(context); // close loader

      if (paymentResponse != null && paymentResponse['paymentId'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Payment started successfully for $enteredShares $shareTypeName shares.",
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ Payment failed: ${paymentResponse?['message'] ?? 'Unknown error'}",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return false;
      }
    } catch (e) {
      Navigator.pop(context); // close loader if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error while starting payment: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }
  }

  // ---------------- Helper UI Widgets ----------------
  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _summaryRow(
    String label,
    String value, {
    bool isFinal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color: isFinal ? Colors.black : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: isFinal ? Colors.orange.shade800 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
