/// Lumina Lanka - Unified Glass Sheet
/// iOS 26 "Liquid Glass" aesthetic using glassmorphism package
/// Cross-platform: Linux, Web, iOS, Android
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:http/http.dart' as http;

/// Unified Glass Sheet - Dark frosted "Floating Island" bottom panel
/// Now with integrated search functionality
class UnifiedGlassSheet extends StatefulWidget {
  final int? selectedActionIndex;
  final ValueChanged<int>? onActionSelected;
  final void Function(double lat, double lng, String displayName)? onLocationSelected;
  final double? width; // Optional width override
  final ValueChanged<bool>? onFocusChange; // New callback
  final ValueChanged<bool>? onSearchModeChanged; // New callback

  const UnifiedGlassSheet({
    super.key,
    this.selectedActionIndex,
    this.onActionSelected,
    this.onLocationSelected,
    this.width,
    this.onFocusChange,
    this.onSearchModeChanged,
  });

  @override
  State<UnifiedGlassSheet> createState() => _UnifiedGlassSheetState();
}

class _UnifiedGlassSheetState extends State<UnifiedGlassSheet> {
  // Height state
  double _currentHeight = 78.0;
  static const double _minHeight = 78.0;
  static const double _maxHeight = 400.0; // Taller for search results

  // Search state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    widget.onFocusChange?.call(_searchFocusNode.hasFocus);
    // Removed auto-resize on focus logic
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ... (skip lines) ...

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    
    // Notify parent
    widget.onSearchModeChanged?.call(true);

    // Expand to show results
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      _currentHeight = screenHeight * 0.7; // 70% of screen height
      _isSearchMode = true;
    });

    _searchFocusNode.unfocus(); // Dismiss keyboard to see results
    _searchAddress(query);
  }

  void _exitSearchMode() {
    _debounce?.cancel();
    
    // Notify parent
    widget.onSearchModeChanged?.call(false);

    setState(() {
      _isSearchMode = false;
      _currentHeight = _minHeight;
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  Future<void> _searchAddress(String query, {bool isAutoSearch = false}) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=lk',
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
            
            // Auto-expand if we have results during auto-search
            if (isAutoSearch && _searchResults.isNotEmpty) {
              final screenHeight = MediaQuery.of(context).size.height;
              _currentHeight = screenHeight * 0.7;
              _isSearchMode = true;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7; // Dynamic max height
    
    // Use provided width or default to 75% of screen (narrower)
    final targetWidth = widget.width ?? (screenWidth * 0.75);

    // Dynamic border radius
    final dynamicRadius = 50.0 - ((_currentHeight - _minHeight) / (maxHeight - _minHeight)) * 30;

    return GestureDetector(
      onVerticalDragUpdate: _isSearchMode ? null : (details) {
        setState(() {
          _currentHeight -= details.delta.dy;
          _currentHeight = _currentHeight.clamp(_minHeight, maxHeight);
        });
      },
      onVerticalDragEnd: _isSearchMode ? null : (details) {
        setState(() {
          if (_currentHeight > (_minHeight + maxHeight) / 2) {
            _currentHeight = maxHeight;
            _isSearchMode = true; // Treating manual expansion as search mode
          } else {
            _currentHeight = _minHeight;
            _isSearchMode = false;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic, // Smoother curve
        width: targetWidth,
        height: _currentHeight,
        alignment: Alignment.topCenter,
        child: GlassmorphicContainer(
          width: targetWidth,
          height: _currentHeight,
          borderRadius: _currentHeight == _minHeight ? _minHeight / 2 : dynamicRadius, // Perfect Pill when collapsed
          blur: 35, // True iOS-style thick acrylic blur 
          alignment: Alignment.topCenter, // Align content to start at top and grow down
          border: 1.5,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C1C1E).withValues(alpha: 0.65), // iOS System Elevated Background
              const Color(0xFF1C1C1E).withValues(alpha: 0.55),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          child: Column(
            children: [
              // Search Bar Top Padding
              const SizedBox(height: 16),

              // Search Bar (Always Editable Now)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildEditableSearchBar(),
              ),

              // Search Results (Only visible when expanded/search mode)
              if (_currentHeight > _minHeight + 20)
                Expanded(
                  child: _buildSearchResults(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _buildTappableSearchBar as requested - always editable now

  Widget _buildEditableSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9.0, sigmaY: 9.0),
        child: Container(
          height: 44, // Reduced height (was 52)
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3C).withValues(alpha: 0.4), // Elevate 3 Search Bar
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: _searchFocusNode.hasFocus 
                  ? const Color(0xFF0A84FF).withValues(alpha: 0.8) // iOS Blue
                  : Colors.white.withValues(alpha: 0.1),
              width: _searchFocusNode.hasFocus ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
                const Icon(CupertinoIcons.search, color: Color(0xFF0A84FF), size: 18), // iOS Blue Search Icon
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15), // Slightly smaller text
                    textInputAction: TextInputAction.search, // Show 'Search' button on keyboard
                    decoration: InputDecoration(
                      hintText: 'Search Maps',
                      hintStyle: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white38),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (value.trim().isNotEmpty) {
                           _searchAddress(value, isAutoSearch: true);
                        }
                      });
                    },
                    onSubmitted: _onSearchSubmitted,
                    onTap: () {
                      // Just focus, don't expand yet
                      setState(() {});
                    },
                  ),
                ),
                // Close/Clear button
                if (_searchController.text.isNotEmpty || _isSearchMode)
                  GestureDetector(
                    onTap: _exitSearchMode,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.xmark, color: Colors.white54, size: 14),
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
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)), // iOS Blue Spinner
        ),
      );
    }

    if (_searchResults.isEmpty && _isSearchMode) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No results found',
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          leading: const Icon(CupertinoIcons.location_solid, color: Color(0xFF0A84FF), size: 22), // iOS Blue Marker
          title: Text(
            result['display_name'],
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onLocationSelected?.call(
              result['lat'],
              result['lon'],
              result['display_name'],
            );
            
            // Cancel any pending search
            _debounce?.cancel();

            // Notify parent to keep active (docked at bottom)
            widget.onSearchModeChanged?.call(true); 

            // Force collapse and clear
            setState(() {
              _isSearchMode = false;
              _currentHeight = _minHeight;
              _searchResults = []; // Clear results to prevent rendering
              _isSearching = false;
            });
            _searchFocusNode.unfocus();
          },
        );
      },
    );
  }
}
