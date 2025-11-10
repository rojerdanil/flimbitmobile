import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_buy.dart';
import '../theme/AppTheme.dart';

class WinnersSection extends StatefulWidget {
  const WinnersSection({super.key});

  @override
  State<WinnersSection> createState() => _WinnersSectionState();
}

class _WinnersSectionState extends State<WinnersSection> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> winners = [];
  bool isLoading = true;
  bool isFetchingMore = false;

  int offset = 0;
  final int limit = 5;
  bool hasMore = true;

  // 🎨 Light Multicolor Gradients for Cards
  final List<List<Color>> cardGradients = const [
    [Color(0xFFFFFDE7), Color(0xFFFFECB3)], // soft gold
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // sky blue
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // mint green
    [Color(0xFFFFEBEE), Color(0xFFFFCDD2)], // rose pink
    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)], // lavender
    [Color(0xFFFFF3E0), Color(0xFFFFCC80)], // peach
  ];

  @override
  void initState() {
    super.initState();
    _fetchWinners();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchWinners() async {
    setState(() => isLoading = true);
    await _loadWinners();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMore() async {
    if (!hasMore || isFetchingMore) return;
    setState(() => isFetchingMore = true);
    await _loadWinners();
    setState(() => isFetchingMore = false);
  }

  Future<void> _loadWinners() async {
    try {
      final payload = {"limit": limit, "offset": offset};
      final response = await ApiService.post(
        ApiEndpoints.winners,
        body: payload,
      );

      final List<dynamic> result = response ?? [];
      if (result.isNotEmpty) {
        setState(() {
          winners.addAll(List<Map<String, dynamic>>.from(result));
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
      debugPrint("⚠️ Error loading winners: $e");
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        hasMore) {
      _fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.5;

    if (isLoading && winners.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (winners.isEmpty) {
      return const Center(child: Text("No winners yet"));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 Header with underline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    "🎉 Congratulations to Our Winners!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 160,
                  child: Container(
                    height: 3,
                    color: AppTheme.primaryColor, // Theme underline
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 🏅 Horizontal list of winner cards
          SizedBox(
            height: 110,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: winners.length + (isFetchingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == winners.length) {
                  return const SizedBox(
                    width: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final winner = winners[index];
                final gradient =
                    cardGradients[index %
                        cardGradients.length]; // 🎨 Rotate colors

                return GestureDetector(
                  onTap: () {
                    final movieId = winner['movieId'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieBuyScreen(
                          movieId: movieId,
                          menu: 'Movie',
                          submenu: 'Winner',
                        ),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: cardWidth,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              (winner["profilePicUrl"] != null &&
                                  winner["profilePicUrl"].toString().isNotEmpty)
                              ? NetworkImage(winner["profilePicUrl"])
                              : const AssetImage("assets/default_user.png")
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 🏆 Offer title with shimmer gold gradient
                              Row(
                                children: [
                                  const Text(
                                    "🏆 ",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Flexible(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.primaryColor.withOpacity(
                                                0.6,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                      child: Text(
                                        winner["offerName"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                winner["userName"] ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                winner["movieName"] ?? "",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
