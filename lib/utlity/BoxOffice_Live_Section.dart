import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_view.dart';

class BoxOfficeLiveSection extends StatefulWidget {
  const BoxOfficeLiveSection({super.key});

  @override
  State<BoxOfficeLiveSection> createState() => _BoxOfficeLiveSectionState();
}

class _BoxOfficeLiveSectionState extends State<BoxOfficeLiveSection> {
  List<dynamic> movies = [];
  bool isLoading = true;

  static const Color primaryColor = Color(0xFFFFD700); // gold accent
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
          child: CircularProgressIndicator(color: primaryColor),
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Box Office — Live",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scroll cards
          SizedBox(
            height: 220,
            child: ListView.builder(
              controller: _scrollController, // ✅ important
              scrollDirection: Axis.horizontal,
              itemCount: movies.length + (isFetchingMore ? 1 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                if (index >= movies.length) {
                  // Loader for more items
                  return const SizedBox(
                    width: 160,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    ),
                  );
                }

                final movie = movies[index];
                final posterUrl = movie['posterUrl'] ?? '';
                final progress = _getWeekProgress(movie['status']);
                return GestureDetector(
                  onTap: () {
                    final movieId = movie['id'];
                    debugPrint("🎬 Clicked on movie ID: $movieId");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieViewScreen(
                          movieId: movieId,
                          selectedMainTab: 'News',
                          selectedSubTab: 'Collection Report',
                        ),
                      ),
                    );
                    // Example navigation:
                    // Navigator.pushNamed(context, '/movie_detail', arguments: movieId);
                  },
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      right: index == movies.length - 1 ? 0 : 12,
                    ),
                    child: Stack(
                      children: [
                        // Poster image
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
                                color: primaryColor.withOpacity(0.85),
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

                        // 🎬 Overlay info (bottom)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  movie['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  movie['movieTypeName'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  movie['language'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _getWeekProgress(movie['status']),
                                  backgroundColor: Colors.white24,
                                  color: primaryColor,
                                  minHeight: 6,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
