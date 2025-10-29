import 'dart:async';
import 'package:flutter/material.dart';
import 'actors.dart';
import '../theme/AppTheme.dart';
import '../screens/movie_view_top_invester.dart';
import '../screens/movie_view_top_proftit_holder.dart';
import '../screens/movie_view_offers_start_connect.dart';
import '../screens/movie_view_flimBit_offer.dart';
import '../screens/movie_view_cinema_news.dart';
import '../screens/movie_view_cinema_collection.dart';
import '../screens/movie_view_transection.dart';
import '../screens/movie_view_winners.dart';
import '../screens/movie_buy.dart';

class MovieUserShareViewScreen extends StatefulWidget {
  final int movieId;

  const MovieUserShareViewScreen({super.key, required this.movieId});

  @override
  State<MovieUserShareViewScreen> createState() => _MovieViewScreenState();
}

class _MovieViewScreenState extends State<MovieUserShareViewScreen> {
  String selectedMainTab = 'Movie';
  String selectedSubTab = 'Actors';
  String selectedOfferSubTab = 'Star Connect'; // Offer sub-tab state
  String selectedNewsSubTab = 'Cinema'; // News sub-tab state

  final PageController _offerController = PageController();
  Timer? _offerTimer;

  @override
  void initState() {
    super.initState();

    // Auto-scroll offers every 3 seconds
    _offerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_offerController.hasClients) {
        final pageCount = (movie['offers'] as List).length;
        final nextPage = (_offerController.page?.round() ?? 0) + 1;
        _offerController.animateToPage(
          nextPage % pageCount,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _offerController.dispose();
    super.dispose();
  }

  // Mock movie data
  final movie = {
    "title": "Rise of Dragon",
    "posterUrl": "assets/poster1.jpg",
    "releaseDate": "2026-02-11",
    "trailerDate": "2025-07-12",
    "movieTypeName": "Action",
    "language": "Tamil",
    "budget": 1000000,
    "investedAmount": 650000,
    "offers": ["Act in Movie", "Premium Show", "Star Connect", "FlimBit"],
    "news": ["Trailer released today!", "Movie shooting completed!"],
    "topInvestor": ["Investor One", "Investor Two"],
    "profitHolder": ["User A", "User B"],
    "winner": ["Winner X", "Winner Y"],
    "description":
        "Rise of Dragon is an action-packed movie with thrilling sequences and a captivating story.",
  };

  @override
  Widget build(BuildContext context) {
    final investedAmount = (movie['investedAmount'] as num).toDouble();
    final budget = (movie['budget'] as num).toDouble();
    final progress = (investedAmount / budget).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button & title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Movie: ${movie['title']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Poster with overlay progress bar + offers
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: AssetImage(
                                    movie['posterUrl'] as String,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // Play button
                            IconButton(
                              icon: const Icon(
                                Icons.play_circle_fill,
                                size: 60,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),

                            // Offers (top-right)
                            Positioned(
                              top: 12,
                              right: 24,
                              child: SizedBox(
                                height: 30,
                                width: 140,
                                child: PageView.builder(
                                  controller: _offerController,
                                  scrollDirection: Axis.vertical,
                                  itemCount: (movie['offers'] as List).length,
                                  itemBuilder: (context, index) {
                                    final offer =
                                        (movie
                                            as Map<
                                              String,
                                              dynamic
                                            >)['offers'][index];
                                    return Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        offer,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Progress bar (bottom overlay)
                            Positioned(
                              bottom: 12,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[400],
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Raised: ₹${investedAmount.toStringAsFixed(0)}',
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

                        const SizedBox(height: 10),

                        // Release, Genre & Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Release: ${movie['releaseDate']}   Trailer: ${movie['trailerDate']}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Genre: ${movie['movieTypeName']} • ${movie['language']}   Certification: U/A',
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Main Tabs
                        buildMainTabs(),

                        const SizedBox(height: 16),

                        // Sub-tabs container
                        if (selectedMainTab == 'Movie') buildMovieSubTabs(),
                        if (selectedMainTab == 'Offers')
                          buildOfferSubTabs(movie),
                        if (selectedMainTab == 'News') buildNewsSubTabs(),

                        const SizedBox(height: 16),

                        // Content container
                        if (selectedMainTab != 'News')
                          Container(
                            width: double.infinity,
                            color: Colors.grey[50],
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: getTabContent(movie),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Buy Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // test it
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieBuyScreen(movieId: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Buy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Tabs
  Widget buildMainTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['Movie', 'Offers', 'News', 'Transection'].map((tab) {
          final isSelected = selectedMainTab == tab;
          return GestureDetector(
            onTap: () => setState(() {
              selectedMainTab = tab;
              selectedSubTab = 'Actors';
              if (tab == 'Offers') selectedOfferSubTab = 'Star Connect';
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border(
                        bottom: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Movie sub-tabs
  Widget buildMovieSubTabs() {
    final subTabs = ['Actors', 'Top Investor', 'Profit Holder', 'Winner'];
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: subTabs.map((subTab) {
            final isSelected = selectedSubTab == subTab;
            return GestureDetector(
              onTap: () => setState(() => selectedSubTab = subTab),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.3),
                ),
                child: Text(
                  subTab,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Offers sub-tabs
  Widget buildOfferSubTabs(Map<String, dynamic> movie) {
    final offers = List<String>.from(movie['offers'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: offers.map((offer) {
                final isSelected = selectedOfferSubTab == offer;
                return GestureDetector(
                  onTap: () => setState(() => selectedOfferSubTab = offer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                    child: Text(
                      offer,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // News sub-tabs
  Widget buildNewsSubTabs() {
    final newsSubTabs = ['Cinema', 'Collection Report'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: newsSubTabs.map((subTab) {
                final isSelected = selectedNewsSubTab == subTab;
                return GestureDetector(
                  onTap: () => setState(() => selectedNewsSubTab = subTab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                    child: Text(
                      subTab,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Load corresponding News content
        selectedNewsSubTab == 'Cinema'
            ? CinemaNewsScreen(movieId: widget.movieId)
            : CollectionReportScreen(movieId: widget.movieId),
      ],
    );
  }

  // Content container
  Widget getTabContent(Map<String, dynamic> movie) {
    switch (selectedMainTab) {
      case 'Offers':
        switch (selectedOfferSubTab) {
          case 'Star Connect':
            return StartOfferScreen(movieId: widget.movieId);
          case 'FlimBit':
            return FilmBitOfferScreen(movieId: widget.movieId);
          default:
            return const SizedBox();
        }

      case 'Transection':
        return TransactionReportScreen(movieId: widget.movieId);

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
