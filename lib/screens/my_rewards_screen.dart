import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../reward/star_connect_movie_list.dart';
import '../reward/filmbit_movie_list.dart';
import 'dart:ui';

class MyRewardsScreen extends StatefulWidget {
  const MyRewardsScreen({super.key});

  @override
  State<MyRewardsScreen> createState() => _MyRewardsScreenState();
}

class _MyRewardsScreenState extends State<MyRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? selectedReward;
  bool isStarConnectSelected = true;
  int? selectedOfferId;
  List<Map<String, dynamic>> starConnectSummary = [];
  Map<String, dynamic> filmBitSummary = {};

  final List<Color> cardColors = [
    AppTheme.accentColor,
    AppTheme.accentColor,
    AppTheme.accentColor,
    AppTheme.accentColor,
    AppTheme.accentColor,
    AppTheme.accentColor,
  ];

  final Map<String, IconData> rewardIcons = {
    "Act in Movie": Icons.movie_filter,
    "Premium Show": Icons.star,
    "Meet & Greet": Icons.people_alt,
    "Live Call with Actor": Icons.videocam,
    "Free Shares": Icons.card_giftcard,
    "Platform Commission": Icons.percent,
    "Profit Commission": Icons.trending_up,
    "Wallet Cashback": Icons.account_balance_wallet,
    "Discount": Icons.local_offer,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadSummary();
    loadFilmBitSummary();
  }

  Future<void> loadSummary() async {
    final data = await fetchStarConnectSummary();
    setState(() {
      starConnectSummary = data;
    });
  }

  Future<List<Map<String, dynamic>>> fetchStarConnectSummary() async {
    final response = await ApiService.get(
      ApiEndpoints.reward_star_connect_summary,
    );
    if (response != null) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<void> loadFilmBitSummary() async {
    final response = await ApiService.get(ApiEndpoints.reward_flim_bit_summary);

    if (response != null && response is Map<String, dynamic>) {
      setState(() {
        filmBitSummary = response;
      });
    } else {
      setState(() {
        filmBitSummary = {
          "no_profit_commission_count": 0,
          "total_free_share": 0,
          "no_platform_commission_count": 0,
          "total_wallet_amount": 0,
          "total_discount": 0,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Rewards", style: TextStyle(color: Colors.black)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: "Star Connect"),
            Tab(text: "FilmBit"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          rewardsTab(isStarConnect: true),
          rewardsTab(isStarConnect: false),
        ],
      ),
    );
  }

  Widget rewardsTab({required bool isStarConnect}) {
    if (isStarConnect) {
      final items = starConnectSummary.map((r) {
        return {
          "title": r["offer_name"].toString(),
          "count": r["total_count"].toString(),
          "offer_id": r["offer_id"],
        };
      }).toList();

      // ✅ Auto-select first offer if nothing selected
      if (selectedReward == null && items.isNotEmpty) {
        selectedReward = items[0]["title"];
        selectedOfferId = items[0]["offer_id"];
        isStarConnectSelected = true;
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return rewardCard(
                    title: item["title"].toString(),
                    count: item["count"].toString(),
                    index: index,
                    isStarConnect: true,
                    offerId: item["offer_id"] ?? 0,
                    clickable: true,
                  );
                },
              ),
            ),
            if (selectedReward != null)
              Padding(
                padding: const EdgeInsets.all(14),
                child: selectedOfferId != null
                    ? StarConnectMovieListScreen(
                        key: ValueKey(selectedOfferId),
                        offerId: selectedOfferId!,
                      )
                    : const SizedBox(),
              ),
          ],
        ),
      );
    } else {
      final items = [
        {
          "title": "Free Shares",
          "count": filmBitSummary["total_free_share"]?.toString() ?? "0",
        },
        {
          "title": "Platform Commission",
          "count": "${filmBitSummary["no_platform_commission_count"] ?? 0}",
        },
        {
          "title": "Profit Commission",
          "count": "${filmBitSummary["no_profit_commission_count"] ?? 0}",
        },
        {
          "title": "Wallet Cashback",
          "count":
              "₹${filmBitSummary["total_wallet_amount"]?.toStringAsFixed(2) ?? "0"}",
        },
        {
          "title": "Discount",
          "count":
              "₹${filmBitSummary["total_discount"]?.toStringAsFixed(2) ?? "0"}",
        },
      ];

      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return rewardCard(
                    title: item["title"].toString(),
                    count: item["count"].toString(),
                    index: index,
                    isStarConnect: false,
                    offerId: 0,
                    clickable: false,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: FilmBitMovieListScreen(),
            ),
          ],
        ),
      );
    }
  }

  Widget rewardCard({
    required String title,
    required String count,
    required int index,
    required bool isStarConnect,
    required int offerId,
    required bool clickable,
  }) {
    final icon = rewardIcons[title] ?? Icons.redeem;
    final Color baseColor = glassColors[index % glassColors.length].withOpacity(
      0.45,
    );

    final bool isSelected =
        selectedReward == title &&
        isStarConnectSelected == isStarConnect &&
        selectedOfferId == offerId;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: clickable
                ? () {
                    setState(() {
                      if (isSelected) {
                        selectedReward = null;
                        selectedOfferId = null;
                      } else {
                        selectedReward = title;
                        isStarConnectSelected = isStarConnect;
                        selectedOfferId = offerId;
                      }
                    });
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 190 : 165,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.4),
                  width: isSelected ? 2.2 : 1.2,
                ),
                color: Colors.black.withOpacity(0.10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(0.6),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                        ),
                        if (isSelected)
                          BoxShadow(
                            color: baseColor.withOpacity(0.9),
                            blurRadius: 32,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                      ],
                      border: Border.all(
                        color: baseColor.withOpacity(isSelected ? 1 : 0.5),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      color: baseColor.withOpacity(0.35),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: isSelected ? 38 : 32,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSelected ? 16 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: isSelected ? 22 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ✅ Tick icon for selected offer
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
            ),
        ],
      ),
    );
  }

  final List<Color> glassColors = [
    Color(0xFF6EE7B7), // Mint Green
    Color(0xFF93C5FD), // Soft Blue
    Color(0xFFFDA4AF), // Pink Rose
    Color(0xFFFCD34D), // Gold Yellow
    Color(0xFFA5B4FC), // Lavender
    Color(0xFFFF9F9F), // Peach
  ];
}
