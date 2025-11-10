import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_view_transection.dart';

class MovieShareSummaryBox extends StatelessWidget {
  final int movieId;

  const MovieShareSummaryBox({super.key, required this.movieId});

  // 🔹 Fetch share summary from API
  Future<Map<String, dynamic>> fetchShareSummary() async {
    final response = await ApiService.get(
      "${ApiEndpoints.movieShareSoldCountummary}$movieId",
    );
    if (response != null) {
      return response ?? {};
    }
    return {
      "totalShares": 0,
      "distributedShares": 0,
      "soldShares": 0,
      "ownedShares": 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchShareSummary(),
      builder: (context, snapshot) {
        Map<String, dynamic> shareData = {
          "totalShares": 0,
          "distributedShares": 0,
          "soldShares": 0,
          "ownedShares": 0,
        };

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData) {
          shareData = snapshot.data!;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Row 1: Title + View History =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Movie Share Summary",
                    style: AppTheme.headline2.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 30,
                            ),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.75,
                              width: double.infinity,
                              child: TransactionReportScreen(movieId: movieId),
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          "View History",
                          style: TextStyle(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 11,
                          color: AppTheme.primaryColor.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Row 2: Summary Stats =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShareInfoItem("Total Share", shareData['totalShares']),
                  _buildShareInfoItem(
                    "Distributed",
                    shareData['distributedShares'],
                  ),
                  _buildShareInfoItem("Sold", shareData['soldShares']),
                  _buildShareInfoItem("You Owned", shareData['ownedShares']),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Helper for each label/value item
  Widget _buildShareInfoItem(String label, dynamic value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
          ),
          const SizedBox(height: 3),
          Text(
            value != null ? value.toString() : "0",
            style: AppTheme.headline2.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
