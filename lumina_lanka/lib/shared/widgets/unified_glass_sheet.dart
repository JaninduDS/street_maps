/// Lumina Lanka - Unified Glass Sheet
/// iOS 26 "Liquid Glass" aesthetic using glassmorphism package
/// Cross-platform: Linux, Web, iOS, Android
library;

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:glassmorphism/glassmorphism.dart';

import '../../core/services/google_places_service.dart';

/// Unified Glass Sheet - Frosted "Floating Island" bottom panel
/// Now with integrated search functionality and Light/Dark mode support
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
  static const double _minHeight = 78.0;

  // Search state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlacePrediction> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _sessionToken = GooglePlacesService.generateSessionToken();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    widget.onFocusChange?.call(_searchFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        if (_isSearchMode) {
          _isSearchMode = false;
          widget.onSearchModeChanged?.call(false);
        }
      });
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

        // Auto-expand if we have results
        if (_searchResults.isNotEmpty) {
          final screenHeight = MediaQuery.of(context).size.height;
          
          _isSearchMode = true;
          widget.onSearchModeChanged?.call(true);
        }
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    
    // Notify parent
    widget.onSearchModeChanged?.call(true);

    // Expand to show results
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      
      _isSearchMode = true;
    });

    _searchFocusNode.unfocus();
    _fetchSuggestions(query);
  }

  void _exitSearchMode() {
    _debounce?.cancel();
    
    // Notify parent
    widget.onSearchModeChanged?.call(false);

    setState(() {
      _isSearchMode = false;
      
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
    // Reset session token for next search session
    _sessionToken = GooglePlacesService.generateSessionToken();
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

    // Cancel any pending search
    _debounce?.cancel();

    // Notify parent to keep active (docked at bottom)
    widget.onSearchModeChanged?.call(true);

    // Force collapse and clear
    if (mounted) {
      setState(() {
        _isSearchMode = false;
        _searchResults = [];
        _isSearching = false;
      });
      _searchFocusNode.unfocus();
      _sessionToken = GooglePlacesService.generateSessionToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // 1. Calculate safe height so it never goes off-screen
    final safeMaxHeight = screenHeight - keyboardHeight - 120; // 120px clearance for top buttons
    final expandedHeight = (screenHeight * 0.65).clamp(200.0, safeMaxHeight);
    
    // 2. Determine actual height
    final displayHeight = _isSearchMode ? expandedHeight : _minHeight;
    
    final targetWidth = widget.width ?? (screenWidth * 0.75);

    // Dynamic border radius
    final dynamicRadius = 50.0 - ((displayHeight - _minHeight) / (expandedHeight - _minHeight).clamp(1.0, double.infinity)) * 30;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: targetWidth,
      height: displayHeight,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(displayHeight == _minHeight ? 40 : dynamicRadius.clamp(20.0, 40.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: -5,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: GlassmorphicContainer(
          width: targetWidth,
          height: displayHeight,
          borderRadius: displayHeight == _minHeight ? 40 : dynamicRadius.clamp(20.0, 40.0),
          blur: 45, 
          alignment: Alignment.topCenter, 
          border: 1.0,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1C1C1E).withOpacity(0.75), const Color(0xFF121212).withOpacity(0.65)]
              : [Colors.white.withOpacity(0.90), Colors.white.withOpacity(0.80)],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
              ? [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)]
              : [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.02)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEditableSearchBar(),
              ),

              if (displayHeight > _minHeight + 20)
                Expanded(
                  child: _buildSearchResults(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9.0, sigmaY: 9.0),
        child: Container(
          height: 44, // Reduced height (was 52)
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF3A3A3C).withValues(alpha: 0.4) // Elevate 3 Search Bar
                : Colors.white.withValues(alpha: 0.8), // Light mode search bg
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: _searchFocusNode.hasFocus 
                  ? const Color(0xFF0A84FF).withValues(alpha: 0.8) // iOS Blue
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
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
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex', 
                      color: isDark ? Colors.white : Colors.black87, 
                      fontSize: 15
                    ), // Slightly smaller text
                    textInputAction: TextInputAction.search, // Show 'Search' button on keyboard
                    decoration: InputDecoration(
                      hintText: 'Search Maps',
                      hintStyle: TextStyle(
                        fontFamily: 'GoogleSansFlex', 
                        color: isDark ? Colors.white38 : Colors.black38
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    onChanged: _onSearchChanged,
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
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.xmark, 
                        color: isDark ? Colors.white54 : Colors.black54, 
                        size: 14
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildSearchResults(bool isDark) {
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
            style: TextStyle(
              fontFamily: 'GoogleSansFlex', 
              color: isDark ? Colors.white38 : Colors.black38, 
              fontSize: 14
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final prediction = _searchResults[index];
        return ListTile(
          leading: const Icon(CupertinoIcons.location_solid, color: Color(0xFF0A84FF), size: 22),
          title: Text(
            prediction.mainText,
            style: TextStyle(
              fontFamily: 'GoogleSansFlex', 
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: prediction.secondaryText.isNotEmpty
              ? Text(
                  prediction.secondaryText,
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: () => _selectResult(prediction),
        );
      },
    );
  }
}
