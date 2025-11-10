import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_menu_controller.dart';
import '../screens/movie_buy.dart';

class MovieViewScreen extends StatefulWidget {
  final int movieId;
  final String? selectedMainTab;
  final String? selectedSubTab;

  const MovieViewScreen({
    super.key,
    required this.movieId,
    this.selectedMainTab,
    this.selectedSubTab,
  });

  @override
  State<MovieViewScreen> createState() => _MovieViewScreenState();
}

class _MovieViewScreenState extends State<MovieViewScreen>
    with TickerProviderStateMixin {
  final MovieMenuController menuController = MovieMenuController();

  bool isLoading = true;
  Map<String, dynamic>? movie;
  int numberOfUsers = 0;
  double investedAmount = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(_pulseController);
  }

  Future<void> fetchMovieDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(
        "${ApiEndpoints.movieView}${widget.movieId}",
      );
      final offersResponse = await ApiService.get(
        "${ApiEndpoints.movieOffers}${widget.movieId}",
      );

      if (response != null) {
        setState(() {
          movie = response;
          movie!['offers'] = offersResponse ?? [];
        });
        await fetchInvestmentSummary();
      }
    } catch (e) {
      debugPrint("Error fetching movie details: $e");
    }
    setState(() => isLoading = false);
    _fadeController.forward(from: 0);
  }

  Future<void> fetchInvestmentSummary() async {
    try {
      final response = await ApiService.get(
        "${ApiEndpoints.movieInvestCountSummary}${widget.movieId}",
      );
      if (response != null) {
        final countData = response['countData'];
        setState(() {
          numberOfUsers = countData?['userCount'] ?? 0;
          investedAmount =
              (countData?['totalInvested'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching invest summary: $e");
    }
  }

  String formatIndianNumber(num value) {
    if (value >= 10000000) return "${(value / 10000000).toStringAsFixed(2)} Cr";
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(2)} L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
    return value.toString();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (movie == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load movie details")),
      );
    }

    final invested = (movie!['investedAmount'] as num?)?.toDouble() ?? 0.0;
    final budget = (movie!['budget'] as num?)?.toDouble() ?? 1;
    final progress = (invested / budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(movie!['title'] ?? 'Movie', style: AppTheme.headline1),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPosterSection(),
                  const SizedBox(height: 12),
                  _buildBadgesSection(progress),
                  const SizedBox(height: 8),
                  _buildMainTabs(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: menuController.buildSubTabBar(() => setState(() {})),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: menuController.getTabContent(widget.movieId),
                  ),
                ],
              ),
            ),
          ),
          _buyButton(),
        ],
      ),
    );
  }

  // ---------------- Poster Section ----------------
  Widget _buildPosterSection() {
    final bannerUrl =
        movie?['bannerUrl'] ?? movie?['banner'] ?? movie?['posterUrl'] ?? '';
    final posterUrl =
        movie?['posterUrl'] ?? movie?['poster'] ?? movie?['bannerUrl'] ?? '';

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 240,
          child: Image.network(
            bannerUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Icon(Icons.movie, size: 60, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  posterUrl,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 140,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: Text(
                  movie?['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Badges Section ----------------
  Widget _buildBadgesSection(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _badge(
                  Icons.people,
                  'Users',
                  formatIndianNumber(numberOfUsers),
                ),
                _badge(
                  Icons.currency_rupee,
                  'Invested',
                  "₹${formatIndianNumber(investedAmount)}",
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: AppTheme.primaryColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(progress * 100).toStringAsFixed(1)}% funded",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade200.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Tabs Section ----------------
  Widget _buildMainTabs() {
    final tabs = ['Movie', 'Offers', 'News', 'Transection'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = menuController.selectedMainTab == tab;
          return GestureDetector(
            onTap: () {
              setState(() => menuController.selectMainTab(tab));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- Buy Button ----------------
  Widget _buyButton() => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieBuyScreen(movieId: widget.movieId),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Buy Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    ),
  );
}
