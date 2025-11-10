import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_buy.dart';

class ProducerSpotlight extends StatefulWidget {
  const ProducerSpotlight({super.key});

  @override
  State<ProducerSpotlight> createState() => _ProducerSpotlightState();
}

class _ProducerSpotlightState extends State<ProducerSpotlight> {
  List<Map<String, dynamic>> producers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducers();
  }

  Future<void> fetchProducers() async {
    final Map<String, dynamic> payload = {"offset": "0", "limit": "3"};

    try {
      final response = await ApiService.post(
        ApiEndpoints.topProdcutionCompany,
        body: payload,
      );

      if (response != null) {
        setState(() {
          producers = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching producers: $e");
      setState(() => isLoading = false);
    }
  }

  // 🔹 Fetch movies (full objects)
  Future<List<Map<String, dynamic>>> fetchTopMovies(int companyId) async {
    final payload = {
      "offset": "0",
      "limit": "4",
      "productionCompanyId": companyId,
    };

    try {
      final response = await ApiService.post(
        ApiEndpoints.readtopProdcutionCompanyMovies,
        body: payload,
      );

      if (response != null) {
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint("Error fetching top movies: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "🎬 Producer Spotlight",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 110,
                      child: Container(height: 3, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Horizontal List
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: producers.length,
              itemBuilder: (context, index) {
                final producer = producers[index];
                return _buildProducerCard(context, producer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducerCard(
    BuildContext context,
    Map<String, dynamic> producer,
  ) {
    return GestureDetector(
      onTap: () async {
        final topMovies = await fetchTopMovies(producer["id"]);
        _openFullScreenDetail(context, producer, topMovies);
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                producer["logo"] ?? "",
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    producer["name"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producer["films"] ?? "",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${producer["totalinvestment"] ?? 0}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
  }

  void _openFullScreenDetail(
    BuildContext context,
    Map<String, dynamic> producer,
    List<Map<String, dynamic>> topMovies,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    producer["logo"] ?? "",
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        expandedHeight: 300,
                        floating: false,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Image.network(
                            producer["logo"] ?? "",
                            fit: BoxFit.cover,
                          ),
                        ),
                        leading: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                producer["name"] ?? "",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹${producer["totalinvestment"] ?? 0}",
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                producer["highlight"] ?? "",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Top Movies",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (topMovies.isEmpty)
                                      const Text(
                                        "No top movies found",
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    for (final movie in topMovies)
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MovieBuyScreen(
                                                movieId: movie["movieid"],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  movie["posterUrl"] ??
                                                      movie["poster"] ??
                                                      "",
                                                  height: 60,
                                                  width: 60,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      movie["title"] ??
                                                          movie["movieName"] ??
                                                          "",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      "Investment: ₹${movie["totalInvestment"] ?? movie["totalinvestment"] ?? 0}",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                    if (movie["budget"] != null)
                                                      Text(
                                                        "Budget: ₹${movie["budget"]}",
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black45,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color: Colors.black45,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}
