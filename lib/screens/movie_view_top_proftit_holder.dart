import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/AppTheme.dart';
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

    final itemsPerPage = 3;
    final pageCount = (holders.length / itemsPerPage).ceil();

    return Container(
      color: Colors.grey.shade100, // 🔹 gray background
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "💰 Top Profit Holders",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 120,
                      child: Container(height: 3, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Cards
          SizedBox(
            height: 240,
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
                          rank: start + index + 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Dots
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
                  color: currentPage == index
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfitHolderCard extends StatelessWidget {
  final ProfitHolder holder;
  final int rank;

  const ProfitHolderCard({super.key, required this.holder, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenDetail(context, holder),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShimmerProfile(holder.profilePicUrl),
            const SizedBox(height: 10),
            Text(
              holder.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _statTile("ROI", "${holder.roi.toStringAsFixed(1)}%"),
            _statTile(
              "Invested",
              "₹${holder.investedAmount.toStringAsFixed(0)}",
            ),
            _statTile("Profit", "₹${holder.profitAmount.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerProfile(String imageUrl) {
    return ClipOval(
      child: SizedBox(
        height: 60,
        width: 60,
        child: Stack(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.amber.shade200,
              highlightColor: Colors.amber.shade50,
              child: Container(color: Colors.amber.shade100),
            ),
            FadeInImage.assetNetwork(
              placeholder: '',
              image: imageUrl,
              fit: BoxFit.cover,
              imageErrorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // 🪩 Fullscreen Detail Popup (like Star Connect)
  void _openFullScreenDetail(BuildContext context, ProfitHolder holder) {
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
                  child: FadeInImage.assetNetwork(
                    placeholder: '',
                    image: holder.profilePicUrl,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[900]),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(holder.profilePicUrl),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            holder.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailTile(
                            "Invested",
                            "₹${holder.investedAmount.toStringAsFixed(0)}",
                          ),
                          _buildDetailTile(
                            "Profit",
                            "₹${holder.profitAmount.toStringAsFixed(0)}",
                          ),
                          _buildDetailTile(
                            "ROI",
                            "${holder.roi.toStringAsFixed(1)}%",
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              "Close",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
