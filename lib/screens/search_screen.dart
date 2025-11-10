import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';
import '../screens/movie_buy.dart';

class SearchScreen extends StatefulWidget {
  final String? initialType;
  const SearchScreen({super.key, this.initialType});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bottomSheetController;

  String selectedFilter = "";
  List<dynamic> movies = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int offset = 0;
  final int limit = 6;

  // Filter data
  List<Map<String, dynamic>> languageList = [];
  List<Map<String, dynamic>> genreList = [];
  List<Map<String, dynamic>> statusList = [];

  Set<int> selectedLanguageIds = {};
  Set<int> selectedGenreIds = {};
  Set<int> selectedStatusIds = {};
  Set<String> selectedTypes = {};

  bool isLanguageLoading = false;
  bool isGenreLoading = false;
  bool isStatusLoading = false;

  bool languageFetched = false;
  bool genreFetched = false;
  bool statusFetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null && widget.initialType!.isNotEmpty) {
      selectedTypes.clear();
      selectedTypes.add(widget.initialType!);
    }

    _fetchMovies();
    _scrollController.addListener(_onScroll);

    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _fetchMoreMovies();
    }
  }

  Future<void> _fetchMovies({String? query}) async {
    setState(() {
      offset = 0;
      hasMore = true;
      isLoading = true;
      movies.clear();
    });
    await _loadMovies(query: query);
    setState(() => isLoading = false);
  }

  Future<void> _fetchMoreMovies() async {
    if (!hasMore) return;
    setState(() => isLoadingMore = true);
    offset += limit;
    await _loadMovies(query: searchController.text);
    setState(() => isLoadingMore = false);
  }

  Future<void> _loadMovies({String? query}) async {
    try {
      final body = {
        "languaageIds": selectedLanguageIds.toList(),
        "movieType": selectedGenreIds.toList(),
        "movieStatus": selectedStatusIds.toList(),
        "filterSearchType": selectedTypes.isNotEmpty ? selectedTypes.first : "",
        "offset": offset.toString(),
        "limit": limit.toString(),
        "movieName": query ?? "",
      };

      final result = await ApiService.post(
        ApiEndpoints.searchMovies,
        body: body,
      );

      if (result != null && result.isNotEmpty) {
        List<dynamic> fetched = result;
        setState(() {
          movies.addAll(fetched);
          if (fetched.length < limit) hasMore = false;
        });
      } else {
        setState(() => hasMore = false);
      }
    } catch (e) {
      debugPrint("Error fetching movies: $e");
    }
  }

  // ✅ Lazy-load with proper state refresh
  Future<void> _fetchLanguages(StateSetter setModalState) async {
    if (languageFetched) return;
    setModalState(() => isLanguageLoading = true);
    try {
      final result = await ApiService.get(ApiEndpoints.languages);
      if (result != null && result.isNotEmpty) {
        setModalState(() {
          languageList = List<Map<String, dynamic>>.from(result);
          languageFetched = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching languages: $e");
    } finally {
      setModalState(() => isLanguageLoading = false);
    }
  }

  Future<void> _fetchGenres(StateSetter setModalState) async {
    if (genreFetched) return;
    setModalState(() => isGenreLoading = true);
    try {
      final result = await ApiService.get(ApiEndpoints.genres);
      if (result != null && result.isNotEmpty) {
        setModalState(() {
          genreList = List<Map<String, dynamic>>.from(result);
          genreFetched = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching genres: $e");
    } finally {
      setModalState(() => isGenreLoading = false);
    }
  }

  Future<void> _fetchStatuses(StateSetter setModalState) async {
    if (statusFetched) return;
    setModalState(() => isStatusLoading = true);
    try {
      final result = await ApiService.get(ApiEndpoints.movieStatus);
      if (result != null && result.isNotEmpty) {
        setModalState(() {
          statusList = List<Map<String, dynamic>>.from(result);
          statusFetched = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching statuses: $e");
    } finally {
      setModalState(() => isStatusLoading = false);
    }
  }

  // ---------------- FILTER SHEET ----------------
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: _bottomSheetController,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: MediaQuery.of(context).viewInsets,
          child: _buildFilterBottomSheet(),
        );
      },
    ).whenComplete(() => _bottomSheetController.reset());
  }

  Widget _buildFilterBottomSheet() {
    String activeMenu = "Type";
    final leftMenu = ["Type", "Language", "Genre", "Status"];

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void handleMenuChange(String menu) {
              setModalState(() => activeMenu = menu);
              if (menu == "Language") _fetchLanguages(setModalState);
              if (menu == "Genre") _fetchGenres(setModalState);
              if (menu == "Status") _fetchStatuses(setModalState);
            }

            Widget buildCheckboxList(
              List<Map<String, dynamic>> items,
              Set<int> selectedIds,
              bool isLoading,
            ) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedIds.contains(item["id"]);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setModalState(() {
                        if (selected == true) {
                          selectedIds.add(item["id"]);
                        } else {
                          selectedIds.remove(item["id"]);
                        }
                      });
                    },
                    title: Text(item["name"] ?? "Unknown"),
                    activeColor: AppTheme.primaryColor,
                  );
                },
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Filters",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: Row(
                      children: [
                        // Left Menu
                        Container(
                          width: 130,
                          color: Colors.grey.shade100,
                          child: ListView.builder(
                            itemCount: leftMenu.length,
                            itemBuilder: (context, index) {
                              final menu = leftMenu[index];
                              final isSelected = activeMenu == menu;
                              return InkWell(
                                onTap: () => handleMenuChange(menu),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 12,
                                  ),
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade100,
                                  child: Text(
                                    menu,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Right panel
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Builder(
                              builder: (_) {
                                switch (activeMenu) {
                                  case "Language":
                                    return buildCheckboxList(
                                      languageList,
                                      selectedLanguageIds,
                                      isLanguageLoading,
                                    );
                                  case "Genre":
                                    return buildCheckboxList(
                                      genreList,
                                      selectedGenreIds,
                                      isGenreLoading,
                                    );
                                  case "Status":
                                    return buildCheckboxList(
                                      statusList,
                                      selectedStatusIds,
                                      isStatusLoading,
                                    );
                                  default:
                                    final typeOptions = [
                                      "Recommended",
                                      "Upcoming",
                                      "Box_Office",
                                    ];
                                    return ListView(
                                      children: typeOptions.map((item) {
                                        final isSelected = selectedTypes
                                            .contains(item);
                                        return RadioListTile<String>(
                                          value: item,
                                          groupValue: selectedTypes.isEmpty
                                              ? null
                                              : selectedTypes.first,
                                          onChanged: (val) {
                                            setModalState(() {
                                              selectedTypes.clear();
                                              if (val != null) {
                                                selectedTypes.add(val);
                                              }
                                            });
                                          },
                                          title: Text(item),
                                          activeColor: AppTheme.primaryColor,
                                        );
                                      }).toList(),
                                    );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom buttons (Clear + Apply)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Clear All button (bottom-left)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setModalState(() {
                                selectedTypes.clear();
                                selectedLanguageIds.clear();
                                selectedGenreIds.clear();
                                selectedStatusIds.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(
                              Icons.clear_all,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "Clear All",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Apply Filter button (bottom-right)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _fetchMovies(query: searchController.text);
                            },
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => _fetchMovies(query: value),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    hintText: 'Search movies...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: _showFilterSheet,
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : movies.isEmpty
          ? const Center(child: Text("No movies found"))
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 8, // tighter spacing
                mainAxisExtent: 165, // exact card height
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return SizedBox(
                  height: 220, // ✅ fixed height card container
                  child: _buildMovieCard(movie),
                );
              },
            ),
    );
  }

  String _formatAmount(num value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${value.toStringAsFixed(0)}';
    }
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final double budget = (movie['budget'] ?? 0).toDouble();
    final double invested = (movie['investedAmount'] ?? 0).toDouble();
    final double progress = budget > 0
        ? (invested / budget).clamp(0.0, 1.0)
        : 0.0;

    String formatAmount(double amount) {
      if (amount >= 10000000)
        return "${(amount / 10000000).toStringAsFixed(2)} Cr";
      if (amount >= 100000) return "${(amount / 100000).toStringAsFixed(2)} L";
      if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(1)} K";
      return amount.toStringAsFixed(0);
    }

    // Release Date Logic
    String releaseText = "Coming Soon";
    int diffDays = 9999;
    final String? releaseDateStr = movie['releaseDate'];
    if (releaseDateStr != null && releaseDateStr.isNotEmpty) {
      try {
        final releaseDate = DateTime.parse(releaseDateStr);
        final now = DateTime.now();
        diffDays = releaseDate.difference(now).inDays;
        if (diffDays > 0) {
          if (diffDays <= 3)
            releaseText = "🔥 Releases in $diffDays days";
          else if (diffDays <= 7)
            releaseText = "⏰ Only $diffDays days left";
          else
            releaseText = "📅 Releases in $diffDays days";
        } else if (diffDays == 0)
          releaseText = "🎉 Releasing Today!";
        else
          releaseText = "✅ Released ${diffDays.abs()} days ago";
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieBuyScreen(movieId: movie['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster + overlay
              Stack(
                children: [
                  Image.network(
                    movie["posterUrl"] ?? "",
                    width: 100,
                    height: 155,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 155,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.movie_creation_outlined,
                        color: Colors.grey,
                        size: 36,
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 155,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Circular progress badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3.5,
                            backgroundColor: Colors.white24,
                            color: AppTheme.primaryColor,
                          ),
                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (diffDays <= 7)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "HOT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie["title"] ?? "Untitled Movie",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${movie["movieTypeName"] ?? ''} • ${movie["language"] ?? ''}",
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie['status'] ?? '',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color:
                              (movie['status']?.toString().toLowerCase() ==
                                  'active')
                              ? Colors.green
                              : Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Invested & Budget
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "₹${formatAmount(invested)}",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "₹${formatAmount(budget)}",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: (diffDays <= 7)
                                    ? AppTheme.primaryColor.withOpacity(0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                releaseText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MovieBuyScreen(movieId: movie['id']),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                "Invest Now",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
