import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class TopProfitHolderSection extends StatefulWidget {
  const TopProfitHolderSection({super.key});

  @override
  State<TopProfitHolderSection> createState() => _TopProfitHolderSectionState();
}

class _TopProfitHolderSectionState extends State<TopProfitHolderSection> {
  final ScrollController _scrollController = ScrollController();

  List<dynamic> profitHolders = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;

  int offset = 0;
  final int limit = 5;

  static const List<String> medals = ["🥇", "🥈", "🥉"];

  // Gradient colors for cards
  final List<List<Color>> gradients = const [
    [Color(0xFFE1F5FE), Color(0xFFB3E5FC)], // blue
    [Color(0xFFFFEBEE), Color(0xFFFFCDD2)], // pink
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // green
    [Color(0xFFFFF8E1), Color(0xFFFFECB3)], // cream
  ];

  List<Color> getGradient(int index) {
    return gradients[index % gradients.length];
  }

  @override
  void initState() {
    super.initState();
    fetchTopProfitHolders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        hasMore) {
      _fetchMoreProfitHolders();
    }
  }

  Future<void> fetchTopProfitHolders() async {
    setState(() => isLoading = true);
    await _fetchProfitHolders();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreProfitHolders() async {
    if (!hasMore) return;
    setState(() => isFetchingMore = true);
    await _fetchProfitHolders();
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchProfitHolders() async {
    try {
      final input = {"limit": limit, "offset": offset};
      final result = await ApiService.post(
        ApiEndpoints.topProfitHolders,
        body: input,
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          profitHolders.addAll(result);
          if (result.length >= limit) {
            offset += (limit - 1);
          } else {
            hasMore = false;
          }
        });
      } else {
        setState(() => hasMore = false);
      }
    } catch (e) {
      debugPrint("Error fetching profit holders: $e");
      setState(() => hasMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.45;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "💹 Top Profit Holders",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (isLoading && profitHolders.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (profitHolders.isEmpty)
            const Center(
              child: Text(
                "No profit holders found.",
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: profitHolders.length + (isFetchingMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == profitHolders.length) {
                    return const SizedBox(
                      width: 60,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final holder = profitHolders[index];
                  final double invested = (holder['totalInvested'] ?? 0)
                      .toDouble();
                  final double returned = (holder['totalReturned'] ?? 0)
                      .toDouble();
                  final double profit = returned - invested;
                  final percent = invested > 0
                      ? ((profit / invested) * 100).toStringAsFixed(1)
                      : "0";

                  // First card: soft gray background, others: gradient
                  final decoration = BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: index == 0 ? const Color(0xFFF7F7F7) : null,
                    gradient: index == 0
                        ? null
                        : LinearGradient(
                            colors: getGradient(index),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  );

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: cardWidth,
                        padding: const EdgeInsets.all(10),
                        decoration: decoration,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(
                                holder['profilePicUrl'] ??
                                    'https://via.placeholder.com/150',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holder['userName'] ?? "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Invested: ₹${invested.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Profit badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Profit: ₹${profit.toStringAsFixed(0)} (+$percent%)",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -8,
                        left: -8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Text(
                            index < medals.length ? medals[index] : "⭐",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
