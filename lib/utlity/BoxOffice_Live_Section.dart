import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_buy.dart';
import '../theme/AppTheme.dart';
import '../screens/search_screen.dart';

class BoxOfficeLiveSection extends StatefulWidget {
  const BoxOfficeLiveSection({super.key});

  @override
  State<BoxOfficeLiveSection> createState() => _BoxOfficeLiveSectionState();
}

class _BoxOfficeLiveSectionState extends State<BoxOfficeLiveSection> {
  List<dynamic> movies = [];
  bool isLoading = true;

  int offset = 0;
  final int limit = 5;
  final ScrollController _scrollController = ScrollController();
  bool isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    fetchBoxOfficeMovies();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        !isLoading) {
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchMoreMovies() async {
    setState(() => isFetchingMore = true);
    await fetchBoxOfficeMovies();
    setState(() => isFetchingMore = false);
  }

  Future<void> fetchBoxOfficeMovies() async {
    try {
      final Map<String, dynamic> payload = {"offset": offset, "limit": limit};
      final result = await ApiService.post(
        ApiEndpoints.boxOfficeMovies,
        body: payload,
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          movies.addAll(result);
          isLoading = false;
          offset += limit;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error fetching BoxOffice movies: $e");
    }
  }

  int _getTopPerformerIndex() {
    int maxIndex = 0;
    double maxValue = 0;
    for (int i = 0; i < movies.length; i++) {
      final value = (movies[i]['investedAmount'] ?? 0).toDouble();
      if (value > maxValue) {
        maxValue = value;
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  double _getWeekProgress(String? status) {
    if (status == null) return 0.0;
    if (status.contains("Week 1")) return 0.25;
    if (status.contains("Week 2")) return 0.5;
    if (status.contains("Week 3")) return 0.75;
    if (status.contains("Week 4")) return 1.0;
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text("No Box Office movies available"),
        ),
      );
    }

    final topIndex = _getTopPerformerIndex();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header with underline
          // 🔹 Header with underline + View All
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 🎬 Title + underline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🎬 Box Office — Live",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 3,
                      width: 120,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),

                // 🔸 View All button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SearchScreen(initialType: "Box_Office"),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Horizontal scroll cards
          SizedBox(
            height: 230,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: movies.length + (isFetchingMore ? 1 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                if (index >= movies.length) {
                  return const SizedBox(
                    width: 160,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                final movie = movies[index];
                final progress = _getWeekProgress(movie['status']);

                return GestureDetector(
                  onTap: () {
                    final movieId = movie['id'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieBuyScreen(
                          movieId: movieId,
                          menu: 'News',
                          submenu: 'Collection Report',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      right: index == movies.length - 1 ? 0 : 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // 🎞 Poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            movie['posterUrl'] ?? '',
                            width: 160,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                          ),
                        ),

                        // 🏆 Top Performer Badge
                        if (index == topIndex)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Top Performer",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),

                        // 📊 Overlay info bottom
                        Positioned(
                          bottom: 10,
                          left: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "${movie['language'] ?? ''} • ${movie['movieTypeName'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white24,
                                    color: AppTheme.primaryColor,
                                    minHeight: 6,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
