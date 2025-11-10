import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart';
import '../screens/movie_buy.dart';

class TopProfitHolderSection extends StatefulWidget {
  const TopProfitHolderSection({super.key});

  @override
  State<TopProfitHolderSection> createState() =>
      _TopProfitHolderGlassSectionState();
}

class _TopProfitHolderGlassSectionState extends State<TopProfitHolderSection> {
  List<dynamic> profitHolders = [];
  bool isLoading = true;
  bool hasMore = true;
  int offset = 0;
  final int limit = 5;

  // 🎨 Light gradient colors for variety
  final List<List<Color>> cardGradients = const [
    [Color(0xFFFFF9E5), Color(0xFFFFECB3)], // Gold
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // Blue
    [Color(0xFFFFEBEE), Color(0xFFFFCDD2)], // Pink
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // Green
    [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], // Orange
  ];

  @override
  void initState() {
    super.initState();
    fetchTopProfitHolders();
  }

  Future<void> fetchTopProfitHolders() async {
    try {
      final input = {"limit": limit, "offset": offset};
      final result = await ApiService.post(
        ApiEndpoints.topProfitHolders,
        body: input,
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          profitHolders.addAll(result);
          offset += result.length;
          if (result.length < limit) hasMore = false;
        });
      } else {
        setState(() => hasMore = false);
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching top profit holders: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.32;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header with underline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    "💎 Top Profit Holders",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 160,
                  child: Container(height: 3, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 🔹 Content Section
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (profitHolders.isEmpty)
            const Center(child: Text("No profit holders found."))
          else
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: profitHolders.length,
                itemBuilder: (context, index) {
                  final holder = profitHolders[index];
                  final invested = (holder['totalInvested'] ?? 0).toDouble();
                  final returned = (holder['totalReturned'] ?? 0).toDouble();
                  final profit = returned - invested;
                  final roi = invested > 0 ? (profit / invested) * 100 : 0.0;
                  final gradient = cardGradients[index % cardGradients.length];

                  return _buildGradientCard(
                    holder,
                    index,
                    cardWidth,
                    invested,
                    profit,
                    roi,
                    gradient,
                    context,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // 🟡 Gradient Glass Card
  Widget _buildGradientCard(
    Map<String, dynamic> holder,
    int index,
    double cardWidth,
    double invested,
    double profit,
    double roi,
    List<Color> gradient,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _openDetailPopup(context, holder, invested, profit, roi),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.only(right: 14),
        width: cardWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      holder['profilePicUrl'] ??
                          'https://via.placeholder.com/150',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    holder['userName'] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${invested.toStringAsFixed(0)} → ₹${(invested + profit).toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.9),
                          Colors.amber.shade300,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "+${roi.toStringAsFixed(1)}% ROI",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "#${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💎 Popup for profit details
  void _openDetailPopup(
    BuildContext context,
    Map<String, dynamic> holder,
    double invested,
    double profit,
    double roi,
  ) async {
    List<dynamic> topMovies = [];
    bool isLoadingMovies = true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 🔹 Load movies on first build
            if (isLoadingMovies) {
              () async {
                try {
                  final response = await ApiService.get(
                    ApiEndpoints.userlatestProfitMovies,
                  );
                  if (response != null) {
                    setState(() {
                      topMovies = response ?? [];
                      isLoadingMovies = false;
                    });
                  } else {
                    setState(() => isLoadingMovies = false);
                  }
                } catch (e) {
                  debugPrint("⚠️ Error fetching top movies: $e");
                  setState(() => isLoadingMovies = false);
                }
              }();
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF9E5), Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          holder['profilePicUrl'] ??
                              'https://via.placeholder.com/150',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        holder['userName'] ?? "Investor",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "ROI: ${roi.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 💰 Summary box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Total Invested: ₹${invested.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Total Returned: ₹${(invested + profit).toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "🎬 Top 5 Movie Portfolio",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 🔄 Loading / Empty / Data
                      if (isLoadingMovies)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else if (topMovies.isEmpty)
                        const Text("No movie profits found.")
                      else
                        ...topMovies.map((movie) {
                          final profit = (movie['totalprofit'] ?? 0).toDouble();
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close popup
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MovieBuyScreen(movieId: movie['movieid']),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      movie['posterurl'] ??
                                          'https://via.placeholder.com/60',
                                      height: 45,
                                      width: 45,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          movie['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          movie['language'] ?? '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "+₹${profit.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        movie['lastprofitdate']
                                                ?.toString()
                                                .split('T')
                                                .first ??
                                            '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text("Close"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
