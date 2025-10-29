import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class ActorsSection extends StatefulWidget {
  final int movieId;
  const ActorsSection({super.key, required this.movieId});

  @override
  State<ActorsSection> createState() => _ActorsSectionState();
}

class _ActorsSectionState extends State<ActorsSection> {
  List<Map<String, dynamic>> actors = [];
  bool isLoading = true;

  final ScrollController _scrollController = ScrollController();
  double scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _fetchActors();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      scrollPosition = _scrollController.offset;
    });
  }

  Future<void> _fetchActors() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.get(
        "${ApiEndpoints.movieActors}${widget.movieId}",
      );

      if (result is List && result.isNotEmpty) {
        setState(() {
          actors = List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching actors: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  int _visiblePageIndex(double cardWidth) {
    if (actors.isEmpty) return 0;
    return (scrollPosition / (cardWidth + 12)).round().clamp(
      0,
      actors.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 36) / 2.5;
    final cardHeight = cardWidth * 1.4;

    if (isLoading) {
      return SizedBox(
        height: cardHeight + 40,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (actors.isEmpty) {
      return const Center(child: Text("No actors found"));
    }

    final visibleIndex = _visiblePageIndex(cardWidth);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const SizedBox(height: 12),

          // Horizontal scroll of actor cards
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: actors.length,
              itemBuilder: (context, index) {
                final actor = actors[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == actors.length - 1 ? 0 : 12,
                  ),
                  child: _AnimatedActorCard(
                    actor: actor,
                    width: cardWidth,
                    height: cardHeight,
                  ),
                );
              },
            ),
          ),

          // Dot Indicator
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                actors.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: visibleIndex == i ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: visibleIndex == i
                        ? Colors.amber
                        : Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Animated Actor Card with gradient overlay
class _AnimatedActorCard extends StatelessWidget {
  final Map<String, dynamic> actor;
  final double width;
  final double height;

  const _AnimatedActorCard({
    required this.actor,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = actor["profilePicUrl"] ?? "";
    final role = actor["roleName"] ?? "Unknown Role";
    final name = actor["actorName"] ?? "Unknown";

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Actor Image
              Image.network(
                imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/poster1.jpg', fit: BoxFit.cover),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Text info
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
