import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/google_places_service.dart';

class SearchWardsSidebar extends StatefulWidget {
  final bool isVisible;
  final double leftPosition;
  final VoidCallback onClose;
  final void Function(double lat, double lng, String displayName)? onLocationSelected;
  final List<Map<String, dynamic>> poleDataList;
  final void Function(Map<String, dynamic> pole)? onPoleSelected;
  final double? userLat;
  final double? userLon;

  const SearchWardsSidebar({
    super.key,
    required this.isVisible,
    required this.leftPosition,
    required this.onClose,
    this.onLocationSelected,
    this.poleDataList = const [],
    this.onPoleSelected,
    this.userLat,
    this.userLon,
  });

  @override
  State<SearchWardsSidebar> createState() => _SearchWardsSidebarState();
}

class _SearchWardsSidebarState extends State<SearchWardsSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlacePrediction> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _sessionToken = GooglePlacesService.generateSessionToken();
  List<Map<String, dynamic>> _nearestPoles = [];
  final Map<String, String> _poleLocations = {}; // pole id -> location name


  double get _currentWidth => widget.isVisible ? 420.0 : 0.0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _computeNearestPoles();
  }

  @override
  void didUpdateWidget(covariant SearchWardsSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
      _computeNearestPoles();
    }
    if (!widget.isVisible && oldWidget.isVisible) {
      _clearSearch();
    }
    if (widget.poleDataList.length != oldWidget.poleDataList.length ||
        widget.userLat != oldWidget.userLat ||
        widget.userLon != oldWidget.userLon) {
      _computeNearestPoles();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
    // Reset session token for next search session
    _sessionToken = GooglePlacesService.generateSessionToken();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void _computeNearestPoles() {
    if (widget.poleDataList.isEmpty) return;
    final refLat = widget.userLat;
    final refLon = widget.userLon;
    if (refLat == null || refLon == null) return;

    final sorted = List<Map<String, dynamic>>.from(widget.poleDataList);
    sorted.sort((a, b) {
      final dA = _haversine(refLat, refLon, a['latitude'] as double, a['longitude'] as double);
      final dB = _haversine(refLat, refLon, b['latitude'] as double, b['longitude'] as double);
      return dA.compareTo(dB);
    });

    final top5 = sorted.take(5).toList();
    if (mounted) setState(() => _nearestPoles = top5);

    // Reverse geocode each pole
    for (final pole in top5) {
      final id = pole['id'] as String;
      if (!_poleLocations.containsKey(id)) {
        _reverseGeocodePoleLocation(id, pole['latitude'] as double, pole['longitude'] as double);
      }
    }
  }

  Future<void> _reverseGeocodePoleLocation(String poleId, double lat, double lon) async {
    try {
      final uri = Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lon');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>;
          final street = props['street'] ?? '';
          final city = props['city'] ?? props['town'] ?? props['village'] ?? '';
          final loc = [street, city].where((s) => s.toString().isNotEmpty).join(', ');
          if (mounted && loc.isNotEmpty) {
            setState(() => _poleLocations[poleId] = loc);
          }
        }
      }
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // 300ms debounce for snappy feel
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    final results = await GooglePlacesService.autocomplete(
      query,
      sessionToken: _sessionToken,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _selectResult(PlacePrediction prediction) async {
    HapticFeedback.mediumImpact();

    if (prediction.lat != null && prediction.lon != null) {
      widget.onLocationSelected?.call(
        prediction.lat!,
        prediction.lon!,
        prediction.description,
      );
    }

    _clearSearch();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: widget.leftPosition,
      top: 16,
      bottom: 16,
      width: _currentWidth,
      child: GlassmorphicContainer(
        width: _currentWidth,
        height: double.infinity,
        borderRadius: 24,
        blur: 14,
        alignment: Alignment.topCenter,
        border: 1.0,
        linearGradient: LinearGradient(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, 1.0),
          colors: [
            const Color(0xFF1E1E1E).withValues(alpha: 0.75),
            const Color(0xFF1E1E1E).withValues(alpha: 0.85),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !widget.isVisible
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: "Search" title + Close button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Search',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onClose();
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.xmark,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSearchBar(),
                      ),

                      const SizedBox(height: 16),

                      // Content: Search Results + Nearest Poles below
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            // Search results first (when typing)
                            if (_searchController.text.isNotEmpty) ...
                              _buildSearchResultsList(),
                            // Nearest streetlight recommendations below
                            if (_nearestPoles.isNotEmpty)
                              _buildNearestPolesSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchFocusNode,
      builder: (context, child) {
        final bool isFocused = _searchFocusNode.hasFocus;
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isFocused ? const Color(0xFF0A84FF) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.search, color: Colors.white.withOpacity(0.4), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  cursorColor: const Color(0xFF0A84FF),
                  style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.4), fontSize: 16),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    contentPadding: const EdgeInsets.fromLTRB(2, 12, 0, 12), // Align text closer to icon and center vertically
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearSearch,
                  child: Icon(CupertinoIcons.xmark_circle_fill, color: Colors.white.withOpacity(0.4), size: 18),
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildNearestPolesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Nearby Streetlights',
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._nearestPoles.map((pole) {
            final id = pole['id'] as String;
            final location = _poleLocations[id] ?? '';
            final dist = _haversine(
              widget.userLat!, widget.userLon!,
              pole['latitude'] as double, pole['longitude'] as double,
            );
            final distText = dist < 1000
                ? '${dist.toInt()}m away'
                : '${(dist / 1000).toStringAsFixed(1)}km away';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.isNotEmpty ? location : 'Streetlight',
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            distText,
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onPoleSelected?.call(pole);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'GO',
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResultsList() {
    if (_isSearching) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
          ),
        ),
      ];
    }

    if (_searchResults.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No results found',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      ];
    }

    return _searchResults.map((prediction) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
        child: InkWell(
          onTap: () => _selectResult(prediction),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.location_solid, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.mainText,
                        style: const TextStyle(
                          fontFamily: 'GoogleSansFlex',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (prediction.secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          prediction.secondaryText,
                          style: TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
