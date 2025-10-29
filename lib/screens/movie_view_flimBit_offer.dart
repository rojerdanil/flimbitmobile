import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class FilmBitOfferScreen extends StatefulWidget {
  final int movieId;
  const FilmBitOfferScreen({super.key, required this.movieId});

  @override
  State<FilmBitOfferScreen> createState() => _FilmBitOfferScreenState();
}

class _FilmBitOfferScreenState extends State<FilmBitOfferScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> shareList = [];
  List<Map<String, dynamic>> offersList = [];
  int selectedShareIndex = 0;
  int selectedOfferIndex = 0;
  bool isLoading = true;
  bool isOfferLoading = false;

  final ScrollController _chipScrollController = ScrollController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fetchShareList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchShareList() async {
    try {
      final response = await ApiService.get(
        "${ApiEndpoints.shareDetails}${widget.movieId}",
      );
      if (response != null && response is List) {
        setState(() {
          shareList = List<Map<String, dynamic>>.from(response);
        });
        if (shareList.isNotEmpty) {
          fetchShareOffers(0, shareList[0]['id']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching share list: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchShareOffers(int index, int shareId) async {
    setState(() {
      selectedShareIndex = index;
      selectedOfferIndex = 0;
      isOfferLoading = true;
    });

    try {
      final response = await ApiService.get(
        "${ApiEndpoints.flimbitOffer}${widget.movieId}/$shareId",
      );
      if (response != null && response is List) {
        setState(() {
          offersList = List<Map<String, dynamic>>.from(response);
        });

        // Trigger animation
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint("Error fetching offers: $e");
    }

    setState(() => isOfferLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShareTabs(),
        const SizedBox(height: 12),
        _buildOfferCards(),
        const SizedBox(height: 12),
        if (offersList.isNotEmpty)
          _buildAnimatedOfferDetails(offersList[selectedOfferIndex]),
      ],
    );
  }

  Widget _buildShareTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shareList.length,
        itemBuilder: (context, index) {
          final share = shareList[index];
          final isSelected = selectedShareIndex == index;

          return GestureDetector(
            onTap: () => fetchShareOffers(index, share['id']),
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                share['name'] ?? '',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferCards() {
    if (isOfferLoading) return const Center(child: CircularProgressIndicator());
    if (offersList.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No offers available."),
      );

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offersList.length,
        itemBuilder: (context, index) {
          final offer = offersList[index];
          final isSelected = selectedOfferIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => selectedOfferIndex = index);
              _chipScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );

              // Trigger animation
              _animationController.reset();
              _animationController.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey[200]!, Colors.grey[300]!],
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(
                    "Offer ${index + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: offer['status'] == 'active'
                          ? Colors.green[600]
                          : Colors.grey[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer['status'] == 'active' ? "Active" : "Inactive",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedOfferDetails(Map<String, dynamic> offer) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = _animationController.value;
        final offsetY = 50 * (1 - animationValue); // Slide-up distance
        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: _buildOfferDetails(offer),
          ),
        );
      },
    );
  }

  Widget _buildOfferDetails(Map<String, dynamic> offer) {
    final DateFormat df = DateFormat('dd MMM yyyy');

    final List<Map<String, dynamic>> properties = [
      {
        "text": offer['discountAmount'] != null && offer['discountAmount'] > 0
            ? "Discount: ${offer['discountAmount']}"
            : "Discount",
        "available":
            offer['discountAmount'] != null && offer['discountAmount'] > 0,
        "icon": Icons.local_offer,
        "gradient": [Colors.yellow[200]!, Colors.yellow[400]!],
      },
      {
        "text":
            offer['walletCreditAmount'] != null &&
                offer['walletCreditAmount'] > 0
            ? "Wallet: ${offer['walletCreditAmount']}"
            : "Wallet",
        "available":
            offer['walletCreditAmount'] != null &&
            offer['walletCreditAmount'] > 0,
        "icon": Icons.account_balance_wallet,
        "gradient": [Colors.green[200]!, Colors.green[400]!],
      },
      {
        "text": "No Profit Commission",
        "available": offer['noProfitCommission'] == true,
        "icon": Icons.money_off,
        "gradient": [Colors.blue[200]!, Colors.blue[400]!],
      },
      {
        "text": "No Platform Commission",
        "available": offer['noPlatFormCommission'] == true,
        "icon": Icons.web,
        "gradient": [Colors.pink[200]!, Colors.pink[400]!],
      },
      if (offer['buyOneGetOne'] == true)
        {
          "text": "Buy ${offer['buyQuantity']} Get ${offer['getQuantity']}",
          "available": true,
          "icon": Icons.shopping_bag,
          "gradient": [Colors.orange[200]!, Colors.orange[400]!],
        },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Validity and max users
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Valid: ${df.format(DateTime.parse(offer['validFrom']))} - ${df.format(DateTime.parse(offer['validTo']))}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Max Users: ${offer['maxUsers'] ?? '-'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _chipScrollController,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: properties.map((prop) {
                final isAvailable = prop['available'] as bool;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isAvailable
                        ? LinearGradient(
                            colors: prop['gradient'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.grey[200]!, Colors.grey[300]!],
                          ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        prop['icon'] as IconData,
                        size: 16,
                        color: isAvailable ? Colors.white : Colors.black38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        prop['text'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isAvailable ? Colors.white : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
