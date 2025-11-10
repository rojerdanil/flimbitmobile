import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/movie_buy.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class CinemaBuzz extends StatefulWidget {
  const CinemaBuzz({super.key});

  @override
  State<CinemaBuzz> createState() => _CinemaBuzzState();
}

class _CinemaBuzzState extends State<CinemaBuzz> {
  final ScrollController _scrollController = ScrollController();

  List<dynamic> trendingMovies = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int offset = 0;
  final int limit = 3;

  @override
  void initState() {
    super.initState();
    _fetchCinemaBuzzMovies();
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
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchCinemaBuzzMovies() async {
    try {
      setState(() => isLoading = true);

      final response = await ApiService.post(
        ApiEndpoints.cinemaBuzzMovies,
        body: {"offset": offset.toString(), "limit": limit.toString()},
      );

      if (response != null && response is List) {
        setState(() {
          trendingMovies = response;
          isLoading = false;
          if (response.length >= limit) offset += (limit - 1);
        });
      } else {
        setState(() {
          trendingMovies = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Cinema Buzz movies: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchMoreMovies() async {
    setState(() => isFetchingMore = true);
    try {
      final response = await ApiService.post(
        ApiEndpoints.cinemaBuzzMovies,
        body: {"offset": offset.toString(), "limit": limit.toString()},
      );

      if (response != null && response is List && response.isNotEmpty) {
        setState(() {
          trendingMovies.addAll(response);
          if (response.length >= limit) offset += (limit - 1);
        });
      }
    } catch (e) {
      debugPrint("Error fetching more Cinema Buzz movies: $e");
    }
    setState(() => isFetchingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "🔥 Cinema Buzz",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 60,
                      child: Container(height: 4, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Movies creating the biggest hype this week",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 10),

          // 🔸 Data / Loader / Empty
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (trendingMovies.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No trending movies found"),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trendingMovies.length + (isFetchingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == trendingMovies.length && isFetchingMore) {
                    return const SizedBox(
                      width: 60,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (index >= trendingMovies.length) {
                    return const SizedBox.shrink();
                  }

                  final movie = trendingMovies[index];
                  return _buildTrendingCard(context, movie);
                },
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 Trending Movie Card
  Widget _buildTrendingCard(BuildContext context, Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieBuyScreen(movieId: movie["movieid"]),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16, bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎬 Poster + Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    movie["image"] ?? "",
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          Colors.orangeAccent.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      movie["tag"] ?? "",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🎞️ Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie["title"] ?? "",
                    style: AppTheme.headline2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie["description"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: Text(
                          "ROI ${movie["roi"]}%",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.trending_up_rounded,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Invest Now",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
