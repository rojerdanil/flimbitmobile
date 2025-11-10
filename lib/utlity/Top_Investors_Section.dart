import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../theme/AppTheme.dart';
import '../screens/movie_buy.dart';

class TopInvestorsSection extends StatefulWidget {
  const TopInvestorsSection({super.key});

  @override
  State<TopInvestorsSection> createState() => _TopInvestorsSectionState();
}

class _TopInvestorsSectionState extends State<TopInvestorsSection>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> investors = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int offset = 0;
  final int limit = 5;
  bool hasMore = true;

  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _fetchTopInvestors();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _fetchMoreInvestors();
    }
  }

  Future<void> _fetchTopInvestors() async {
    setState(() => isLoading = true);
    await _loadInvestors();
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreInvestors() async {
    setState(() => isLoadingMore = true);
    offset += limit;
    await _loadInvestors();
    setState(() => isLoadingMore = false);
  }

  Future<void> _loadInvestors() async {
    try {
      final payload = {"offset": offset, "limit": limit};
      final result = await ApiService.post(
        ApiEndpoints.topInvestors,
        body: payload,
      );
      if (result is List && result.isNotEmpty) {
        setState(() {
          investors.addAll(List<Map<String, dynamic>>.from(result));
          if (result.length < limit) hasMore = false;
        });
      } else {
        setState(() => hasMore = false);
      }
    } catch (e) {
      debugPrint("Error fetching investors: $e");
    }
  }

  String formatInvested(num? amount) {
    if (amount == null || amount <= 0) return "₹0";
    if (amount >= 10000000)
      return "₹${(amount / 10000000).toStringAsFixed(2)} Cr";
    if (amount >= 100000) return "₹${(amount / 100000).toStringAsFixed(2)} L";
    return "₹${amount.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    final double coinSize = MediaQuery.of(context).size.width * 0.20;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "💰 Top Investors",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 70, // adjust underline width as you like
                        height: 3, // thickness
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                /*     TextButton(
                  onPressed: () {},
                  child: Text(
                    "View All",
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),*/
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (investors.isEmpty)
            const Center(child: Text("No top investors found"))
          else
            SizedBox(
              height: coinSize + 45,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemCount: investors.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == investors.length && isLoadingMore) {
                    return const SizedBox(
                      width: 80,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final investor = investors[index];
                  return GestureDetector(
                    onTap: () => _showInvestorPopup(investor),
                    child: _buildThemeCoinCard(investor, coinSize),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeCoinCard(Map<String, dynamic> investor, double size) {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        final double shineValue = _shineController.value;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Themed Coin
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  startAngle: 0,
                  endAngle: 6.28319,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.7),
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.6),
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                  stops: [0.0, shineValue, shineValue + 0.25, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: ClipOval(
                  child:
                      investor["profilePicUrl"] != null &&
                          investor["profilePicUrl"].toString().isNotEmpty
                      ? Image.network(
                          investor["profilePicUrl"],
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 45),
                ),
              ),
            ),

            // Texts below
            Positioned(
              bottom: -12,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      investor["userName"] ?? "Investor",
                      style: AppTheme.subtitle.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.9),
                          AppTheme.primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      formatInvested(investor["totalInvested"]),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 💫 Themed Popup
  Future<void> _showInvestorPopup(Map<String, dynamic> investor) async {
    try {
      // Show loading dialog while fetching data
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 🔹 Fetch investor movie investments from backend
      final response = await ApiService.get(ApiEndpoints.usertopInvestedMovies);

      Navigator.pop(context); // Close loading dialog

      List<dynamic> movies = [];
      if (response != null && response is List) {
        movies = response;
      }

      // 🔹 Now show bottom popup with real data
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withOpacity(0.9), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🧑‍💼 Investor Info
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: investor["profilePicUrl"] != null
                          ? NetworkImage(investor["profilePicUrl"])
                          : null,
                      child: investor["profilePicUrl"] == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      investor["userName"] ?? "Investor",
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Total Invested: ${formatInvested(investor["totalInvested"])}",
                      style: AppTheme.subtitle,
                    ),
                    const SizedBox(height: 16),

                    // 🎬 Movie List
                    Text(
                      "🎬 Top Movie Investments",
                      style: AppTheme.goldTitle.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (movies.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("No movie investments found"),
                      )
                    else
                      ...movies.map((m) {
                        return Card(
                          color: Colors.white,
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.2,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.movie,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(m["movieName"]),
                            subtitle: Text(
                              "Invested: ${formatInvested(m["totalInvestedAmount"])} | Shares: ${m["totalSharesPurchased"]}",
                              style: AppTheme.subtitle,
                            ),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                              ),
                              label: const Text(
                                "View",
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MovieBuyScreen(
                                      movieId: m["movieId"],
                                      menu: "Movie",
                                      submenu: "Top Investor",
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // Close dialog if error occurs
      debugPrint("Error fetching investor movie data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load investor data")),
      );
    }
  }
}
