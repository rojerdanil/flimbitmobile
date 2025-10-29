import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_view.dart';

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

  final List<List<Color>> gradients = const [
    [Color(0xFFFFF9C4), Color(0xFFFFECB3)], // yellow
    [Color(0xFFC8E6C9), Color(0xFFA5D6A7)], // green
    [Color(0xFFBBDEFB), Color(0xFF90CAF9)], // blue
    [Color(0xFFFFCCBC), Color(0xFFFFAB91)], // orange
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
      color: const Color(0xFFFFFDE7),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎉 Congratulations to Our Winners!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 100,
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
                final gradient = gradients[index % gradients.length];

                // 🟡 Added GestureDetector here 👇
                return GestureDetector(
                  onTap: () {
                    final movieId = winner['movieId'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieViewScreen(
                          movieId: movieId,
                          selectedMainTab: 'Movie',
                          selectedSubTab: 'Winner',
                        ),
                      ),
                    );
                    // Example navigation:
                    // Navigator.pushNamed(context, '/winner_detail', arguments: winnerId);
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
                              // 🏆 Offer name
                              Row(
                                children: [
                                  const Text(
                                    "🏆 ",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Flexible(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFFFE57F),
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
