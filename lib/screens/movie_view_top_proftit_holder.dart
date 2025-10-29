import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class ProfitHolder {
  final String name;
  final String profilePicUrl;
  final double investedAmount;
  final double profitAmount;

  ProfitHolder({
    required this.name,
    required this.profilePicUrl,
    required this.investedAmount,
    required this.profitAmount,
  });

  factory ProfitHolder.fromJson(Map<String, dynamic> json) {
    return ProfitHolder(
      name: json["userName"] ?? "Unknown",
      profilePicUrl: json["profilePicUrl"] ?? "",
      investedAmount: (json["totalInvested"] ?? 0).toDouble(),
      profitAmount: (json["totalReturned"] ?? 0).toDouble(),
    );
  }

  double get roi =>
      investedAmount == 0 ? 0 : (profitAmount / investedAmount) * 100;
}

class TopProfitHoldersSection extends StatefulWidget {
  final int movieId;
  const TopProfitHoldersSection({super.key, required this.movieId});

  @override
  State<TopProfitHoldersSection> createState() =>
      _TopProfitHoldersSectionState();
}

class _TopProfitHoldersSectionState extends State<TopProfitHoldersSection> {
  final PageController _pageController = PageController();
  List<ProfitHolder> holders = [];
  bool isLoading = true;
  int currentPage = 0;

  int offset = 0;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchHolders();
  }

  Future<void> _fetchHolders() async {
    setState(() => isLoading = true);
    try {
      final payload = {
        "movieId": widget.movieId.toString(),
        "offset": offset.toString(),
        "limit": limit.toString(),
      };
      final result = await ApiService.post(
        ApiEndpoints.topProfitHolder,
        body: payload,
      );

      if (result != null) {
        final List<dynamic> newHolders = result ?? [];
        setState(() {
          holders.addAll(
            newHolders.map((e) => ProfitHolder.fromJson(e)).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching profit holders: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && holders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (holders.isEmpty) {
      return const Center(child: Text("No profit holders yet"));
    }

    final itemsPerPage = 3; // 3 cards per page
    final pageCount = (holders.length / itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Top Profit Holders",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: pageCount,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, pageIndex) {
                final start = pageIndex * itemsPerPage;
                final end = (start + itemsPerPage) > holders.length
                    ? holders.length
                    : start + itemsPerPage;
                final pageHolders = holders.sublist(start, end);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(
                    pageHolders.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 12 : 6,
                          right: index == pageHolders.length - 1 ? 12 : 6,
                        ),
                        child: ProfitHolderCard(
                          holder: pageHolders[index],
                          index: start + index,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index ? 14 : 8,
                height: currentPage == index ? 14 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: currentPage == index
                      ? const LinearGradient(
                          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: currentPage == index ? null : Colors.grey.shade300,
                ),
                child: AnimatedScale(
                  scale: currentPage == index ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: const SizedBox(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfitHolderCard extends StatefulWidget {
  final ProfitHolder holder;
  final int index;

  const ProfitHolderCard({
    super.key,
    required this.holder,
    required this.index,
  });

  @override
  State<ProfitHolderCard> createState() => _ProfitHolderCardState();
}

class _ProfitHolderCardState extends State<ProfitHolderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<List<Color>> gradients = [
    [Colors.blue.shade300, Colors.purple.shade400],
    [Colors.orange.shade400, Colors.red.shade400],
    [Colors.green.shade300, Colors.teal.shade400],
    [Colors.pink.shade300, Colors.purple.shade300],
    [Colors.cyan.shade300, Colors.indigo.shade400],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = gradients[widget.index % gradients.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(widget.holder.profilePicUrl),
            onBackgroundImageError: (_, __) =>
                const AssetImage('assets/poster1.jpg') as ImageProvider,
          ),
          const SizedBox(height: 8),
          Text(
            widget.holder.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_animation.value),
                child: child,
              );
            },
            child: Column(
              children: [
                AnimatedStatCard(
                  label: "Invested",
                  value: widget.holder.investedAmount,
                ),
                const SizedBox(height: 4),
                AnimatedStatCard(
                  label: "Profit",
                  value: widget.holder.profitAmount,
                ),
                const SizedBox(height: 4),
                AnimatedStatCard(
                  label: "ROI",
                  value: widget.holder.roi,
                  isPercentage: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedStatCard extends StatelessWidget {
  final String label;
  final double value;
  final bool isPercentage;

  const AnimatedStatCard({
    super.key,
    required this.label,
    required this.value,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isPercentage
            ? "$label: ${value.toStringAsFixed(2)}%"
            : "$label: ₹${value.toStringAsFixed(0)}",
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
