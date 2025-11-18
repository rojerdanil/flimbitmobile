import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_buy.dart';

class StarConnectMovieListScreen extends StatefulWidget {
  final int offerId;

  const StarConnectMovieListScreen({super.key, required this.offerId});

  @override
  State<StarConnectMovieListScreen> createState() =>
      _StarConnectMovieListScreenState();
}

class _StarConnectMovieListScreenState
    extends State<StarConnectMovieListScreen> {
  List<Map<String, dynamic>> movies = [];
  int page = 0;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final payload = {
      "offset": page.toString(),
      "limit": "5",
      "starOfferId": widget.offerId.toString(),
    };

    final response = await ApiService.post(
      ApiEndpoints.reward_star_connect_movie_list,
      body: payload,
    );

    if (response != null && response is List) {
      setState(() {
        movies.addAll(List<Map<String, dynamic>>.from(response));
        if (response.length < 5) hasMore = false;
        page++;
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: movies.isEmpty ? 6 : movies.length + 1,
        itemBuilder: (_, index) {
          if (movies.isEmpty) return buildShimmerCard();

          if (index == movies.length) {
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox();
          }

          return buildMovieCard(movies[index]);
        },
      ),
    );
  }

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
          border: Border.all(
            color: Colors.yellow.shade700.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.shade700.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item["posterurl"].toString(),
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
                    item["movie_name"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  Text(
                    "Invested: ₹${item["total_invested"] ?? 0}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.yellow.shade800,
                    ),
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

  Widget buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
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

// Dummy MovieDetailScreen for navigation
