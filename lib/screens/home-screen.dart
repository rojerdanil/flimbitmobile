import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../screens/user_share.dart';
import '../screens/portfolio_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notificationScreen.dart';
import '../screens/home_menu.dart';

// Assume this is your Home tab content
import '../utlity/WinnersSection.dart';
import '../utlity/Upcoming_Movies_Section.dart';
import '../utlity/Top_Investors_Section.dart';
import '../utlity/BoxOffice_Live_Section.dart';
import '../utlity/Top_Profit_Holder_Section.dart';
import '../utlity/Recommanded_Movie_Section.dart';
import '../utlity/poster_slider.dart';
import '../utlity/Live_News_Marquee.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/search_screen.dart';
import '../HomeScreen/star_connect_zone.dart.dart';
import '../HomeScreen/investment_insights.dart';
import '../HomeScreen/cinema_buzz.dart';
import '../HomeScreen/producer_spotlight.dart';
import '../helper/Lazy_Section_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int notificationCount = 0;
  int numberOfUsers = 0;
  int investedAmount = 0; // 1.25 crore example

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
    _fetchDashboardStats();
    // Pulse animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final result = await ApiService.get(ApiEndpoints.movieSummaryCounts);
      if (result.isNotEmpty) {
        setState(() {
          numberOfUsers = result['totalUser'] ?? 0;
          investedAmount = (result['totalInvested'] ?? 0).toInt();
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final result = await ApiService.get(ApiEndpoints.userNotificationCount);
      if (result.isNotEmpty) {
        setState(() {
          notificationCount = int.tryParse(result['value'] ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      if (_selectedIndex == 0) {
        _fetchNotificationCount();
      }
    }
  }

  Widget _getBodyWidget() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const MovieListScreen();
      case 2:
        return const PortfolioScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          LazySectionLoader(builder: (_) => HomeMenu()),
          LazySectionLoader(builder: (_) => PosterSlider()),
          LazySectionLoader(builder: (_) => StarConnectZone()),
          LazySectionLoader(builder: (_) => RecommendedMovie()),
          LazySectionLoader(builder: (_) => UpcomingMoviesSection()),
          LazySectionLoader(builder: (_) => CinemaBuzz()),
          LazySectionLoader(builder: (_) => BoxOfficeLiveSection()),
          LazySectionLoader(builder: (_) => TopInvestorsSection()),
          LazySectionLoader(builder: (_) => ProducerSpotlight()),
          LazySectionLoader(builder: (_) => WinnersSection()),
          LazySectionLoader(builder: (_) => InvestmentInsights()),
          LazySectionLoader(builder: (_) => TopProfitHolderSection()),
        ],
      ),
    );
  }

  // Helper to format numbers in k, lakh, crore
  String formatIndianNumber(int value) {
    if (value >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(2)} Cr";
    } else if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(2)} L";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    } else {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 1,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side: Welcome text + badges
                    Row(
                      children: [
                        const Text(
                          "Welcome to FilmBit",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Users Badge
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.shade700.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: numberOfUsers),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Text(
                                      "${value.toString()} users",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Invested Badge
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade600.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(
                                    begin: 0,
                                    end: investedAmount,
                                  ),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Text(
                                      formatIndianNumber(value),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Right side: Search & Notification icons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.black,
                            size: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchScreen(),
                              ),
                            );
                          },
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.black,
                                size: 28,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen(),
                                  ),
                                );
                              },
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$notificationCount",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _getBodyWidget(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share_outlined),
            activeIcon: Icon(Icons.share),
            label: 'My Share',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
