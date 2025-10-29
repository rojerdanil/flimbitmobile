import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

// ----------------------------
// OfferWinner model
// ----------------------------
class OfferWinner {
  final String username;
  final String imageUrl;
  final double investedAmount;
  final String status;
  OfferWinner({
    required this.username,
    required this.imageUrl,
    required this.investedAmount,
    required this.status,
  });

  factory OfferWinner.fromJson(Map<String, dynamic> json) {
    return OfferWinner(
      username: json['userName'] ?? 'Unknown',
      imageUrl: json['profilePicUrl'] ?? 'assets/poster1.jpg',
      investedAmount: (json['totalInvested'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
    );
  }
}

// ----------------------------
// Offer model
// ----------------------------
class Offer {
  final String key;
  final String title;

  Offer({required this.key, required this.title});

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(key: json['key'].toString(), title: json['value'] ?? '');
  }
}

// ----------------------------
// StartOfferScreenWinner with animated cards
// ----------------------------
class StartOfferScreenWinner extends StatefulWidget {
  final int movieId;

  const StartOfferScreenWinner({super.key, required this.movieId});

  @override
  State<StartOfferScreenWinner> createState() => _StartOfferScreenWinnerState();
}

class _StartOfferScreenWinnerState extends State<StartOfferScreenWinner>
    with TickerProviderStateMixin {
  List<Offer> offers = [];
  List<OfferWinner> winners = [];
  int selectedOfferIndex = 0;
  bool loadingOffers = true;
  bool loadingWinners = false;
  bool isFetchingMore = false;

  int offset = 0;
  final int limit = 6;
  final ScrollController _scrollController = ScrollController();
  double scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    fetchOffers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        !loadingWinners) {
      _fetchMoreWinners();
    }
    setState(() {
      scrollPosition = _scrollController.offset;
    });
  }

  Future<void> fetchOffers() async {
    setState(() => loadingOffers = true);

    final response = await ApiService.get(
      "${ApiEndpoints.readMovieStarConnectOffer}${widget.movieId}",
    );

    if (response != null) {
      final List<Offer> fetchedOffers = (response as List)
          .map((json) => Offer.fromJson(json))
          .toList();
      setState(() {
        offers = fetchedOffers;
        loadingOffers = false;
      });
      if (offers.isNotEmpty) {
        offset = 0;
        winners = [];
        fetchWinners(offers[0].key);
      }
    } else {
      setState(() => loadingOffers = false);
    }
  }

  Future<void> fetchWinners(String starOfferId) async {
    setState(() {
      loadingWinners = true;
      winners = [];
      offset = 0;
    });
    await _fetchWinnersPage(starOfferId);
    setState(() => loadingWinners = false);
  }

  Future<void> _fetchMoreWinners() async {
    if (offers.isEmpty) return;
    setState(() => isFetchingMore = true);
    await _fetchWinnersPage(offers[selectedOfferIndex].key);
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchWinnersPage(String starOfferId) async {
    final payload = {
      "movieId": widget.movieId.toString(),
      "offset": offset.toString(),
      "limit": limit.toString(),
      "starOfferId": starOfferId,
    };
    final response = await ApiService.post(
      ApiEndpoints.readMovieWinner,
      body: payload,
    );

    if (response != null && response['userWinnerList'] != null) {
      final List<OfferWinner> fetchedWinners =
          (response['userWinnerList'] as List)
              .map((json) => OfferWinner.fromJson(json))
              .toList();
      setState(() {
        winners.addAll(fetchedWinners);
        if (fetchedWinners.length >= limit) offset += limit;
      });
    }
  }

  int _visiblePageIndex() {
    if (winners.isEmpty) return 0;
    const double cardWidth = 140;
    return (scrollPosition / cardWidth).round().clamp(0, winners.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (loadingOffers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (offers.isEmpty) {
      return const Center(child: Text("No offers available"));
    }

    final visibleIndex = _visiblePageIndex();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offer Tabs
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final isSelected = index == selectedOfferIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOfferIndex = index;
                  });
                  winners = [];
                  offset = 0;
                  fetchWinners(offers[index].key);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? Colors.yellow.shade700
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    offers[index].title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: isSelected ? 16 : 15,
                      color: isSelected
                          ? Colors.yellow.shade700
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Winners List with staggered fade & slide animation
        loadingWinners && winners.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : winners.isEmpty
            ? Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 50,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Winners will be announced soon 🏆",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              )
            : SizedBox(
                height: 210,
                child: ListView.builder(
                  key: ValueKey(selectedOfferIndex),
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: winners.length + (isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == winners.length) {
                      return const SizedBox(
                        width: 60,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    return AnimatedWinnerCard(
                      winner: winners[index],
                      index: index,
                    );
                  },
                ),
              ),

        // Dot Indicator
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              winners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: visibleIndex == i ? 12 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: visibleIndex == i
                      ? Colors.yellow.shade700
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: visibleIndex == i
                      ? [
                          BoxShadow(
                            color: Colors.yellow.shade200,
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ----------------------------
// Animated Winner Card
// ----------------------------
class AnimatedWinnerCard extends StatefulWidget {
  final OfferWinner winner;
  final int index;
  const AnimatedWinnerCard({
    super.key,
    required this.winner,
    required this.index,
  });

  @override
  State<AnimatedWinnerCard> createState() => _AnimatedWinnerCardState();
}

class _AnimatedWinnerCardState extends State<AnimatedWinnerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered delay
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.winner;
    final isTop3 = widget.index < 3;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 140,
          margin: EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isTop3
                ? LinearGradient(
                    colors: [Colors.amber.shade100, Colors.yellow.shade50],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : LinearGradient(colors: [Colors.grey.shade100, Colors.white]),
            border: Border.all(
              color: isTop3 ? Colors.amber.shade700 : Colors.grey.shade300,
              width: isTop3 ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(winner.imageUrl),
                    onBackgroundImageError: (_, __) =>
                        const AssetImage('assets/poster1.jpg') as ImageProvider,
                  ),
                  if (isTop3)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        widget.index == 0
                            ? Icons.emoji_events
                            : widget.index == 1
                            ? Icons.emoji_events_outlined
                            : Icons.military_tech,
                        color: widget.index == 0
                            ? Colors.amber
                            : widget.index == 1
                            ? Colors.grey
                            : Colors.brown,
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                winner.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                " ${winner.status}",
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
