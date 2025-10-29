import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

// Import your other widget files
import '../screens/movie_buy.dart';
import '../screens/movie_view_top_invester.dart';
import '../screens/movie_view_top_proftit_holder.dart';
import '../screens/movie_view_offers_start_connect.dart';
import '../screens/movie_view_flimBit_offer.dart';
import '../screens/movie_view_cinema_news.dart';
import '../screens/movie_view_cinema_collection.dart';
import '../screens/movie_view_transection.dart';
import '../screens/movie_view_winners.dart';
import '../screens/actors.dart';

class MovieViewScreen extends StatefulWidget {
  final int movieId;

  /// 🔹 Optional: auto-select main & sub tab on open
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
  late String selectedMainTab;
  late String selectedSubTab;
  String selectedOfferSubTab = 'Star Connect';
  String selectedNewsSubTab = 'Cinema';

  final PageController _offerController = PageController();
  Timer? _offerTimer;
  bool isLoading = true;
  Map<String, dynamic>? movie;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 🔸 For badges
  final int numberOfUsers = 12800;
  final int investedAmount = 25600000;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 🔹 Initialize with passed-in or default tabs
    selectedMainTab = widget.selectedMainTab ?? 'Movie';
    selectedSubTab = widget.selectedSubTab ?? 'Actors';

    fetchMovieDetails();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _offerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_offerController.hasClients &&
          movie != null &&
          (movie!['offers'] ?? []).isNotEmpty) {
        final offers = movie!['offers'] as List;
        final nextPage =
            ((_offerController.page?.round() ?? 0) + 1) % offers.length;
        _offerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
          movie!['news'] = [
            "Trailer released today!",
            "Movie shooting completed!",
          ];
        });
      }
    } catch (e) {
      debugPrint("Error fetching movie details: $e");
    }
    setState(() => isLoading = false);
    _fadeController.forward(from: 0);
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _offerController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // 🔸 Format numbers
  String formatIndianNumber(int value) {
    if (value >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(2)} Cr";
    } else if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(2)} L";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    } else {
      return value.toString();
    }
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

    final invested = (movie!['investedAmount'] as num).toDouble();
    final budget = (movie!['budget'] as num).toDouble();
    final progress = (invested / budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        title: Text(movie!['title'] ?? 'Movie', style: AppTheme.headline1),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildBadgeRow(compact: true),
          ),
        ],
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
                  const SizedBox(height: 8),
                  _buildPosterSection(progress, invested, budget),
                  const SizedBox(height: 10),
                  _buildInfoSection(),
                  const SizedBox(height: 16),
                  _buildMainTabs(),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _buildDynamicSubTabs(),
                  ),
                  const SizedBox(height: 16),
                  _buildTabContentContainer(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
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
          ),
        ],
      ),
    );
  }

  // ✅ Rest of your original design untouched
  // (all functions below remain exactly the same)

  Widget _buildBadgeRow({bool compact = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildBadge(
        Icons.people,
        numberOfUsers,
        Colors.amber.shade700,
        compact: compact,
      ),
      const SizedBox(width: 8),
      _buildBadge(
        Icons.monetization_on,
        investedAmount,
        Colors.green.shade600,
        compact: compact,
      ),
    ],
  );

  Widget _buildBadge(
    IconData icon,
    int value,
    Color color, {
    bool compact = false,
  }) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(seconds: 2),
              builder: (context, val, child) => Text(
                formatIndianNumber(val),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterSection(double progress, double invested, double budget) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                movie!['posterUrl'] ?? "",
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Icon(
                Icons.play_circle_fill,
                color: Colors.white.withOpacity(0.9),
                size: 70,
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          color: AppTheme.primaryColor,
                          backgroundColor: Colors.white30,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Raised: ₹${invested.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Goal: ₹${budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoSection() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Release: ${movie!['releaseDate'] ?? 'Coming Soon'}   '
            'Trailer: ${movie!['trailerDate'] ?? 'Coming Soon'}',
            style: AppTheme.headline2,
          ),
          const SizedBox(height: 8),
          Text(
            'Genre: ${movie!['movieTypeName']} • ${movie!['language']}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text(
            movie!['description'] ?? "",
            style: const TextStyle(
              color: Colors.black87,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );

  // ✅ All remaining code unchanged (mainTabs, subTabs, getTabContent, etc.)
  // Tabs (rest of your code remains unchanged below)
  Widget _buildMainTabs() {
    final tabs = ['Movie', 'Offers', 'News', 'Transection'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedMainTab == tab;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedMainTab = tab;
                selectedSubTab = 'Actors';
                _fadeController.forward(from: 0);
              });
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

  Widget _buildDynamicSubTabs() {
    if (selectedMainTab == 'Movie') {
      return _buildSubTabBar(
        ['Actors', 'Top Investor', 'Profit Holder', 'Winner'],
        selectedSubTab,
        (tab) => setState(() => selectedSubTab = tab),
      );
    } else if (selectedMainTab == 'Offers') {
      return _buildSubTabBar(
        ['Star Connect', 'FlimBit'],
        selectedOfferSubTab,
        (tab) => setState(() => selectedOfferSubTab = tab),
      );
    } else if (selectedMainTab == 'News') {
      // Directly handle sub-tab selection
      return _buildSubTabBar(
        ['Cinema', 'Collection Report'],
        selectedSubTab, // Use selectedSubTab directly here
        (tab) => setState(() => selectedSubTab = tab), // Update selectedSubTab
      );
    }
    return const SizedBox();
  }

  Widget _buildSubTabBar(
    List<String> tabs,
    String selected,
    Function(String) onTap,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 40),
          ...tabs.map((tab) {
            final isSelected = selected == tab;
            return GestureDetector(
              onTap: () => onTap(tab), // Update the selected tab
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(width: 40), // Right padding for symmetry
        ],
      ),
    );
  }

  // 🧩 Tab Content
  Widget _buildTabContentContainer() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
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
        child: getTabContent(),
      ),
    );
  }

  Widget getTabContent() {
    switch (selectedMainTab) {
      case 'Offers':
        return selectedOfferSubTab == 'Star Connect'
            ? StartOfferScreen(movieId: widget.movieId)
            : FilmBitOfferScreen(movieId: widget.movieId);
      case 'Transection':
        return TransactionReportScreen(movieId: widget.movieId);
      case 'News':
        // Don't overwrite selectedNewsSubTab here, use selectedSubTab directly
        return selectedSubTab == 'Cinema'
            ? CinemaNewsScreen(movieId: widget.movieId)
            : CollectionReportScreen(movieId: widget.movieId);
      case 'Movie':
      default:
        switch (selectedSubTab) {
          case 'Actors':
            return ActorsSection(movieId: widget.movieId);
          case 'Top Investor':
            return TopInvestorsSection(movieId: widget.movieId);
          case 'Profit Holder':
            return TopProfitHoldersSection(movieId: widget.movieId);
          case 'Winner':
            return StartOfferScreenWinner(movieId: widget.movieId);
          default:
            return const SizedBox();
        }
    }
  }
}
