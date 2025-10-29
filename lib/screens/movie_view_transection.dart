import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart';

class TransactionReportScreen extends StatefulWidget {
  final int movieId;
  const TransactionReportScreen({super.key, required this.movieId});

  @override
  State<TransactionReportScreen> createState() =>
      _TransactionReportScreenState();
}

class _TransactionReportScreenState extends State<TransactionReportScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  int offset = 0;
  final int limit = 10;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fetchTransactions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _fetchTransactions() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        ApiEndpoints.userInvestmentHistory,
        body: {
          "offset": offset.toString(),
          "limit": limit.toString(),
          "movieId": widget.movieId,
        },
      );

      if (response != null) {
        setState(() {
          final List<Map<String, dynamic>> newItems =
              List<Map<String, dynamic>>.from(response);
          transactions.addAll(newItems);
          offset += limit;
        });

        // start animation after data is loaded
        _animationController.forward();
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching transactions: $e");
    }

    setState(() => isLoading = false);
  }

  String formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transaction data available.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    final pageCount = (transactions.length / 4).ceil(); // 4 cards per page
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;
    final cardHeight = 160.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Transaction Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        // Total Invested
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(1, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Invested",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatAmount(
                    transactions.fold<double>(
                      0.0,
                      (previousValue, element) =>
                          previousValue +
                          parseDouble(element['amountInvested']),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Swipeable cards with animation
        SizedBox(
          height: cardHeight * 2 + 24,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final pageItems = transactions
                  .skip(pageIndex * 4)
                  .take(4)
                  .toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cardWidth / cardHeight,
                  ),
                  itemCount: pageItems.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final animationValue = _animationController.value;
                        final safeOffset =
                            50.0 * (1.0 - (animationValue ?? 0.0));
                        return Opacity(
                          opacity: animationValue,
                          child: Transform.translate(
                            offset: Offset(0, safeOffset),
                            child: TransactionCard(
                              transaction: pageItems[index],
                              parseDouble: parseDouble,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  shrinkWrap: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final double Function(dynamic) parseDouble;
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.parseDouble,
  });

  @override
  Widget build(BuildContext context) {
    final amount = parseDouble(transaction['amountInvested']);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie Name + Date
          Text(
            transaction['categoryName'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            transaction['createdDate'] ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            "Qty:  ${transaction['numberOfShares']}",
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),

          // Amount
          const SizedBox(height: 6),

          Text(
            "Amount: ${NumberFormat.currency(symbol: '₹').format(amount)}",
            style: const TextStyle(fontSize: 13),
          ),

          const Spacer(),

          // Type placeholder (Credit/Debit)
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              transaction['type'] ?? 'Collection',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: (transaction['type'] == 'DEBIT')
                    ? Colors.red[700]
                    : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
