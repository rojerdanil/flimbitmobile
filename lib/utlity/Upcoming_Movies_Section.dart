import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart'; // Import your AppTheme
import '../screens/movie_view.dart';

class UpcomingMoviesSection extends StatefulWidget {
  const UpcomingMoviesSection({super.key});

  @override
  State<UpcomingMoviesSection> createState() => _UpcomingMoviesSectionState();
}

class _UpcomingMoviesSectionState extends State<UpcomingMoviesSection> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> upcomingMovies = [];
  bool isLoading = true;
  bool isFetchingMore = false;

  int offset = 0;
  final int limit = 5;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingMovies();
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
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchUpcomingMovies() async {
    setState(() => isLoading = true);
    await _fetchMovies();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreMovies() async {
    if (!hasMore) return;
    setState(() => isFetchingMore = true);
    await _fetchMovies();
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchMovies() async {
    try {
      final payload = {"offset": offset, "limit": limit};
      final result = await ApiService.post(
        ApiEndpoints.upcommingMovies,
        body: payload,
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          upcomingMovies.addAll(List<Map<String, dynamic>>.from(result));
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
      debugPrint("Error fetching upcoming movies: $e");
    }
  }

  Map<String, dynamic> getDaysLeftInfo(String? releaseDateStr) {
    if (releaseDateStr == null || releaseDateStr.isEmpty) {
      return {"text": "Coming Soon", "type": "coming"};
    }

    try {
      final releaseDate = DateTime.parse(releaseDateStr);
      final difference = releaseDate.difference(DateTime.now()).inDays;

      if (difference <= 0) return {"text": "Today", "type": "today"};
      if (difference <= 7)
        return {"text": "$difference days left", "type": "soon"};
      return {"text": "$difference days left", "type": "later"};
    } catch (_) {
      return {"text": "Coming Soon", "type": "coming"};
    }
  }

  LinearGradient getBadgeGradient(String type) {
    switch (type) {
      case "today":
        return const LinearGradient(
          colors: [Colors.redAccent, Colors.deepOrange],
        );
      case "soon":
        return const LinearGradient(colors: [Colors.orange, Colors.amber]);
      default:
        return const LinearGradient(colors: [Colors.grey, Colors.blueGrey]);
    }
  }

  String formatBudgetIndian(num? amount) {
    if (amount == null || amount <= 0) return "₹0";

    if (amount >= 10000000) {
      double crores = amount / 10000000;
      return "₹${crores.toStringAsFixed(2)} Cr";
    } else if (amount >= 100000) {
      double lakhs = amount / 100000;
      return "₹${lakhs.toStringAsFixed(2)} L";
    } else {
      return "₹${amount.toStringAsFixed(0)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final double posterWidth = 140;
    final double posterHeight = 180;

    if (isLoading && upcomingMovies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (upcomingMovies.isEmpty) {
      return const Center(child: Text("No upcoming movies"));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Upcoming Movies", style: AppTheme.headline1),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "View All",
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal movie carousel
          SizedBox(
            height: posterHeight + 90,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: upcomingMovies.length + (isFetchingMore ? 1 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                if (index == upcomingMovies.length) {
                  return const SizedBox(
                    width: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final movie = upcomingMovies[index];
                final daysInfo = getDaysLeftInfo(movie['releaseDate']);
                final badgeGradient = getBadgeGradient(daysInfo['type']);

                return GestureDetector(
                  onTap: () {
                    // 👇 Handle the click here
                    final movieId = movie['id'];
                    debugPrint("Clicked on movie ID: $movieId");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieViewScreen(movieId: movieId),
                      ),
                    );
                    // Example: Navigate to movie detail screen
                    // Navigator.pushNamed(context, '/movie_detail', arguments: movieId);
                  },
                  child: Container(
                    width: posterWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: movie['posterUrl'] != null
                                  ? Image.network(
                                      movie['posterUrl'],
                                      width: posterWidth,
                                      height: posterHeight,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: posterWidth,
                                      height: posterHeight,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.movie, size: 40),
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: badgeGradient,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      daysInfo['text'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie['title'] ?? '',
                          style: AppTheme.headline2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          movie['movieTypeName'] ?? '',
                          style: AppTheme.headline1.copyWith(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.primaryColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatBudgetIndian(movie['budget']),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
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
