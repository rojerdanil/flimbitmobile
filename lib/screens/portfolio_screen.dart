import 'dart:convert';
import 'package:flutter/material.dart';
import '../chat/PortfolioGrowthChart.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Map<String, dynamic>? portfolio;
  Map<String, dynamic>? lastActivity;
  List<dynamic>? rewards;

  List<double> chartData = [];
  List<String> chartLabels = [];

  bool isLoading = false;
  bool isLoadingActivity = false;
  bool isLoadingRewards = false;
  bool isLoadingChart = false;

  @override
  void initState() {
    super.initState();
    fetchPortfolioData();
    fetchLastActivity();
    fetchRewards();
    fetchChartData();
  }

  Future<void> fetchPortfolioData() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(ApiEndpoints.userPortfolio);
      if (response != null) setState(() => portfolio = response);
    } catch (e) {
      debugPrint('Error fetching portfolio: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchLastActivity() async {
    setState(() => isLoadingActivity = true);
    try {
      final response = await ApiService.get(ApiEndpoints.last3Activity);
      if (response != null) setState(() => lastActivity = response);
    } catch (e) {
      debugPrint('Error fetching last activity: $e');
    } finally {
      setState(() => isLoadingActivity = false);
    }
  }

  Future<void> fetchRewards() async {
    setState(() => isLoadingRewards = true);
    try {
      final response = await ApiService.get(ApiEndpoints.rewards);
      if (response != null) setState(() => rewards = response);
    } catch (e) {
      debugPrint('Error fetching rewards: $e');
    } finally {
      setState(() => isLoadingRewards = false);
    }
  }

  Future<void> fetchChartData() async {
    setState(() => isLoadingChart = true);
    try {
      final response = await ApiService.get(ApiEndpoints.portfolioChart);
      if (response != null &&
          response != null &&
          response['investmentChart'] != null) {
        setState(() {
          chartData = List<double>.from(
            response['investmentChart']['data'].map((e) => e.toDouble()),
          );
          chartLabels = List<String>.from(
            response['investmentChart']['labels'],
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
    } finally {
      setState(() => isLoadingChart = false);
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchPortfolioData(),
      fetchLastActivity(),
      fetchRewards(),
      fetchChartData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingAll =
        isLoading || isLoadingActivity || isLoadingRewards || isLoadingChart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Overview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: RefreshIndicator(
        color: Colors.amber,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 60,
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        onRefresh: refreshAll,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutBack,
          child: isLoadingAll
              ? const Center(child: CircularProgressIndicator())
              : portfolio == null
              ? const Center(child: Text("No data found"))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      _buildStageFunds(),
                      const SizedBox(height: 16),
                      const Text(
                        "Earnings – Top 3 Movies",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildEarningsList(),
                      const SizedBox(height: 24),
                      const Text(
                        "Rewards & Offers",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: rewards != null
                              ? rewards!.map((r) {
                                  return _RewardChip(
                                    label: r['name'] ?? '',
                                    isApproved: r['awardStatus'] == "APPROVED",
                                  );
                                }).toList()
                              : const [],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Recent Transactions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (lastActivity != null) ..._buildActivityTiles(),
                      const SizedBox(height: 24),
                      PortfolioGrowthChart(
                        data: chartData,
                        labels: chartLabels,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _buildActivityTiles() {
    final List<Widget> tiles = [];
    final invest = lastActivity!['invementTrx'];
    final payout = lastActivity!['lastPayout'];
    final wallet = lastActivity!['lastWalletTrx'];

    if (invest != null) {
      tiles.add(
        _TransactionTile(
          title:
              "Invested ₹${invest['amountInvested']} in ${invest['movieName']} (${invest['categoryName']})",
          amount: "- ₹${invest['amountInvested']}",
        ),
      );
    }

    if (payout != null) {
      tiles.add(
        _TransactionTile(
          title:
              "Payout ₹${payout['amount']} (${payout['method']}) - ${payout['movieName']}",
          amount: "+ ₹${payout['amount']}",
        ),
      );
    }

    if (wallet != null) {
      tiles.add(
        _TransactionTile(
          title: wallet['description'] ?? "Wallet Transaction",
          amount:
              "${wallet['type'] == 'CREDIT' ? '+' : '-'} ₹${wallet['amount']}",
        ),
      );
    }

    return tiles;
  }

  Widget _buildOverviewSection() {
    final p = portfolio!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _OverviewItem(
              title: 'Total Invested',
              value: '₹ ${p['totalInvested'] ?? 0}',
            ),
            _OverviewItem(
              title: 'Average ROI',
              value: '${p['averageRoi'] ?? 0}%',
            ),
            _OverviewItem(
              title: 'Total Returns',
              value: '₹ ${p['totalReturns'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final p = portfolio!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double boxWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatBox(
                  title: 'Project Invested',
                  value: '${p['projectsInvest'] ?? 0}',
                  width: boxWidth,
                ),
                _StatBox(
                  title: 'Ongoing Projects',
                  value: '${p['ongoingProjects'] ?? 0}',
                  width: boxWidth,
                ),
                _StatBox(
                  title: 'Successful Releases',
                  value: '${p['successfulReleases'] ?? 0}',
                  width: boxWidth,
                ),
                _StatBox(
                  title: 'On-Hold Releases',
                  value: '${p['holdReleases'] ?? 0}',
                  width: boxWidth,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStageFunds() {
    final p = portfolio!;
    return Card(
      color: const Color(0xFFFFF9C4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stage Funds",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _StageFundItem(
              label: "Released",
              value: "₹${p['releasedStageFunds'] ?? 0}",
              color: Colors.greenAccent,
            ),
            _StageFundItem(
              label: "Ongoing",
              value: "₹${p['ongoingStageFunds'] ?? 0}",
              color: Colors.blueAccent,
            ),
            _StageFundItem(
              label: "On-Hold",
              value: "₹${p['onHoldStageFunds'] ?? 0}",
              color: Colors.pinkAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsList() {
    final earningList = portfolio!['earningList'] as List<dynamic>;
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: earningList.length,
        itemBuilder: (context, index) {
          final e = earningList[index];
          return _buildMovieCard(
            title: e['movieName'],
            imageUrl: e['posterUrl'],
            invested: '₹${e['invested']}',
            roi: '${e['averageRoi']}%',
            returns: '₹${e['returned']}',
            status: 'Released',
          );
        },
      ),
    );
  }

  Widget _buildMovieCard({
    required String title,
    required String imageUrl,
    required String invested,
    required String roi,
    required String returns,
    required String status,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(height: 80, color: Colors.grey[300]);
                },
              ),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _movieDetailRow("Invested:", invested),
              _movieDetailRow("ROI:", roi),
              _movieDetailRow("Returns:", returns),
              _movieDetailRow("Status:", status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _movieDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ================= SUB COMPONENTS =================
class _OverviewItem extends StatelessWidget {
  final String title;
  final String value;
  const _OverviewItem({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final double width;
  const _StatBox({
    required this.title,
    required this.value,
    required this.width,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StageFundItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StageFundItem({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final bool isApproved;
  const _RewardChip({required this.label, this.isApproved = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApproved ? Colors.green : Colors.yellow.shade700,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String amount;
  const _TransactionTile({required this.title, required this.amount});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
