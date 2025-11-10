import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class InvestmentDetailsScreen extends StatefulWidget {
  const InvestmentDetailsScreen({super.key});

  @override
  State<InvestmentDetailsScreen> createState() =>
      _InvestmentDetailsScreenState();
}

class _InvestmentDetailsScreenState extends State<InvestmentDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _liveDotController;

  Map<String, dynamic>? summaryData;
  List<FlSpot> chartSpots = [];
  bool isLoading = true;
  List<dynamic> topMovies = [];
  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _liveDotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchInvestmentSummary(),
      _fetchChartData(),
      _fetchTopMovies(), // ⬅️ new
    ]);
  }

  Future<void> _fetchTopMovies() async {
    try {
      final response = await ApiService.get(
        ApiEndpoints.topLiveInvestingMovies,
      );
      if (response != null) {
        setState(() {
          topMovies = response;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching top movies: $e");
    }
  }

  Future<void> _fetchInvestmentSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.movieSummaryCounts);
      if (response != null) {
        setState(() => summaryData = response);
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching summary: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchChartData() async {
    try {
      final response = await ApiService.get(ApiEndpoints.investmentGrowthChart);
      if (response != null) {
        final result = response ?? {};
        final investmentChart = result['investmentChart'];

        if (investmentChart != null) {
          List<dynamic> labels = investmentChart['labels'] ?? [];
          List<dynamic> data = investmentChart['data'] ?? [];

          chartSpots = List.generate(
            data.length,
            (i) => FlSpot(i.toDouble(), (data[i] ?? 0).toDouble()),
          );
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching chart data: $e");
    }
  }

  String formatAmount(dynamic value) {
    if (value == null) return "₹0";
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
    _shimmerController.dispose();
    _liveDotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Investment Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final shimmerShift = _shimmerController.value;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedBuilder(
                              animation: _liveDotController,
                              builder: (context, child) {
                                final opacity =
                                    0.5 + (0.5 * _liveDotController.value);
                                return Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryColor.withOpacity(
                                      opacity,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(opacity),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "LIVE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Updated: Just now",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text("📈 Investment Growth", style: AppTheme.headline1),
                        const SizedBox(height: 12),

                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment(-1 + shimmerShift, -1),
                              end: Alignment(1 - shimmerShift, 1),
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.2),
                                Colors.white,
                                AppTheme.primaryColor.withOpacity(0.15),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: (chartSpots.isNotEmpty)
                                      ? (chartSpots
                                                .map((e) => e.y)
                                                .reduce(
                                                  (a, b) => a > b ? a : b,
                                                ) /
                                            4)
                                      : 20,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.15),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 48,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          formatAmount(value),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final months = [
                                          "Jan",
                                          "Feb",
                                          "Mar",
                                          "Apr",
                                          "May",
                                          "Jun",
                                          "Jul",
                                          "Aug",
                                          "Sep",
                                          "Oct",
                                          "Nov",
                                          "Dec",
                                        ];
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < months.length) {
                                          return Text(
                                            months[value.toInt()],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black54,
                                            ),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: 11,
                                minY: 0,
                                maxY: (chartSpots.isNotEmpty)
                                    ? chartSpots
                                              .map((e) => e.y)
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.2
                                    : 100,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: chartSpots.isNotEmpty
                                        ? chartSpots
                                        : const [FlSpot(0, 0)],
                                    isCurved: true,
                                    color: AppTheme.primaryColor,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withOpacity(
                                            0.3,
                                          ),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    dotData: FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          "💰 Investment Overview",
                          style: AppTheme.headline1,
                        ),
                        const SizedBox(height: 10),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.8,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            _buildStatCard(
                              "Total Investments",
                              formatAmount(summaryData?['totalInvested'] ?? 0),
                              Icons.account_balance_wallet,
                            ),
                            _buildStatCard(
                              "Avg ROI",
                              "${summaryData?['averageRoi'] ?? 0}%",
                              Icons.trending_up,
                            ),
                            _buildStatCard(
                              "Active Movies",
                              summaryData?['totalMovies'].toString() ?? "0",
                              Icons.movie_filter,
                            ),
                            _buildStatCard(
                              "Total Investors",
                              summaryData?['totalUser'].toString() ?? "0",
                              Icons.people_alt,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Text(
                          "🏆 Top Performing Movies",
                          style: AppTheme.headline1,
                        ),
                        const SizedBox(height: 12),
                        ...topMovies.map((movie) {
                          return _buildTopMovie(movie);
                        }).toList(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTheme.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTheme.subtitle.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMovie(dynamic movie) {
    String title = movie['movieName'] ?? "Unknown";
    String language = movie['language'] ?? "N/A";
    double roi = (movie['roiPercent'] ?? 0).toDouble();
    String posterUrl = movie['posterUrl'] ?? "";
    double investedAmount = (movie['totalInvestedAmount'] ?? 0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        color: Colors.white,
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: posterUrl.isNotEmpty
              ? Image.network(
                  posterUrl,
                  width: 45,
                  height: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 45,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.movie, color: Colors.grey, size: 30),
                ),
        ),
        title: Text(title, style: AppTheme.headline2),
        subtitle: Text(
          "ROI: ${roi.toStringAsFixed(1)}",
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Text(
          formatAmount(investedAmount),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
