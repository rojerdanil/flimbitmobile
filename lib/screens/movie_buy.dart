import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MovieBuyScreen extends StatefulWidget {
  final int movieId;

  const MovieBuyScreen({super.key, required this.movieId});

  @override
  State<MovieBuyScreen> createState() => _MovieBuyScreenState();
}

class _MovieBuyScreenState extends State<MovieBuyScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic>? movie;
  Timer? _offerTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int numberOfUsers = 0;
  double investedAmount = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // --- Shares & Offers
  late TextEditingController _shareController;
  final PageController _offersPageController = PageController(
    viewportFraction: 0.4,
  );

  int numberOfShares = 1;
  double pricePerShare = 0;
  bool showOffer = false;
  bool calculated = false;
  bool isBuying = false;
  int selectedGatewayIndex = -1;
  bool expandedDescription = false;

  int userBoughtShares = 0;
  double userInvestedAmount = 0;
  bool isShareAvailable = false;
  int? shareTypeId;
  bool userReachedMaxInvest = false;
  int newTotalAfterOffer = 0;
  Map<String, dynamic>? calcuatedOffersList;
  List<Map<String, dynamic>> localOffers = [];

  List<Map<String, dynamic>> gatewayFees = [
    {"type": "UPI", "value": 0, "label": "₹0", "icon": Icons.payment},
    {"type": "Card", "value": 2, "label": "₹2", "icon": Icons.credit_card},
    {
      "type": "NetBanking",
      "value": 2,
      "label": "₹2",
      "icon": Icons.account_balance,
    },
  ];
  final ScrollController _scrollController = ScrollController(); // 👈 add this
  late Razorpay _razorpay;
  double platformCommision = 0;
  double profitCommision = 0;
  @override
  void initState() {
    super.initState();
    _shareController = TextEditingController(text: numberOfShares.toString());
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchMovieDetails();
  }

  Future<void> fetchMovieDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(
        "${ApiEndpoints.movieView}${widget.movieId}",
      );
      if (response != null) {
        setState(() {
          movie = response;
          if (movie!['perShareAmount'] != null) {
            pricePerShare = (movie!['perShareAmount'] as num).toDouble();
          }
        });
        await fetchGatewayFees(); // 🔥 Load gateway data
        await fetchInvestmentSummary();
      }
    } catch (e) {
      debugPrint("Error fetching movie details: $e");
    }
    setState(() => isLoading = false);
    _fadeController.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _offerTimer?.cancel();
    _shareController.dispose();
    _offersPageController.dispose();
    _scrollController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorpayCheckout(
    String orderId,
    double amount,
    String userName,
    String userEmail,
    String userContact,
  ) {
    if (kIsWeb) {
      _handlePaymentSuccess(
        PaymentSuccessResponse(
          "test_web_payment", // paymentId
          orderId ?? "order_test_123", // orderId (use null check or dummy)
          "test_signature", // signature
          {}, // data (pass empty map if not available)
        ),
      );
      return;
    }

    var options = {
      'key': 'rzp_test_6yjHqZxPkJmvO0',
      'amount': (amount * 100).toInt(), // amount in paise
      'name': 'Your App Name',
      'description': 'Movie Shares Purchase',
      'order_id': orderId, // from your backend / redirect-to-payment API
      'prefill': {'contact': userContact, 'email': userEmail, 'name': userName},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("Payment success: ${response.paymentId}");

    // 🔹 Call your backend to verify payment
    final payload = {
      "paymentId": response.paymentId,
      "orderId": response.orderId,
      "signature": response.signature,
    };

    final verifyResponse = await ApiService.post(
      ApiEndpoints.verifyPayment,
      body: payload,
      context: context,
    );

    if (verifyResponse != null) {
      // Show success popup
      final popup = await _buildPaymentSuccessPopup();
      showDialog(context: context, builder: (_) => popup);
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment verification failed")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment failed: ${response.code} - ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External wallet selected: ${response.walletName}");
  }

  // --- Helpers ---
  String formatIndianNumber(int value) {
    if (value >= 10000000) return "${(value / 10000000).toStringAsFixed(2)} Cr";
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(2)} L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
    return value.toString();
  }

  void incrementShares() {
    setState(() {
      numberOfShares++;
      _shareController.text = numberOfShares.toString();
      calculated = false;
      showOffer = false;
    });
  }

  void decrementShares() {
    if (numberOfShares > 1) {
      setState(() {
        numberOfShares--;
        _shareController.text = numberOfShares.toString();
        calculated = false;
        showOffer = false;
      });
    }
  }

  void updateShares(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        numberOfShares = parsed;
        calculated = false;
        showOffer = false;
      });
    }
  }

  Future<void> calculateOffer() async {
    if (numberOfShares <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number of shares")),
      );
      return;
    }

    setState(() {
      calculated = true;
      showOffer = true;
      localOffers = [];
    });

    try {
      final payload = {
        "movieId": widget.movieId,
        "numberOfShares": numberOfShares,
        "shareTypeId": shareTypeId,
        "promoCode": "",
      };

      final response = await ApiService.post(
        ApiEndpoints.calculateOffer,
        body: payload,
      );

      if (response != null) {
        final result = response ?? {};

        final discount = (result['totalDiscountAmount'] ?? 0).toDouble();
        final wallet = (result['totalWalletAmount'] ?? 0).toDouble();
        final freeShare = (result['totalFreeShare'] ?? 0).toInt();
        final platformCommission = result['platformCommision'] ?? false;
        final profitCommission = result['profitCommission'] ?? false;
        final maxInvestAmount = (result['maxInvestAmount'] ?? 0).toDouble();
        bool reachedMax = result['userReachedMaxInvest'] ?? false;

        // 🔹 Create the base offers list
        List<Map<String, dynamic>> updatedOffers = [
          {
            "type": "Discount",
            "value": discount,
            "label": "₹${discount.toStringAsFixed(0)}",
            "icon": Icons.local_offer,
          },
          {
            "type": "Wallet Discount",
            "value": wallet,
            "label": "₹${wallet.toStringAsFixed(0)}",
            "icon": Icons.account_balance_wallet,
          },
          {
            "type": "Free Share",
            "value": freeShare,
            "label": "$freeShare",
            "icon": Icons.share,
          },
        ];

        // 🔹 Add special commission info
        if (platformCommission == true) {
          updatedOffers.add({
            "type": "No Platform Commission",
            "value": 0,
            "label": "0%",
            "icon": Icons.cancel_presentation,
          });
        }

        if (profitCommission == true) {
          updatedOffers.add({
            "type": "No Profit Commission",
            "value": 0,
            "label": "0%",
            "icon": Icons.money_off,
          });
        }

        setState(() {
          localOffers = updatedOffers;

          // Update per-share amount if pres  ent

          userReachedMaxInvest = result['userReachedMaxInvest'] ?? false;
          newTotalAfterOffer = result['newTotalAfterOffer'] ?? 0;
          calcuatedOffersList = response as Map<String, dynamic>?;
        });
        if (reachedMax) {
          _showMaxInvestmentDialog(maxInvestAmount);
        }
      } else {
        debugPrint("Offer API failed: ${response?['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? "Offer fetch failed")),
        );
      }
    } catch (e) {
      debugPrint("Error calculating offer: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong!")));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _scrollToPaymentSection();
  }

  void _showMaxInvestmentDialog(double maxInvestAmount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                "Investment Limit Reached",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You’ve reached your maximum investment limit of ₹${maxInvestAmount.toStringAsFixed(0)}.",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please verify your PAN card to unlock higher investment limits.",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _scrollToPaymentSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  double gstPercent = 0.0; // 👈 declare at top of class with gatewayFees list

  Future<void> fetchGatewayFees() async {
    try {
      final response = await ApiService.get(ApiEndpoints.gatewayFees);
      if (response != null) {
        final List<dynamic> result = response;

        // Separate GST
        final gstItem = result.firstWhere(
          (item) => item['method'] == 'GST',
          orElse: () => null,
        );
        gstPercent = gstItem != null
            ? (gstItem['feePercentage'] as num).toDouble()
            : 0.0;

        // Filter out GST for display
        final filteredGateways = result
            .where((item) => item['method'] != 'GST')
            .toList();

        setState(() {
          gatewayFees = filteredGateways.map((item) {
            return {
              "type": item['method'],
              "value": (item['feePercentage'] as num).toDouble(),
              "label": "${item['feePercentage']}%",
              "icon": _getGatewayIcon(item['method']),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching gateway fees: $e");
    }
  }

  Future<void> fetchInvestmentSummary() async {
    try {
      final response = await ApiService.get(
        "${ApiEndpoints.movieInvestCountSummary}${widget.movieId}",
      );

      if (response != null) {
        final result = response;

        final countData = result['countData'];
        final countUserData = result['countUserData'];
        final shareType = result['movieshareType'];

        setState(() {
          // ✅ overall data
          numberOfUsers = countData?['userCount'] ?? 0;
          investedAmount =
              (countData?['totalInvested'] as num?)?.toDouble() ?? 0.0;

          // ✅ current user data
          userBoughtShares = countUserData?['totalShares'] ?? 0;
          userInvestedAmount =
              (countUserData?['totalInvested'] as num?)?.toDouble() ?? 0.0;

          // ✅ movie share availability
          isShareAvailable = shareType != null;
          if (shareType != null) {
            shareTypeId = shareType['id'];
            pricePerShare =
                (shareType['pricePerShare'] as num?)?.toDouble() ?? 0.0;
            platformCommision =
                (shareType['companyCommissionPercent'] as num?)?.toDouble() ??
                0.0;
            profitCommision =
                (shareType['profitCommissionPercent'] as num?)?.toDouble() ??
                0.0;
          }
        });
      } else {
        debugPrint("Failed to fetch invest summary: ${response?['message']}");
      }
    } catch (e) {
      debugPrint("Error fetching invest summary: $e");
    }
  }

  IconData _getGatewayIcon(String method) {
    switch (method.toUpperCase()) {
      case 'UPI':
        return Icons.payment;
      case 'CARD':
        return Icons.credit_card;
      case 'NETBANKING':
        return Icons.account_balance;
      case 'GST':
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }

  Future<void> buyShares() async {
    if (!calculated) return calculateOffer();

    if (selectedGatewayIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment gateway.")),
      );
      return;
    }

    // Show summary confirmation popup before final payment
    _showPaymentSummaryPopup();
  }

  Future<void> _showPaymentSummaryPopup() async {
    final gw = gatewayFees[selectedGatewayIndex];
    final String method = gw['type'] ?? "CARD";

    try {
      // 🔹 Fetch fee details from API
      final response = await ApiService.get(
        "${ApiEndpoints.calculateFee}?amount=$newTotalAfterOffer&method=$method",
      );

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to calculate payment summary.")),
        );
        return;
      }

      // 🔹 Extract response values
      final double investmentAmount =
          (response['investmentAmount'] as num?)?.toDouble() ?? totalAmount;
      final double gatewayFee =
          (response['convenienceFee'] as num?)?.toDouble() ?? 0.0;
      final double gstAmount = (response['gst'] as num?)?.toDouble() ?? 0.0;
      final double totalPayable =
          (response['totalPayable'] as num?)?.toDouble() ?? investmentAmount;

      // 🔹 New fields for wallet & discount

      // 🔹 Calculate commissions
      final double platformCommissionAmount =
          double.tryParse(
            (calcuatedOffersList?['calucatedPlatformFee'] ?? 0).toString(),
          ) ??
          0.0;

      final double originalInvestedAmount =
          double.tryParse(
            (calcuatedOffersList?['totalOrignalAmount'] ?? 0).toString(),
          ) ??
          0.0;

      final int freeShare = (calcuatedOffersList?['totalFreeShare'] ?? 0)
          .toInt();

      platformCommision =
          double.tryParse(
            (calcuatedOffersList?['plafformCommision'] ?? 0).toString(),
          ) ??
          0.0;

      profitCommision =
          double.tryParse(
            (calcuatedOffersList?['profitCommision'] ?? 0).toString(),
          ) ??
          0.0;

      final double walletPaybackAmount =
          double.tryParse(
            (calcuatedOffersList?['totalWalletAmount'] ?? 0).toString(),
          ) ??
          0.0;

      final double discountAmount =
          double.tryParse(
            (calcuatedOffersList?['totalDiscountAmount'] ?? 0).toString(),
          ) ??
          0.0;
      // 🔹 Show popup dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Payment Summary",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Offer Highlight
                    if (platformCommision == 0 ||
                        profitCommision == 0 ||
                        freeShare > 0)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.card_giftcard,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Special Offer: Extra benefits applied for this investment!",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 🔹 Shares Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Shares",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "$numberOfShares × ₹${pricePerShare.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (freeShare > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "+$freeShare Free",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          "₹${originalInvestedAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 🔹 Gateway Fee
                    _summaryRow(
                      "Gateway Fee ($method)",
                      "",
                      "₹${gatewayFee.toStringAsFixed(2)}",
                    ),

                    // 🔹 GST
                    _summaryRow(
                      "GST (${gstPercent.toStringAsFixed(2)}%)",
                      "",
                      "₹${gstAmount.toStringAsFixed(2)}",
                    ),

                    const Divider(thickness: 1),

                    // 🔹 Platform Commission
                    _summaryRow(
                      "Platform Commission (${platformCommision.toStringAsFixed(2)}%)",
                      "",
                      platformCommision == 0
                          ? "Free"
                          : "₹${platformCommissionAmount.toStringAsFixed(2)}",
                      valueColor: platformCommision == 0
                          ? Colors.green
                          : Colors.black87,
                    ),

                    const SizedBox(height: 6),

                    // 🔹 Profit Commission
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Profit Commission (${profitCommision.toStringAsFixed(2)}%)",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: profitCommision == 0
                                      ? Colors.green
                                      : Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                profitCommision == 0
                                    ? "(Offer applied – No profit fee)"
                                    : "(will be collected from profit)",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profitCommision == 0 ? "Free" : "-",
                          style: TextStyle(
                            color: profitCommision == 0
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: profitCommision == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const Divider(thickness: 1),

                    // 🔹 Wallet Payback & Discount Rows
                    _summaryRow(
                      "Wallet Payback Amount",
                      "",
                      "₹${walletPaybackAmount.toStringAsFixed(2)}",
                      valueColor: Colors.green,
                    ),
                    _summaryRow(
                      "Discount Amount",
                      "",
                      "-₹${discountAmount.toStringAsFixed(2)}",
                      valueColor: Colors.red,
                    ),

                    const SizedBox(height: 6),

                    // 🔹 Total Payable
                    _summaryRow(
                      "Total Payable",
                      "",
                      "₹${totalPayable.toStringAsFixed(2)}",
                      bold: true,
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Cancel",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);

                              final payload = {
                                "movieId": widget.movieId,
                                "numberOfShares": numberOfShares,
                                "shareTypeId": shareTypeId,
                                "promoCode": "",
                                "totalPayable": totalPayable.toStringAsFixed(2),
                                "paymentMethod": method,
                                "offerMoneyResponse": calcuatedOffersList,
                              };

                              await redirectToPayment(payload);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Proceed",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Error fetching payment summary: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> redirectToPayment(Map<String, dynamic> payload) async {
    setState(() => isBuying = true);

    try {
      final response = await ApiService.post(
        ApiEndpoints.redirectToPayment,
        body: payload,
        context: context,
      );

      if (response != null) {
        final orderNo = response?['orderNo'];
        final status = response?['status'];

        if (orderNo != null) {
          // 🔹 Trigger your payment popup
          final orderId = response['orderNo'];
          print(orderId);

          double totalPayable =
              double.tryParse(payload['totalPayable'].toString()) ?? 0.0;

          _openRazorpayCheckout(
            orderId,
            totalPayable,
            'test',
            'rojertest@gmail.com',
            "test",
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Payment not initiated")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? "Payment failed")),
        );
      }
    } catch (e) {
      debugPrint("Error redirecting to payment: $e");
    } finally {
      if (mounted) {
        setState(() {
          isBuying = false;
          calculated = false;
        });
      }
    }
  }

  Widget _summaryRow(
    String label,
    String sub,
    String value, {
    bool bold = false,
    Color? valueColor, // ✅ added this line
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              // ✅ Use the provided color (e.g. green for Free)
              color:
                  valueColor ?? (bold ? Colors.green.shade800 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  double get totalAmount => numberOfShares * pricePerShare;

  // --- Widgets ---
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    if (movie == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load movie details")),
      );
    }

    final invested = (movie!['investedAmount'] as num).toDouble();
    final budget = (movie!['budget'] as num).toDouble();
    final progress = (invested / budget).clamp(0.0, 1.0);
    final posterUrl = movie!['posterUrl'] ?? '';
    final offers =
        (movie!['offers'] is List && (movie!['offers'] as List).isNotEmpty)
        ? List<Map<String, dynamic>>.from(movie!['offers'])
        : localOffers;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        title: Text(movie!['title'] ?? 'Movie', style: AppTheme.headline1),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildBadgeRow(compact: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController, // 👈 connect controller
        child: Column(
          children: [
            // all your sections (movie details, actors, offers, gateway, etc.)
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPoster(posterUrl, progress, invested, budget),
                      const SizedBox(height: 16),
                      buildMovieInfo(),
                      buildSharesSection(),
                      buildInvestmentSummary(),
                      if (showOffer) buildOffersSection(offers),
                      if (calculated) buildGatewaySelection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (!isShareAvailable || isBuying || userReachedMaxInvest)
                  ? null
                  : (calculated ? buyShares : calculateOffer),

              child: isBuying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      !isShareAvailable
                          ? "Wait for Active Share"
                          : userReachedMaxInvest
                          ? "Max Investment Reached"
                          : (calculated ? "Buy Now" : "Calculate Offer"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // === COMPONENTS ===

  Widget buildMovieInfo() {
    return buildSection(
      title: "Movie Info",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Release: ${movie!['releaseDate'] ?? 'Coming Soon'}   Trailer: ${movie!['trailerDate'] ?? 'Coming Soon'}",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Genre: ${movie!['movieTypeName'] ?? 'N/A'} • ${movie!['language'] ?? 'N/A'}",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                setState(() => expandedDescription = !expandedDescription),
            child: AnimatedCrossFade(
              firstChild: Text(
                movie!['description'] ?? "",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              secondChild: Text(
                movie!['description'] ?? "",
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              crossFadeState: expandedDescription
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  setState(() => expandedDescription = !expandedDescription),
              child: Text(expandedDescription ? "Show less" : "Read more"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSharesSection() {
    // 🟢 Print when widget is built
    print("🔍 buildSharesSection called");
    print("userBoughtShares: $userBoughtShares");
    print("platformCommission: $platformCommision");
    print("profitCommission: $profitCommision");

    // 🔹 Log before returning
    if (userBoughtShares > 0) {
      print("✅ User already owns shares: $userBoughtShares");
    }

    return buildSection(
      title: "Shares",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 You can still show the “You Own” card here
          if (userBoughtShares > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade200, Colors.yellow.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You Own",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Shares: $userBoughtShares"),
                      Text("Invested: ₹${investedAmount.toStringAsFixed(2)}"),
                    ],
                  ),
                  const Icon(Icons.verified, color: Colors.green),
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Number of Shares",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  _roundButton(Icons.remove, () {
                    print("➖ Decrement pressed");
                    decrementShares();
                  }, Colors.redAccent),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _shareController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) {
                        print("✏️ Shares input changed: $val");
                        updateShares(val);
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _roundButton(Icons.add, () {
                    print("➕ Increment pressed");
                    incrementShares();
                  }, Colors.green),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 🔹 Platform Commission
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.account_balance,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Platform Commission",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              Text(
                (() {
                  print("💰 Platform Commission text: $platformCommision");
                  return "${platformCommision.toStringAsFixed(2)}%";
                })(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 🔹 Profit Commission
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Profit Commission",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              Text(
                (() {
                  print("📈 Profit Commission text: $profitCommision");
                  return "${profitCommision.toStringAsFixed(2)}%";
                })(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildInvestmentSummary() => buildSection(
    title: "Investment Summary",
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Total: ₹${totalAmount.toStringAsFixed(0)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "Per Share: ₹${pricePerShare.toStringAsFixed(0)}",
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );

  Widget buildOffersSection(List<Map<String, dynamic>> offers) {
    return buildSection(
      title: "Offers Applied",
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final off = offers[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade100, Colors.yellow.shade200],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        off['icon'],
                        size: 16,
                        color: Colors.yellow.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        off['type'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    off['label'] ?? off['value'].toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildGatewaySelection() {
    return buildSection(
      title: "Payment Gateway",
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: gatewayFees.length,
          itemBuilder: (context, index) {
            final gw = gatewayFees[index];
            final isSelected = index == selectedGatewayIndex;
            return GestureDetector(
              onTap: () => setState(() => selectedGatewayIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      gw['icon'],
                      color: isSelected
                          ? Colors.orange.shade800
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      gw['type'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.orange.shade900
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      "Fee: ${gw['label']}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Widget> _buildPaymentSuccessPopup() async {
    await fetchInvestmentSummary(); // ✅ refresh data before showing popup

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 30),
          SizedBox(width: 10),
          Text("Payment Successful!"),
        ],
      ),
      content: const Text(
        "Your investment has been successfully processed. You can view updated share details below.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }

  Widget _buildPoster(
    String posterUrl,
    double progress,
    double invested,
    double budget,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          posterUrl.isNotEmpty
              ? Image.network(
                  posterUrl,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 230,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.movie, size: 60),
                ),
          Icon(
            Icons.play_circle_fill,
            color: Colors.white.withOpacity(0.9),
            size: 70,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.white30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Raised: ₹${invested.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Goal: ₹${budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow({bool compact = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildBadge(
        Icons.people,
        numberOfUsers,
        Colors.amber.shade700,
        compact: compact,
      ),
      const SizedBox(width: 8),
      _buildBadge(
        Icons.monetization_on,
        investedAmount.toInt(),
        Colors.green.shade600,
        compact: compact,
      ),
    ],
  );

  Widget _buildBadge(
    IconData icon,
    int value,
    Color color, {
    bool compact = false,
  }) => ScaleTransition(
    scale: _pulseAnimation,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(seconds: 2),
            builder: (context, val, _) => Text(
              formatIndianNumber(val),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
