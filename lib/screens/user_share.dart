import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../HomeScreen/movie_sell_share_screen.dart';
import '../screens/movie_buy.dart';

class UserShareScreen extends StatefulWidget {
  final bool showAppBar;

  const UserShareScreen({super.key, this.showAppBar = false});

  @override
  State<UserShareScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<UserShareScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMoreData = true;

  Map<String, dynamic>? summary;
  List<Map<String, dynamic>> movies = [];
  int offset = 0;
  final int limit = 5;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    fetchSummary();
    fetchMovies();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        hasMoreData) {
      fetchMoreMovies();
    }
  }

  Future<void> fetchSummary() async {
    try {
      final response = await ApiService.get(ApiEndpoints.summary);
      if (response.isNotEmpty) {
        setState(() {
          summary = response;
        });
      }
    } catch (e) {
      debugPrint("Error fetching summary: $e");
    }
  }

  Future<void> fetchMovies() async {
    setState(() => isLoading = true);
    await _fetchMovies();
    setState(() => isLoading = false);
  }

  Future<void> fetchMoreMovies() async {
    setState(() => isFetchingMore = true);
    await _fetchMovies();
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchMovies() async {
    try {
      final Map<String, dynamic> payload = {"offset": offset, "limit": limit};
      final response = await ApiService.post(
        ApiEndpoints.userShare_movies,
        body: payload,
      );

      if (response is List && response.isNotEmpty) {
        final result = response;
        final List<Map<String, dynamic>> parsedMovies = [];

        for (var item in result) {
          final movie = item['movies'];
          final starOffers =
              (item['starOfferlist'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final filmBitOffers =
              (item['flimBitOfferlist'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          final combinedOffers = [...starOffers, ...filmBitOffers];

          parsedMovies.add({
            "title": movie['movieName'],
            "posterUrl": movie['posterUrl'],
            "genre": movie['movieType'],
            "language": "Tamil",
            "totalShares": movie['totalSharesPurchased'] ?? 0,
            "investedAmount": movie['totalInvestedAmount'] ?? 0,
            "returns": "${(movie['totalReturn'] ?? 10)}%",
            "offers": combinedOffers,
            "badge": combinedOffers.isNotEmpty ? "HOT" : "",
            "movieId": movie['movieId'],
          });
        }

        setState(() {
          movies.addAll(parsedMovies);
          if (result.length < limit) {
            hasMoreData = false;
          } else {
            offset += limit;
          }
        });
      } else {
        setState(() => hasMoreData = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching movies: $e");
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      offset = 0;
      hasMoreData = true;
      movies.clear();
    });
    await fetchSummary();
    await fetchMovies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Color getROIColor(double roi) {
    if (roi >= 12) return Colors.green;
    if (roi >= 8) return Colors.orange;
    return Colors.red;
  }

  Color getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ✅ Conditional AppBar
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppTheme.primaryColor,
              title: const Text("Your Shares"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,

      body: isLoading && movies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Section (same as your existing code)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryColumn(
                            label: "Total Invested",
                            value:
                                "₹${summary?['totalInvested']?.toStringAsFixed(2) ?? '0'}",
                            icon: Icons.attach_money,
                          ),
                          _buildSummaryColumn(
                            label: "Ongoing Funds",
                            value:
                                "₹${summary?['ongoingFunds']?.toStringAsFixed(2) ?? '0'}",
                            icon: Icons.trending_up,
                          ),
                          _buildROISummary(
                            summary?['averageRoi']?.toDouble() ?? 0.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Movie List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.primaryColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: movies.length + (isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == movies.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final movie = movies[index];
                        return _buildMovieCard(movie);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Column(
      children: [
        if (icon != null) Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildROISummary(double roi) {
    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: (roi / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(getROIColor(roi)),
              ),
              Center(
                child: Text(
                  "${roi.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: getROIColor(roi),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text("ROI", style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final invested = (movie['investedAmount'] ?? 0).toDouble();
    final totalShares = (movie['totalShares'] ?? 0).toDouble();
    final progress = totalShares == 0 ? 0.0 : invested / (totalShares * 1000);
    final offers = (movie['offers'] as List).cast<String>();
    final roiValue =
        double.tryParse(movie['returns'].toString().replaceAll('%', '')) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with ROI and Progress
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    movie['posterUrl'],
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),

                // ROI top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ROI: ${roiValue.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                // Progress bar bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Colors.grey[400],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getProgressColor(progress),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Info Section below poster
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          movie['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if ((movie['badge'] ?? "").isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie['genre']} • ${movie['language']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),

                  // Invested amount separated
                  Text(
                    'Invested: ₹$invested',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Offers
                  if (offers.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: offers
                          .map(
                            (offer) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    offer,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MovieSellShareScreen(
                                  movieId: movie['movieId'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Sell'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MovieBuyScreen(movieId: movie['movieId']),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Buy'),
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
