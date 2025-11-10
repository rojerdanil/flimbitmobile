import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../securityScreen/pin_verification_dialog.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../Readysection/movie_share_summary_box.dart';
import '../Readysection/movie_share_offer_widget.dart';
import '../Readysection/sell_summary_dialog.dart';
import '../Readysection/SelectPaymentGatewayScreen.dart';

import '../helper/common_helper.dart';

class MovieSellShareScreen extends StatefulWidget {
  final int movieId;

  const MovieSellShareScreen({super.key, required this.movieId});

  @override
  State<MovieSellShareScreen> createState() => _MovieSellShareScreenState();
}

class _MovieSellShareScreenState extends State<MovieSellShareScreen> {
  late Future<Map<String, dynamic>> movieFuture;
  late Future<List<Map<String, dynamic>>> shareTypesFuture;
  Future<Map<String, dynamic>?>? allocatedOffersFuture;
  final ValueNotifier<double> _totalValue = ValueNotifier(0);
  final ValueNotifier<int> _enteredShares = ValueNotifier<int>(0);

  int selectedShareIndex = 0;
  int enteredShares = 0;
  final TextEditingController _controller = TextEditingController();
  bool isExpanded = false; // <-- move to state of _MovieSellShareScreenState

  Map<String, dynamic>? selectedPayment;

  @override
  void initState() {
    super.initState();
    movieFuture = fetchMovieDetails(widget.movieId);
    shareTypesFuture = fetchShareTypes(widget.movieId);
    allocatedOffersFuture = Future.value(
      null,
    ); // ✅ prevents “not initiated” error
  }

  Future<Map<String, dynamic>> fetchMovieDetails(int movieId) async {
    final response = await ApiService.get(
      "${ApiEndpoints.userInvestedMovieSummary}$movieId",
    );
    if (response != null) {
      return response;
    } else {
      throw Exception('Failed to load movie data from API');
    }
  }

  Future<List<Map<String, dynamic>>> fetchShareTypes(int movieId) async {
    final response = await ApiService.get(
      "${ApiEndpoints.userInvestedMovieShare}$movieId",
    );
    if (response != null) {
      final list = List<Map<String, dynamic>>.from(response);

      // 👇 Auto-call fetchAllocatedOffers for the first share type
      if (list.isNotEmpty) {
        final firstShareTypeId = list[0]['shareId'];
        allocatedOffersFuture = fetchAllocatedOffers(movieId, firstShareTypeId);
      }

      return list;
    } else {
      throw Exception('Failed to load share types');
    }
  }

  Future<Map<String, dynamic>?> fetchAllocatedOffers(
    int movieId,
    int shareTypeId,
  ) async {
    final response = await ApiService.get(
      "${ApiEndpoints.movieShareCalculateOfferSummary}$movieId/$shareTypeId",
    );
    if (response != null) {
      return response;
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchMovieOffers(int movieId) async {
    final response = await ApiService.get(
      "${ApiEndpoints.movieShareCalculateOfferSummary}$movieId/13",
    );
    if (response != null) {
      return Map<String, dynamic>.from(response);
    } else {
      return {};
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _totalValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Sell Shares",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: movieFuture,
        builder: (context, snapshotMovie) {
          if (snapshotMovie.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshotMovie.hasError) {
            return Center(child: Text('Error: ${snapshotMovie.error}'));
          } else if (!snapshotMovie.hasData) {
            return const Center(child: Text('Movie data not found'));
          }

          final movieData = snapshotMovie.data!;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: shareTypesFuture,
            builder: (context, snapshotShares) {
              if (snapshotShares.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshotShares.hasError) {
                return Center(child: Text('Error: ${snapshotShares.error}'));
              } else if (!snapshotShares.hasData ||
                  snapshotShares.data!.isEmpty) {
                return const Center(child: Text('No share types available'));
              }

              final shareTypesData = snapshotShares.data!;
              final shareType = shareTypesData[selectedShareIndex];
              final double price = (movieData['perShareAmount'] is String)
                  ? double.tryParse(movieData['perShareAmount']) ?? 0.0
                  : (movieData['perShareAmount'] ?? 0).toDouble();
              final owned = movieData['totalSharesPurchased'] ?? 0;
              double total = enteredShares * (price as num).toDouble();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildMovieCard(movieData),
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchMovieOffers(widget.movieId),
                      builder: (context, snapshotOffers) {
                        if (snapshotOffers.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshotOffers.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Error loading offers: ${snapshotOffers.error}",
                            ),
                          );
                        } else if (!snapshotOffers.hasData ||
                            snapshotOffers.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final offers = snapshotOffers.data!;
                        return buildMovieOffersSection(context, offers);
                      },
                    ),
                    MovieShareSummaryBox(movieId: widget.movieId),

                    buildSellShareInputRow(
                      context: context,
                      price: price,
                      owned: owned,
                      controller: _controller,
                      onValidInput: (qty) =>
                          setState(() => enteredShares = qty),
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<double>(
                      valueListenable: _totalValue,
                      builder: (context, total, _) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Total Sell Value: ₹${total.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 80), // spacing before button
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(14),
        child: ValueListenableBuilder<int>(
          valueListenable: _enteredShares,
          builder: (context, enteredShares, _) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: enteredShares > 0
                      ? AppTheme.primaryColor
                      : Colors.grey, // visually indicate disabled state
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: enteredShares > 0
                    ? () async {
                        if (selectedPayment == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a payment method"),
                            ),
                          );
                          return;
                        }

                        final payment = selectedPayment!;

                        // ✅ Show Sell Summary Dialog and wait for result
                        final refresh = await SellSummaryDialog.show(
                          context: context,
                          movieId: widget.movieId,
                          enteredShares: enteredShares,
                          selectedPayment: payment,
                        );

                        // If payment was successful, refresh parent screenz
                        print("refresh");
                        print(refresh);
                        if (refresh == true) {
                          setState(() {
                            // Reassign new Futures to force FutureBuilder to reload
                            movieFuture = fetchMovieDetails(widget.movieId);
                            shareTypesFuture = fetchShareTypes(widget.movieId);

                            // Clear entered shares and total value
                            _controller.clear();
                            _enteredShares.value = 0;
                            _totalValue.value = 0;

                            // Reset selected payment (optional)
                            selectedPayment = null;
                          });
                        }
                      }
                    : null,

                icon: const Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.white,
                ),
                label: const Text(
                  "Sell Shares",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildSellShareInputRow({
    required BuildContext context,
    required double price,
    required int owned,
    required TextEditingController controller,
    required Function(int) onValidInput,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price per Share: ₹$price",
                style: AppTheme.subtitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Owned Shares: $owned",
                style: AppTheme.subtitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: TextField
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter shares to sell",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.sell),
                  ),
                  onChanged: (val) {
                    final qty = int.tryParse(val) ?? 0;

                    if (qty > owned) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("You only own $owned shares.")),
                      );

                      Future.microtask(() {
                        controller.text = owned.toString();
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      });
                      _enteredShares.value = owned;
                    } else {
                      _enteredShares.value = qty;
                      _totalValue.value = qty * price;
                    }
                  },
                ),
              ),

              const SizedBox(width: 10),

              // RIGHT: Select Payment Gateway Button
              Expanded(
                flex: 1,
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    Future<void> openPaymentSelection() async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SelectPaymentGatewayScreen(),
                        ),
                      );

                      if (result != null && result is Map) {
                        final type = result['type'];
                        final id = result['id'];
                        final name =
                            result['name']; // <- get name/UPI/account number

                        setState(() {
                          selectedPayment = {
                            'type': type,
                            'id': id,
                            'name': name,
                          };
                        });

                        setLocalState(() {}); // refresh local
                      }
                    }

                    return InkWell(
                      onTap: openPaymentSelection,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.payment,
                              color: Colors.black54,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                selectedPayment == null
                                    ? "Select Payment"
                                    : (selectedPayment!['type'] == "upi"
                                          ? "UPI ID #${selectedPayment!['id']}"
                                          : "Bank ID #${selectedPayment!['id']}"),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (selectedPayment != null) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMovieOffersSection(
    BuildContext context,
    Map<String, dynamic> offers,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          // 🔹 Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Allocated Offers for this Movie",
                style: AppTheme.headline2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // 🔹 "View More" Button
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext dialogContext) {
                      return MovieShareOfferWidget(movieId: widget.movieId);
                    },
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "View More",
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

          const SizedBox(height: 10),

          // 🔹 Horizontal Scroll Offers
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                offerCard(
                  "Total Discount",
                  "₹${offers['totalDiscount'] ?? 0}",
                  Colors.purple,
                ),
                offerCard(
                  "Wallet Bonus",
                  "₹${offers['totalWallet'] ?? 0}",
                  Colors.blue,
                ),
                offerCard(
                  "Free Shares",
                  "${offers['totalFreeShare'] ?? 0}",
                  Colors.green,
                ),
                offerCard(
                  "Total Shares",
                  "${offers['totalShare'] ?? 0}",
                  Colors.orange,
                ),
                offerCard(
                  "Platform Commission",
                  (offers['plaftormCommision'] ?? false) ? "Yes" : "No",
                  Colors.red,
                ),
                offerCard(
                  "Profit Commission",
                  (offers['profitCommision'] ?? false) ? "Yes" : "No",
                  Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget offerCard(String title, String value, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMovieCard(Map<String, dynamic> movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Name + View More/Hide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Movie Name
                        Expanded(
                          child: Text(
                            movie['movieName'] ?? 'Untitled Movie',
                            style: AppTheme.headline2.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isExpanded = !isExpanded),
                    child: Row(
                      children: [
                        Text(
                          isExpanded ? "Hide" : "View More",
                          style: TextStyle(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.arrow_forward_ios,
                          size: 11,
                          color: AppTheme.primaryColor.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Invested Amount & Total Shares
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "₹${movie['totalInvestedAmount'] ?? 0}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${movie['totalSharesPurchased'] ?? 0} Shares",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Section
            if (isExpanded)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    Container(
                      width: 120,
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(movie['posterUrl'] ?? ''),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.overlayDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                movie['movieStatus'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Info section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language + Genre
                          Row(
                            children: [
                              Icon(
                                Icons.language,
                                size: 12,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie['language'] ?? 'Unknown',
                                style: AppTheme.subtitle.copyWith(fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.movie_creation_outlined,
                                size: 12,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie['movieType'] ?? '',
                                style: AppTheme.subtitle.copyWith(fontSize: 12),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          // Description
                          Text(
                            movie['description'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Return & Budget
                          Text(
                            "Return: ₹ ${CommonHelper.formatAmount(movie['totalReturn'] ?? 0)}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Budget: ₹ ${CommonHelper.formatAmount(movie['budget'] ?? 0)}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Return & Budget
                          Text(
                            "Trailer: ${movie['trailerDate'] ?? 'Coming soon'}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),

                          if (movie['movieStatus'] != null)
                            CommonHelper.movieStatusBadge(
                              movie['movieStatus'] ?? 'Coming Soon',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------- Existing dialog and helper methods --------------------
}
