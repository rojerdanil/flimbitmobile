import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/movie_view.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class RecommendedMovie extends StatefulWidget {
  const RecommendedMovie({super.key});

  @override
  State<RecommendedMovie> createState() => _RecommendedMovieState();
}

class _RecommendedMovieState extends State<RecommendedMovie> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> recommendedMovies = [];
  bool isLoading = true;
  bool isFetchingMore = false;

  int offset = 0;
  final int limit = 5;

  // Map to hold current offer index for each movie
  Timer? offerTimer;
  final Map<int, int> currentOfferIndex = {};
  final Map<int, bool> slideUp = {}; //

  @override
  void initState() {
    super.initState();
    _fetchRecommendedMovies();
    _scrollController.addListener(_onScroll);

    // Start auto-scrolling offers every 2 seconds
    offerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < recommendedMovies.length; i++) {
          final offers = List<Map<String, dynamic>>.from(
            recommendedMovies[i]["starOfferList"] ?? [],
          );
          if (offers.isEmpty) continue;
          currentOfferIndex[i] =
              ((currentOfferIndex[i] ?? 0) + 1) % offers.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    offerTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        !isLoading) {
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchRecommendedMovies() async {
    setState(() => isLoading = true);
    await _fetchMovies();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreMovies() async {
    setState(() => isFetchingMore = true);
    await _fetchMovies();
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchMovies() async {
    try {
      final Map<String, dynamic> payload = {"offset": offset, "limit": limit};
      final result = await ApiService.post(
        ApiEndpoints.recommandedMovie,
        body: payload,
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          recommendedMovies.addAll(List<Map<String, dynamic>>.from(result));
          if (result.length >= limit) offset += (limit - 1);
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching movies: $e");
    }
  }

  double _getProgress(double invested, double budget) {
    if (budget <= 0) return 0.0;
    return (invested / budget).clamp(0.0, 1.0);
  }

  Color _getOfferColor(String offer) {
    switch (offer) {
      case 'Act in Movie':
        return Colors.deepPurple;
      case 'Premium Ticket':
        return Colors.orange;
      case 'Free Ticket':
        return Colors.green;
      case 'No Profit Commission':
      case 'No Platform Commission':
        return Colors.blueAccent;
      default:
        return Colors.redAccent;
    }
  }

  String? _getReleaseCountdown(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return null;
    try {
      final date = DateTime.parse(releaseDate);
      final now = DateTime.now();
      final diff = date.difference(now).inDays;
      if (diff > 0) return "Releasing in $diff days";
      return null;
    } catch (_) {
      return null;
    }
  }

  void _onMovieTap(BuildContext context, int movieId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieViewScreen(movieId: movieId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading && recommendedMovies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendedMovies.isEmpty) {
      return const Center(child: Text("No recommended movies available"));
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
                const Text(
                  "Recommended Movies",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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

          // Horizontal movie cards
          SizedBox(
            height: 320,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: recommendedMovies.length + (isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == recommendedMovies.length) {
                  return const SizedBox(
                    width: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final movieData = recommendedMovies[index];
                final movie = movieData["movie"];
                final starOffers = List<Map<String, dynamic>>.from(
                  movieData["starOfferList"] ?? [],
                );

                final progress = _getProgress(
                  (movie["investedAmount"] ?? 0).toDouble(),
                  (movie["budget"] ?? 1).toDouble(),
                );

                final releaseCountdown = _getReleaseCountdown(
                  movie["releaseDate"],
                );

                final cardWidth = screenWidth * 0.45;

                // Current offer index for this movie
                final offerIndex = currentOfferIndex[index] ?? 0;
                final currentOffer = starOffers.isNotEmpty
                    ? starOffers[offerIndex]["value"] ?? ""
                    : "";

                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(
                    right: index == recommendedMovies.length - 1 ? 0 : 16,
                  ),
                  child: GestureDetector(
                    onTap: () => _onMovieTap(context, movie["id"]),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 200,
                                width: cardWidth,
                                child: Image.network(
                                  movie["posterUrl"] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey.shade300),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Animated offer
                              if (starOffers.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: currentOffer.isNotEmpty
                                        ? Container(
                                            key: ValueKey<String>(currentOffer),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getOfferColor(
                                                currentOffer,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              currentOffer,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              // Release countdown
                              if (releaseCountdown != null)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      releaseCountdown,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  movie["title"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  movie["movieTypeName"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade300,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₹${movie["investedAmount"] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "₹${movie["budget"] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    final movieId = movie["id"];
                                    if (movieId != null && movieId != 0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MovieViewScreen(movieId: movieId),
                                        ),
                                      );
                                    } else {
                                      debugPrint(
                                        "⚠️ Invalid movieId, skipping navigation",
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                  child: Text(
                                    "Invest ₹${movie["perShareAmount"] ?? 0}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
