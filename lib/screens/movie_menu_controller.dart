import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';

// Import all your sub-section widgets
import '../screens/actors.dart';
import '../screens/movie_view_top_invester.dart';
import '../screens/movie_view_top_proftit_holder.dart';
import '../screens/movie_view_winners.dart';
import '../screens/movie_view_offers_start_connect.dart';
import '../screens/movie_view_flimBit_offer.dart';
import '../screens/movie_view_cinema_news.dart';
import '../screens/movie_view_cinema_collection.dart';
import '../screens/movie_view_transection.dart';

class MovieMenuController extends ChangeNotifier {
  String selectedMainTab = 'Movie';
  String selectedSubTab = 'Actors';
  String selectedOfferSubTab = 'Star Connect';
  String selectedNewsSubTab = 'Cinema';

  // 🔸 Called when switching between top tabs
  void selectMainTab(String tab) {
    selectedMainTab = tab;

    switch (tab) {
      case 'Movie':
        selectedSubTab = 'Actors';
        break;
      case 'Offers':
        selectedOfferSubTab = 'Star Connect';
        break;
      case 'News':
        selectedNewsSubTab = 'Cinema';
        break;
    }
    notifyListeners();
  }

  // 🔸 Called when sub tab is clicked
  void selectSubTab(String tab) {
    switch (selectedMainTab) {
      case 'Movie':
        selectedSubTab = tab;
        break;
      case 'Offers':
        selectedOfferSubTab = tab;
        break;
      case 'News':
        selectedNewsSubTab = tab;
        break;
    }
    notifyListeners();
  }

  // 🔸 Returns sub-tabs for the selected main tab
  List<String> getSubTabs() {
    switch (selectedMainTab) {
      case 'Movie':
        return ['Actors', 'Top Investor', 'Profit Holder', 'Winner'];
      case 'Offers':
        return ['Star Connect', 'FlimBit'];
      case 'News':
        return ['Cinema', 'Collection Report'];
      case 'Transection':
        return [];
      default:
        return [];
    }
  }

  // 🔸 Returns the currently active sub tab
  String get activeSubTab {
    switch (selectedMainTab) {
      case 'Movie':
        return selectedSubTab;
      case 'Offers':
        return selectedOfferSubTab;
      case 'News':
        return selectedNewsSubTab;
      default:
        return '';
    }
  }

  // 🔸 Returns the widget to display in tab content area
  Widget getTabContent(int movieId) {
    switch (selectedMainTab) {
      case 'Movie':
        switch (selectedSubTab) {
          case 'Actors':
            return ActorsSection(movieId: movieId);
          case 'Top Investor':
            return TopInvestorsSection(movieId: movieId);
          case 'Profit Holder':
            return TopProfitHoldersSection(movieId: movieId);
          case 'Winner':
            return StartOfferScreenWinner(movieId: movieId);
        }
        break;

      case 'Offers':
        if (selectedOfferSubTab == 'Star Connect') {
          return StartOfferScreen(movieId: movieId);
        } else {
          return FilmBitOfferScreen(movieId: movieId);
        }

      case 'News':
        if (selectedNewsSubTab == 'Cinema') {
          return CinemaNewsScreen(movieId: movieId);
        } else {
          return CollectionReportScreen(movieId: movieId);
        }

      case 'Transection':
        return TransactionReportScreen(movieId: movieId);
    }

    return const SizedBox();
  }

  // 🔸 Sub tab bar widget (for reuse in screen)
  Widget buildSubTabBar(VoidCallback rebuild) {
    final tabs = getSubTabs();
    final active = activeSubTab;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const SizedBox(width: 40),
          ...tabs.map((tab) {
            final isSelected = active == tab;
            return GestureDetector(
              onTap: () {
                selectSubTab(tab);
                rebuild();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
