import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';

class SearchWardsSidebar extends StatefulWidget {
  final bool isVisible;
  final double leftPosition;
  final VoidCallback onClose;
  final void Function(double lat, double lng, String displayName)? onLocationSelected;

  const SearchWardsSidebar({
    super.key,
    required this.isVisible,
    required this.leftPosition,
    required this.onClose,
    this.onLocationSelected,
  });

  @override
  State<SearchWardsSidebar> createState() => _SearchWardsSidebarState();
}

class _SearchWardsSidebarState extends State<SearchWardsSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSearchActive = false;
  Timer? _debounce;

  static const List<String> _wards = [
    'Mirihana South', 'Mirihana North', 'Madiwela', 'Pragathipura', 'Udahamulla',
    'Thalapathpitiya', 'Pamunuwa', 'Thalawathugoda', 'Kalalgoda', 'Depanama',
    'Kottawa West', 'Kottawa East', 'Rukmale', 'Makumbura', 'Kottawa South',
    'Kottawa Town', 'Pannipitiya', 'Maharagama South', 'Maharagama North',
    'Pathiragoda', 'Navinna', 'Gangodavila', 'Wattegedara', 'Godigamuwa North',
    'Godigamuwa South',
  ];

  double get _currentWidth => widget.isVisible ? 420.0 : 0.0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant SearchWardsSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      // Auto-focus search when opened
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
    if (!widget.isVisible && oldWidget.isVisible) {
      _clearSearch();
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
      _isSearchActive = false;
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    setState(() => _isSearchActive = true);
    _searchFocusNode.unfocus();
    _searchAddress(query);
  }

  Future<void> _searchAddress(String query, {bool isAutoSearch = false}) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=8&countrycodes=lk',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'LuminaLanka/1.0 (Flutter App)',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data.map((item) => {
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
              'display_name': item['display_name'] as String,
            }).toList();
            _isSearching = false;
            if (isAutoSearch && _searchResults.isNotEmpty) {
              _isSearchActive = true;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
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

                      // Content: Search Results OR Wards List
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _isSearchActive || _searchController.text.isNotEmpty
                              ? _buildSearchResults()
                              : _buildWardsList(),
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
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? const Color(0xFF0A84FF).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.search, color: Colors.white.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 2),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (value.trim().isNotEmpty) {
                    _searchAddress(value, isAutoSearch: true);
                  } else {
                    setState(() {
                      _isSearchActive = false;
                      _searchResults.clear();
                    });
                  }
                });
              },
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: const Icon(CupertinoIcons.clear_thick_circled, color: Colors.white54, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildWardsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            'Maharagama Urban Council Wards',
            style: TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _wards.length,
            itemBuilder: (context, index) {
              return _buildWardTile(
                wardName: _wards[index],
                wardNumber: index + 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWardTile({required String wardName, required int wardNumber}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _searchController.text = '$wardName, Maharagama';
          _onSearchSubmitted('$wardName, Maharagama');
        },
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
                decoration: const BoxDecoration(
                  color: Color(0xFF0A84FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.location_solid, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Ward $wardNumber - $wardName',
                  style: const TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No results found',
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onLocationSelected?.call(
                result['lat'],
                result['lon'],
                result['display_name'],
              );
              _clearSearch();
              widget.onClose();
            },
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
                    child: Text(
                      result['display_name'],
                      style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
