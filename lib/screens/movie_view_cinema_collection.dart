import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart';

class CollectionReportScreen extends StatefulWidget {
  final int movieId;
  const CollectionReportScreen({super.key, required this.movieId});

  @override
  State<CollectionReportScreen> createState() => _CollectionReportScreenState();
}

class _CollectionReportScreenState extends State<CollectionReportScreen> {
  final List<Map<String, dynamic>> collectionReport = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  int offset = 0;
  final int limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchInitialReport();
  }

  Future<void> _fetchInitialReport() async {
    setState(() => isLoading = true);
    await _fetchReportBatch();
    setState(() => isLoading = false);
  }

  Future<void> _fetchReportBatch() async {
    try {
      final response = await ApiService.post(
        ApiEndpoints.readCollectionReport,
        body: {
          "offset": offset.toString(),
          "limit": limit.toString(),
          "movieId": widget.movieId.toString(),
        },
      );

      if (response != null) {
        setState(() {
          final List<Map<String, dynamic>> newItems =
              List<Map<String, dynamic>>.from(response);
          collectionReport.addAll(newItems);
          offset += limit;
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching collection report: $e");
    }
  }

  String formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (collectionReport.isEmpty) {
      return Center(
        child: Text(
          'No collection report available.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    final pageCount = (collectionReport.length / 4).ceil(); // 4 cards per page
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;
    final cardHeight = 120.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Collection Report',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        SizedBox(
          height: cardHeight * 2 + 24,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final pageItems = collectionReport
                  .skip(pageIndex * 4)
                  .take(4)
                  .toList();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cardWidth / cardHeight,
                  ),
                  itemCount: pageItems.length,
                  itemBuilder: (context, index) {
                    return AnimatedCollectionCard(
                      report: pageItems[index],
                      index: index,
                      formatAmount: formatAmount,
                    );
                  },
                  shrinkWrap: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AnimatedCollectionCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final int index;
  final String Function(double) formatAmount;

  const AnimatedCollectionCard({
    super.key,
    required this.report,
    required this.index,
    required this.formatAmount,
  });

  @override
  State<AnimatedCollectionCard> createState() => _AnimatedCollectionCardState();
}

class _AnimatedCollectionCardState extends State<AnimatedCollectionCard>
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
        child: CollectionCard(
          report: widget.report,
          formatAmount: widget.formatAmount,
        ),
      ),
    );
  }
}

class CollectionCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final String Function(double) formatAmount;

  const CollectionCard({
    super.key,
    required this.report,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final collectionDate = report['collectionDate'] != null
        ? df.format(DateTime.parse(report['collectionDate']))
        : '';
    final amount = report['collectionAmt'] != null
        ? formatAmount(report['collectionAmt'].toDouble())
        : '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report['region'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            collectionDate,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
