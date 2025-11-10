import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class MovieShareOfferWidget extends StatefulWidget {
  final int movieId;

  const MovieShareOfferWidget({super.key, required this.movieId});

  @override
  State<MovieShareOfferWidget> createState() => _MovieShareOfferWidgetState();
}

class _MovieShareOfferWidgetState extends State<MovieShareOfferWidget> {
  List<Map<String, dynamic>> shareTypesData = [];
  int? selectedShareIndex;
  Future<Map<String, dynamic>?>? allocatedOffersFuture;
  bool hasSelectedOffers = false;
  int soldShares = 0;
  int totalShares = 0;
  int distributedShares = 0;
  int ownedShare = 0;

  @override
  void initState() {
    super.initState();
    loadShareTypes();
  }

  // 🔹 Fetch share types for movie
  Future<void> loadShareTypes() async {
    try {
      final list = await fetchShareTypes(widget.movieId);
      setState(() {
        shareTypesData = list;
      });

      // Auto-select first share type and fetch its offers
      if (list.isNotEmpty) {
        onShareTypeSelected(0);
      }
    } catch (e) {
      debugPrint("Error fetching share types: $e");
    }
  }

  // 🔹 On share type selected
  void onShareTypeSelected(int index) {
    setState(() {
      selectedShareIndex = index;
      hasSelectedOffers = true;
      final shareTypeId = shareTypesData[index]['shareId'];
      allocatedOffersFuture = fetchAllocatedOffers(widget.movieId, shareTypeId);
    });
  }

  // 🔹 API call to get share types
  Future<List<Map<String, dynamic>>> fetchShareTypes(int movieId) async {
    final response = await ApiService.get(
      "${ApiEndpoints.userInvestedMovieShare}$movieId",
    );
    if (response != null) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  // 🔹 API call to get offers for a share type
  Future<Map<String, dynamic>?> fetchAllocatedOffers(
    int movieId,
    int shareTypeId,
  ) async {
    final response = await ApiService.get(
      "${ApiEndpoints.movieShareCalculateOfferSummary}$movieId/$shareTypeId",
    );
    if (response != null) return response;
    return null;
  }

  Color getBadgeColor(String? status) {
    switch (status) {
      case 'eligibleForSale':
        return Colors.green;
      case 'soldOut':
        return Colors.grey;
      case 'distributed':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String getShareStatusText(String? status) {
    switch (status) {
      case 'eligibleForSale':
        return 'Sellable';
      case 'soldOut':
        return 'Sold';
      case 'distributed':
        return 'Distributed';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Dialog title + close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Buyed Share Offer",
                          style: AppTheme.headline2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 🔹 Subtitle
                Text(
                  "Select Share Type",
                  style: AppTheme.subtitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔹 Share type list
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: shareTypesData.length,
                    itemBuilder: (context, index) {
                      final st = shareTypesData[index];
                      final isSelected = selectedShareIndex == index;

                      return GestureDetector(
                        onTap: () => onShareTypeSelected(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      Colors.amber,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  st['shareTypeName'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getBadgeColor('distributed'),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    getShareStatusText('distributed'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Offers section
                if (hasSelectedOffers)
                  FutureBuilder<Map<String, dynamic>?>(
                    future: allocatedOffersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return const Text("No offers available");
                      }

                      final offers = snapshot.data!;

                      // 🔹 Assign values to show in badges
                      totalShares = offers['totalShare'] ?? 0;
                      soldShares = offers['soldShares'] ?? 0;
                      distributedShares = offers['distributedShares'] ?? 0;
                      ownedShare = offers['ownedShares'] ?? 0;
                      final offerItems = [
                        {
                          "label": "Discount",
                          "value": "₹${offers['totalDiscount'] ?? 0}",
                        },
                        {
                          "label": "Wallet Bonus",
                          "value": "₹${offers['totalWallet'] ?? 0}",
                        },
                        {
                          "label": "Free Shares",
                          "value": "${offers['totalFreeShare'] ?? 0}",
                        },
                        {
                          "label": "Platform Commission",
                          "value": (offers['plaftormCommision'] ?? false)
                              ? "Yes"
                              : "No",
                        },
                        {
                          "label": "Profit Commission",
                          "value": (offers['profitCommision'] ?? false)
                              ? "Yes"
                              : "No",
                        },
                      ];

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Row for Total / Sold / Distributed badges
                            Row(
                              children: [
                                _buildShareBadge(
                                  label: "Total",
                                  value: totalShares.toString(),
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 10),
                                _buildShareBadge(
                                  label: "Sold",
                                  value: soldShares.toString(),
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 10),
                                _buildShareBadge(
                                  label: "Distributed",
                                  value: distributedShares.toString(),
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                _buildShareBadge(
                                  label: "Owned",
                                  value: ownedShare.toString(),
                                  color: const Color(0xFF26A69A), // Teal
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // 🔹 Offer details list
                            ...offerItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['label']!,
                                      style: AppTheme.subtitle.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item['value']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.pie_chart_rounded, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
