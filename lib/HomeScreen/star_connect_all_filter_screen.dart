import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/AppTheme.dart';
import '../services/api_service.dart';
import '../constants/api_endpoints.dart';

class StarConnectAllScreen extends StatefulWidget {
  const StarConnectAllScreen({super.key});

  @override
  State<StarConnectAllScreen> createState() => _StarConnectAllScreenState();
}

class _StarConnectAllScreenState extends State<StarConnectAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> allOffers = [];
  List<Map<String, dynamic>> filteredOffers = [];

  bool isLoading = false;
  bool showFilterPanel = false;

  // offer types fetched from backend. Each item: { "id": 1, "name": "Act in Movie", "selected": false, "iconUrl": "..."}
  List<Map<String, dynamic>> offerTypes = [];

  @override
  void initState() {
    super.initState();
    // load filter types first, then offers
    fetchOfferTypes().then((_) => fetchOffers());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // placeholder for pagination if you want to enable later
        debugPrint("Reached near bottom – ready for pagination 🔽");
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Fetch available offer types from server
  /// Response expected like:
  /// { "status":"success", "message":"success", "result": [ { "id":3, "name":"Meet & Greet", ... }, ... ] }
  Future<void> fetchOfferTypes() async {
    try {
      final response = await ApiService.get(
        ApiEndpoints
            .movieStarConnectOfferTypes, // <--- replace if your constant name differs
      );

      if (response is List) {
        // if ApiService returns the list directly
        final types = List<Map<String, dynamic>>.from(response);
        setState(() {
          offerTypes = types
              .map(
                (t) => {
                  "id": t["id"],
                  "name": t["name"],
                  "iconUrl": t["iconUrl"] ?? "",
                  "selected": false,
                },
              )
              .toList();
        });
      } else if (response is Map && response["result"] is List) {
        final types = List<Map<String, dynamic>>.from(response["result"]);
        setState(() {
          offerTypes = types
              .map(
                (t) => {
                  "id": t["id"],
                  "name": t["name"],
                  "iconUrl": t["iconUrl"] ?? "",
                  "selected": false,
                },
              )
              .toList();
        });
      } else {
        debugPrint("⚠️ Unexpected offer types response: $response");
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching offer types: $e");
    }
  }

  /// Fetch offers from server. If offerIds provided, they will be included in payload.
  /// Server side will filter results (search and offerIds) and return matching offers.
  Future<void> fetchOffers({List<int>? offerIds, String? search}) async {
    setState(() => isLoading = true);
    try {
      final Map<String, dynamic> payload = {
        "offset": 0,
        "limit": 10,
        if (offerIds != null && offerIds.isNotEmpty) "offerIds": offerIds,
        if (search != null && search.isNotEmpty) "search": search,
      };

      final response = await ApiService.post(
        ApiEndpoints.movieStarConnectOffer,
        body: payload,
      );

      if (response is List) {
        final offers = List<Map<String, dynamic>>.from(response);
        setState(() {
          allOffers = offers;
          filteredOffers = offers; // server already filtered
        });
      } else if (response is Map && response["result"] is List) {
        final offers = List<Map<String, dynamic>>.from(response["result"]);
        setState(() {
          allOffers = offers;
          filteredOffers = offers;
        });
      } else {
        debugPrint("⚠️ Unexpected offers response: $response");
        setState(() {
          allOffers = [];
          filteredOffers = [];
        });
      }
    } catch (e) {
      debugPrint("⚠️ Fetch error: $e");
      setState(() {
        allOffers = [];
        filteredOffers = [];
      });
    }
    setState(() => isLoading = false);
  }

  // Toggle filter panel visibility
  void _toggleFilterPanel() {
    setState(() => showFilterPanel = !showFilterPanel);
  }

  // Called when the user taps "Apply Filter" — collects selected ids and calls server
  void _applyFilterAndClose() {
    final selectedIds = offerTypes
        .where((t) => t["selected"] == true)
        .map<int>((t) => (t["id"] as num).toInt())
        .toList();

    fetchOffers(offerIds: selectedIds, search: _searchController.text);
    setState(() => showFilterPanel = false);
  }

  // Clear all filters and refetch all offers
  void _clearFilters() {
    setState(() {
      for (var t in offerTypes) {
        t["selected"] = false;
      }
      showFilterPanel = false;
    });
    fetchOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              // server-side search: call fetchOffers with current selected ids
              final selectedIds = offerTypes
                  .where((t) => t["selected"] == true)
                  .map<int>((t) => (t["id"] as num).toInt())
                  .toList();
              fetchOffers(offerIds: selectedIds, search: value);
            },
            decoration: const InputDecoration(
              hintText: "Search offer or movie name...",
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded, color: Colors.black),
            onPressed: _toggleFilterPanel,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🧾 Offer List
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredOffers.isEmpty
              ? const Center(child: Text("No offers found"))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredOffers.length,
                  itemBuilder: (context, index) {
                    final offer = filteredOffers[index];
                    return _buildOfferCard(offer);
                  },
                ),

          // 🎚️ LEFT-side Filter Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: showFilterPanel ? 0 : -320, // widen to 320 for more room
            top: 0,
            bottom: 0,
            child: Container(
              width: 320,
              color: AppTheme.accentColor.withOpacity(0.95),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter by Offer Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleFilterPanel,
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: offerTypes.isEmpty
                          ? const Center(child: Text("No filter types"))
                          : ListView.builder(
                              itemCount: offerTypes.length,
                              itemBuilder: (context, i) {
                                final t = offerTypes[i];
                                return CheckboxListTile(
                                  activeColor: AppTheme.primaryColor,
                                  title: Text(t["name"] ?? ""),
                                  secondary:
                                      (t["iconUrl"] ?? "").toString().isNotEmpty
                                      ? SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.network(
                                              _normalizeIconUrl(t["iconUrl"]),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: AppTheme.primaryColor
                                                        .withOpacity(0.2),
                                                  ),
                                            ),
                                          ),
                                        )
                                      : null,
                                  value: t["selected"] == true,
                                  onChanged: (val) {
                                    setState(() {
                                      t["selected"] = val ?? false;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _applyFilterAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("Apply Filter"),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text(
                        "Clear All",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Utility: ensure iconUrl is absolute if backend returns relative path
  String _normalizeIconUrl(dynamic iconUrl) {
    if (iconUrl == null) return '';
    final s = iconUrl.toString();
    if (s.startsWith('http')) return s;
    // change base to your server if needed
    return 'http://localhost:8000${s.startsWith('/') ? s : '/$s'}';
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final String title = offer['title'] ?? 'No Title';
    final String subtitle = offer['subtitle'] ?? '';
    final String details = offer['details'] ?? '';
    final String movieName = offer['movieName'] ?? '';
    final String iconUrl = offer['iconUrl'] ?? '';

    return Card(
      elevation: 4,
      shadowColor: AppTheme.shadowColor,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _normalizeIconUrl(iconUrl),
                width: 150,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 150,
                  height: 130,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.black54,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🎁 $title',
                    style: AppTheme.headline2.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🎬 $movieName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.subtitle.copyWith(color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    details,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
