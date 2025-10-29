import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
  final int limit = 10;

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
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: movies.length + (isLoadingMore ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.65,
              ),
              itemBuilder: (context, index) {
                if (index == movies.length && isLoadingMore) {
                  return const Center(child: CircularProgressIndicator());
                }
                final movie = movies[index];
                return _buildMovieCard(movie);
              },
            ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final double budget = (movie['budget'] ?? 0).toDouble();
    final double invested = (movie['investedAmount'] ?? 0).toDouble();
    final double progress = budget > 0
        ? (invested / budget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Stack(
              children: [
                Image.network(
                  movie["posterUrl"] ?? "",
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.white.withOpacity(0.9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress: ${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade300,
                          color: AppTheme.primaryColor,
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie["title"] ?? "Untitled",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${movie["perShareAmount"] ?? 0}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  movie["movieTypeName"] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
