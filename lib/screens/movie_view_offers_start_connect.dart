import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class StartOfferScreen extends StatefulWidget {
  final int movieId;
  const StartOfferScreen({super.key, required this.movieId});

  @override
  State<StartOfferScreen> createState() => _StartOfferScreenState();
}

class _StartOfferScreenState extends State<StartOfferScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> offerList = [];
  Map<String, dynamic>? offerDetails;
  int? selectedIndex;
  bool isLoading = true;
  bool isDetailLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fetchOfferList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchOfferList() async {
    try {
      final response = await ApiService.get(
        "${ApiEndpoints.readMovieStarConnectOffer}${widget.movieId}",
      );

      if (response != null && response is List) {
        setState(() {
          offerList = List<Map<String, dynamic>>.from(response);
        });

        if (offerList.isNotEmpty) {
          // Auto-select first offer
          fetchOfferDetails(0, offerList[0]['key']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching offers: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchOfferDetails(int index, String offerKey) async {
    setState(() {
      selectedIndex = index;
      isDetailLoading = true;
    });

    try {
      final response = await ApiService.get(
        "${ApiEndpoints.starConnectOfferDetails}$offerKey/${widget.movieId}",
      );

      if (response != null) {
        setState(() {
          offerDetails = response;
        });

        // Trigger animation
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint("Error fetching offer details: $e");
    }

    setState(() => isDetailLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔘 Offer Tabs (underline style)
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: offerList.length,
            itemBuilder: (context, index) {
              final offer = offerList[index];
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => fetchOfferDetails(index, offer['key']),
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(
                    offer['value'] ?? '',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 📄 Selected offer details with animation
        if (isDetailLoading)
          const Center(child: CircularProgressIndicator())
        else if (offerDetails != null)
          _buildAnimatedOfferCard(offerDetails!)
        else
          Center(
            child: Text(
              'No offers  available.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedOfferCard(Map<String, dynamic> data) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = _animationController.value;
        final offsetY = 50 * (1 - animationValue); // Slide-up distance
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: _buildOfferCard(data),
          ),
        );
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> data) {
    final starOffer = data["starOffer"] ?? {};
    final starConnect = starOffer["starConnectorOffer"] ?? {};

    final rulesText = (starOffer["description"] ?? "")
        .toString()
        .split(RegExp(r'\n|\r'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offer title
          Row(
            children: [
              Expanded(
                child: Text(
                  starConnect["name"] ?? "Offer",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            starConnect["description"] ?? "",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 10),

          const Text(
            'Rules:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ...rulesText.map(
            (rule) => Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(rule, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data["selectedMsg"] ?? "Not Selected",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Rank: ${data["rank"] ?? '-'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
