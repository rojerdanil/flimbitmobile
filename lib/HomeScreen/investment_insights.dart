import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import 'investment_details_screen.dart';

class InvestmentInsights extends StatefulWidget {
  const InvestmentInsights({super.key});

  @override
  State<InvestmentInsights> createState() => _InvestmentInsightsState();
}

class _InvestmentInsightsState extends State<InvestmentInsights>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Map<String, dynamic>? summaryData;
  bool isLoading = true;

  final List<List<Color>> cardGradients = const [
    [Color(0xFFFFFDE7), Color(0xFFFFECB3)], // gold
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // blue
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // green
    [Color(0xFFFFEBEE), Color(0xFFFFCDD2)], // pink
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _fetchInvestmentSummary();
  }

  Future<void> _fetchInvestmentSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.movieSummaryCounts);
      if (response != null) {
        setState(() {
          summaryData = response;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching summary: $e");
      setState(() => isLoading = false);
    }
  }

  String formatAmount(dynamic value) {
    if (value == null) return "0";
    double num;
    if (value is int) {
      num = value.toDouble();
    } else if (value is double) {
      num = value;
    } else if (value is String) {
      num = double.tryParse(value) ?? 0;
    } else {
      num = 0;
    }

    if (num >= 10000000) {
      return "₹${(num / 10000000).toStringAsFixed(2)} Cr";
    } else if (num >= 100000) {
      return "₹${(num / 100000).toStringAsFixed(2)} L";
    } else if (num >= 1000) {
      return "₹${(num / 1000).toStringAsFixed(2)} K";
    } else {
      return "₹${num.toStringAsFixed(0)}";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (isLoading) {
          return _buildLoadingState();
        }

        if (summaryData == null) {
          return const Center(child: Text("No data available"));
        }

        final insights = [
          {
            "title": "Total Investments",
            "value": formatAmount(summaryData!['totalInvested'] ?? 0),
            "icon": Icons.account_balance_wallet_rounded,
          },
          {
            "title": "Active Movies",
            "value": summaryData!['totalMovies']?.toString() ?? "0",
            "icon": Icons.movie_filter_rounded,
          },
          {
            "title": "Total Investors",
            "value": summaryData!['totalUser']?.toString() ?? "0",
            "icon": Icons.people_alt_rounded,
          },
          {
            "title": "Avg ROI",
            "value": "${summaryData!['averageRoi'] ?? 0}%",
            "icon": Icons.trending_up_rounded,
          },
        ];

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            "📊 Investment Insights",
                            style: AppTheme.headline1,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 130,
                          child: Container(
                            height: 3,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvestmentDetailsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "View Details",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 18, bottom: 8),
                child: Text(
                  "Last Updated: Just now",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: insights.length,
                  itemBuilder: (context, index) {
                    final item = insights[index];
                    final gradient =
                        cardGradients[index % cardGradients.length];
                    return _buildInsightCard(item, gradient);
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: List.generate(4, (index) {
            return Container(
              height: 80,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> item, List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.primaryColor.withOpacity(0.8),
            highlightColor: Colors.white,
            child: Icon(item["icon"], color: AppTheme.primaryColor, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item["value"].toString(),
                  style: AppTheme.headline2.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(item["title"] ?? "", style: AppTheme.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
