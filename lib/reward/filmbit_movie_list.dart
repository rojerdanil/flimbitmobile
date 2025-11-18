import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_buy.dart';

class FilmBitMovieListScreen extends StatefulWidget {
  const FilmBitMovieListScreen({super.key});

  @override
  State<FilmBitMovieListScreen> createState() => _FilmBitMovieListScreenState();
}

class _FilmBitMovieListScreenState extends State<FilmBitMovieListScreen> {
  List<Map<String, dynamic>> movies = [];
  bool isLoading = false;
  bool hasMore = true;

  int offset = 0;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final payload = {"offset": offset.toString(), "limit": limit.toString()};

    final response = await ApiService.post(
      ApiEndpoints.reward_filmbit_movie_list,
      body: payload,
    );

    if (response != null && response is List) {
      setState(() {
        movies.addAll(List<Map<String, dynamic>>.from(response));
        if (response.length < limit) hasMore = false;
        offset += limit;
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && movies.isEmpty) {
      return Column(children: List.generate(6, (_) => buildShimmerCard()));
    }

    if (!isLoading && movies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_outlined,
                size: 60,
                color: Colors.yellow.shade700,
              ),
              const SizedBox(height: 12),
              Text(
                "No Records Available",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent) {
          loadMovies();
        }
        return true;
      },
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: movies.length + 1,
        itemBuilder: (_, index) {
          if (index == movies.length) {
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox();
          }

          final item = movies[index];
          return buildMovieCard(item);
        },
      ),
    );
  }

  // ---------------- Movie Card ----------------
  Widget buildMovieCard(Map<String, dynamic> item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        final movieId = item["movie_id"];
        if (movieId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MovieBuyScreen(movieId: movieId)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.yellow.shade700.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item["poster"].toString(),
                width: 90,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["movie_title"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (item["status"] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item["status"]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item["status"] ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildTotalChip(
                        Icons.card_giftcard,
                        "Free Shares",
                        item["total_free_share"].toString(),
                      ),
                      _buildTotalChip(
                        Icons.percent,
                        "Platform Commission",
                        "${item["no_platform_commission_count"]}",
                      ),
                      _buildTotalChip(
                        Icons.trending_up,
                        "Profit Commission",
                        "${item["no_profit_commission_count"]}",
                      ),
                      _buildTotalChip(
                        Icons.account_balance_wallet,
                        "Wallet",
                        "₹${item["total_wallet_amount"]}",
                      ),
                      _buildTotalChip(
                        Icons.local_offer,
                        "Discount",
                        "₹${item["total_discount"]}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.yellow.shade700.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            "$label: $value",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 130,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "Won":
        return Colors.green.shade600;
      case "Pending":
        return Colors.orange.shade700;
      case "Lost":
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

// Dummy MovieDetailScreen
