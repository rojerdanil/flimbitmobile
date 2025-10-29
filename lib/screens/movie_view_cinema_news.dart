import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class CinemaNewsScreen extends StatefulWidget {
  final int movieId;
  const CinemaNewsScreen({super.key, required this.movieId});

  @override
  State<CinemaNewsScreen> createState() => _CinemaNewsScreenState();
}

class _CinemaNewsScreenState extends State<CinemaNewsScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> cinemaNews = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int offset = 0;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchInitialNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetchingMore &&
        !isLoading) {
      _fetchMoreNews();
    }
  }

  Future<void> _fetchInitialNews() async {
    setState(() => isLoading = true);
    await _fetchNewsBatch();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreNews() async {
    setState(() => isFetchingMore = true);
    await _fetchNewsBatch();
    setState(() => isFetchingMore = false);
  }

  Future<void> _fetchNewsBatch() async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.readCinemaNews,
        body: {
          "offset": offset.toString(),
          "limit": limit.toString(),
          "movieId": widget.movieId.toString(),
        },
      );

      if (response != null && response is List && response.isNotEmpty) {
        setState(() {
          cinemaNews.addAll(List<Map<String, dynamic>>.from(response));
          offset += limit;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching cinema news: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && cinemaNews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cinemaNews.isEmpty) {
      return Center(
        child: Text(
          'No news available.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;
    final cardHeight = 150.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Cinema News',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // Grid with fade-in animation
          GridView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cardWidth / cardHeight,
            ),
            itemCount: cinemaNews.length + (isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == cinemaNews.length) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return AnimatedCinemaNewsCard(
                news: cinemaNews[index],
                index: index,
              );
            },
          ),

          if (isFetchingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

class AnimatedCinemaNewsCard extends StatefulWidget {
  final Map<String, dynamic> news;
  final int index;
  const AnimatedCinemaNewsCard({
    super.key,
    required this.news,
    required this.index,
  });

  @override
  State<AnimatedCinemaNewsCard> createState() => _AnimatedCinemaNewsCardState();
}

class _AnimatedCinemaNewsCardState extends State<AnimatedCinemaNewsCard>
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
      begin: const Offset(0, 0.2), // Start slightly below
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CinemaNewsCard(news: widget.news),
      ),
    );
  }
}

class CinemaNewsCard extends StatelessWidget {
  final Map<String, dynamic> news;
  const CinemaNewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final newsDate = news['newsDate'] != null
        ? df.format(DateTime.parse(news['newsDate']))
        : '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news['newsTitle'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            newsDate,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              news['newsDetail'] ?? '',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}
