import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../HomeScreen/star_connect_all_filter_screen.dart';
import '../screens/movie_buy.dart';

class StarConnectZone extends StatefulWidget {
  const StarConnectZone({super.key});

  @override
  State<StarConnectZone> createState() => _StarConnectZoneState();
}

class _StarConnectZoneState extends State<StarConnectZone> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> starConnectItems = [];
  bool isLoading = true;
  bool isFetchingMore = false;

  int offset = 0;
  final int limit = 4;

  final List<String> randomIcons = ["🎬", "🎤", "🎁", "🎥", "⭐", "🎟️"];

  @override
  void initState() {
    super.initState();
    fetchStarConnectOffers();
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
        !isLoading) {
      fetchMoreStarConnectOffers();
    }
  }

  // 🌐 Fetch initial offers
  Future<void> fetchStarConnectOffers() async {
    setState(() => isLoading = true);
    await _fetchOffers();
    setState(() => isLoading = false);
  }

  // 🌐 Fetch more on scroll
  Future<void> fetchMoreStarConnectOffers() async {
    setState(() => isFetchingMore = true);
    await _fetchOffers();
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchOffers() async {
    try {
      final Map<String, dynamic> payload = {"offset": offset, "limit": limit};

      final response = await ApiService.post(
        ApiEndpoints.movieStarConnectOffer,
        body: payload,
      );

      if (response is List && response.isNotEmpty) {
        final random = Random();
        final List<Map<String, dynamic>> fetchedItems = response.map((offer) {
          final icon = randomIcons[random.nextInt(randomIcons.length)];
          return {
            "title": "$icon ${offer["title"] ?? ""}",
            "subtitle": offer["subtitle"] ?? "",
            "movie": offer["movieName"] ?? "",
            "image": offer["iconUrl"] ?? "",
            "date": offer["endDate"]?.toString().substring(0, 10) ?? "",
            "details": offer["details"] ?? "",
            "movieId": offer["movieId"] ?? 0,
          };
        }).toList();

        setState(() {
          starConnectItems.addAll(fetchedItems);
          offset += limit; // move to next page
        });
      }
    } catch (e) {
      debugPrint("⚠️ Exception while fetching offers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "🎟️ Star Connect Zone",
                        style: AppTheme.headline1,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 120,
                      child: Container(height: 3, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StarConnectAllScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // 🔸 Offer Cards with infinite scroll
          SizedBox(
            height: 290,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        starConnectItems.length + (isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == starConnectItems.length && isFetchingMore) {
                        return const SizedBox(
                          width: 60,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      if (index >= starConnectItems.length) {
                        return const SizedBox.shrink();
                      }

                      final item = starConnectItems[index];
                      return _buildLuxuryTicketCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 💎 Premium Ticket Card
  Widget _buildLuxuryTicketCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    return GestureDetector(
      onTap: () => _openFullScreenDetail(context, item),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _buildSmoothShimmerImage(item["image"] ?? "", 130),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _GoldTicketBorderPainter()),
            ),
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.amber.shade300,
                    highlightColor: Colors.white,
                    child: Text(
                      item["title"] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["subtitle"] ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "🎬 ${item["movie"] ?? ""}",
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orangeAccent],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "INVITED",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "📅 ${item["date"] ?? ""}",
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmoothShimmerImage(String imageUrl, double height) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, opacity, child) {
        return Stack(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade800,
              highlightColor: Colors.grey.shade600,
              child: Container(
                height: height,
                width: double.infinity,
                color: Colors.grey.shade700,
              ),
            ),
            Opacity(
              opacity: opacity,
              child: Image.network(
                imageUrl,
                height: height,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: height,
                    color: Colors.grey[850],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white30,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openFullScreenDetail(BuildContext context, Map<String, dynamic> item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: _buildSmoothShimmerImage(
                    item["image"] ?? "",
                    double.infinity,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: Colors.black.withOpacity(0.7)),
                  ),
                ),
                SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        expandedHeight: 300,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: _buildSmoothShimmerImage(
                            item["image"] ?? "",
                            300,
                          ),
                        ),
                        leading: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                item["title"] ?? "",
                                textAlign: TextAlign.center,
                                style: AppTheme.headline1.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "🎬 ${item["movie"] ?? ""}",
                                style: AppTheme.goldTitle,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "📅 ${item["date"] ?? ""}",
                                style: AppTheme.subtitle.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  item["details"] ?? "",
                                  style: AppTheme.subtitle.copyWith(
                                    color: Colors.black87,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieBuyScreen(
                                        movieId: item["movieId"],
                                        menu: 'Movie',
                                        submenu: 'Winner',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  elevation: 8,
                                ),
                                icon: const Icon(Icons.stars_rounded),
                                label: const Text(
                                  "Invest to Join",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
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
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// 🟡 Gold Border Painter
class _GoldTicketBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFFE082)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
