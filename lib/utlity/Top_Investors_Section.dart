import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart'; // Use AppTheme

class TopInvestorsSection extends StatefulWidget {
  const TopInvestorsSection({super.key});

  @override
  State<TopInvestorsSection> createState() => _TopInvestorsSectionState();
}

class _TopInvestorsSectionState extends State<TopInvestorsSection> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> investors = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int offset = 0;
  final int limit = 5;
  bool hasMore = true;

  final List<List<Color>> gradients = const [
    [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
    [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchTopInvestors();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _fetchMoreInvestors();
    }
  }

  Future<void> _fetchTopInvestors() async {
    setState(() => isLoading = true);
    await _loadInvestors();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreInvestors() async {
    setState(() => isLoadingMore = true);
    offset += limit;
    await _loadInvestors();
    setState(() => isLoadingMore = false);
  }

  Future<void> _loadInvestors() async {
    try {
      final payload = {"offset": offset, "limit": limit};
      final result = await ApiService.post(
        ApiEndpoints.topInvestors,
        body: payload,
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          investors.addAll(List<Map<String, dynamic>>.from(result));
          if (result.length < limit) hasMore = false;
        });
      } else {
        setState(() => hasMore = false);
      }
    } catch (e) {
      debugPrint("Error fetching top investors: $e");
    }
  }

  String formatInvested(num? amount) {
    if (amount == null || amount <= 0) return "₹0";
    if (amount >= 10000000)
      return "₹${(amount / 10000000).toStringAsFixed(2)} Cr";
    if (amount >= 100000) return "₹${(amount / 100000).toStringAsFixed(2)} L";
    return "₹${amount.toStringAsFixed(0)}";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.45;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (investors.isEmpty)
      return const Center(child: Text("No top investors available"));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "💎 Top Investors",
              style: AppTheme.headline1.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: investors.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == investors.length && isLoadingMore) {
                  return SizedBox(
                    width: cardWidth,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final investor = investors[index];
                final gradient = gradients[index % gradients.length];

                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child:
                            (investor["profilePicUrl"] != null &&
                                investor["profilePicUrl"].toString().isNotEmpty)
                            ? CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(
                                  investor["profilePicUrl"],
                                ),
                              )
                            : const CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.transparent,
                                child: Icon(
                                  Icons.person,
                                  size: 26,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              investor["userName"] ?? "Unknown",
                              style: AppTheme.headline2.copyWith(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Invested ${formatInvested(investor["totalInvested"])}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
