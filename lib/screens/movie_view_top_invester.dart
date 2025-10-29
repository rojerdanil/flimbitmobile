import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class TopInvestorsSection extends StatefulWidget {
  final int movieId;
  const TopInvestorsSection({super.key, required this.movieId});

  @override
  State<TopInvestorsSection> createState() => _TopInvestorsSectionState();
}

class _TopInvestorsSectionState extends State<TopInvestorsSection>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> investors = [];
  bool isLoading = true;
  bool isFetchingMore = false;

  int offset = 0;
  final int limit = 10;
  double scrollPosition = 0;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetchInvestors();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Pagination
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isFetchingMore &&
        !isLoading) {
      _fetchMoreInvestors();
    }

    // Dot indicator
    setState(() {
      scrollPosition = _scrollController.offset;
    });
  }

  Future<void> _fetchInvestors() async {
    setState(() => isLoading = true);
    await _fetchMoreInvestors();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreInvestors() async {
    setState(() => isFetchingMore = true);
    try {
      final payload = {
        "offset": offset.toString(),
        "limit": limit.toString(),
        "movieId": widget.movieId,
      };
      final result = await ApiService.post(
        ApiEndpoints.topInvestors,
        body: payload,
      );

      if (result != null) {
        final List<dynamic> newInvestors = result;
        setState(() {
          investors.addAll(List<Map<String, dynamic>>.from(newInvestors));
          if (newInvestors.length >= limit) offset += limit;
        });

        // Trigger card animation
        _animController.forward(from: 0);
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching investors: $e");
    } finally {
      setState(() => isFetchingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  int _visiblePageIndex() {
    if (investors.isEmpty) return 0;
    const double cardWidth = 132;
    return (scrollPosition / cardWidth).round().clamp(0, investors.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && investors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (investors.isEmpty) {
      return const Center(child: Text("No investors yet"));
    }

    final visibleIndex = _visiblePageIndex();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Top Investors",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal list
          SizedBox(
            height: 200,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: investors.length + (isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == investors.length) {
                  return const SizedBox(
                    width: 60,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final investor = investors[index];
                final isTop3 = index < 3;

                return AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final animationValue =
                        (_animController.value - index * 0.05).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: animationValue,
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - animationValue)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: EdgeInsets.only(
                      right: index == investors.length - 1 ? 0 : 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isTop3 ? Colors.amber[50] : Colors.grey[100],
                      border: Border.all(
                        color: isTop3 ? Colors.amber : Colors.grey.shade300,
                        width: isTop3 ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
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
                              backgroundImage: NetworkImage(
                                investor["profilePicUrl"] ?? '',
                              ),
                              onBackgroundImageError: (_, __) =>
                                  const AssetImage('assets/poster1.jpg')
                                      as ImageProvider,
                            ),
                            if (isTop3)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          investor["userName"] ?? "Unknown",
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
                          "₹${(investor["totalInvested"] ?? 0).toStringAsFixed(0)}",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                investors.length,
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
}
