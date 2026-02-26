import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
class WebSidebar extends StatefulWidget {
  final int? selectedActionIndex;
  final ValueChanged<int>? onActionSelected;
  final void Function(double lat, double lng, String displayName)? onLocationSelected;
  final VoidCallback onReportTapped;
  
  const WebSidebar({
    super.key,
    this.selectedActionIndex,
    this.onActionSelected,
    this.onLocationSelected,
    required this.onReportTapped,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _isSearchActive = false;
  
  bool _isExpanded = false; // Add collapsed/expanded state

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _searchFocusNode.unfocus();
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    setState(() => _isSearchActive = true);
    _searchFocusNode.unfocus();
    _searchAddress(query);
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
    final width = _isExpanded ? 320.0 : 64.0;
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        child: GlassmorphicContainer(
          width: width,
          height: double.infinity,
          borderRadius: 20, 
          blur: 35,
          alignment: Alignment.topCenter,
          border: 1.5,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Dark theme matching the screenshot
            colors: [
              const Color(0xFF1E2428).withValues(alpha: 0.90), 
              const Color(0xFF1a1c23).withValues(alpha: 0.85), 
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
          child: SafeArea( 
            child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Sidebar Toggle
        _buildSidebarIconButton(
          icon: CupertinoIcons.sidebar_left,
          tooltip: 'Expand',
          onTap: _toggleExpand,
          isActive: false,
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            height: 1,
            width: 32,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        
        // Search
        _buildSidebarIconButton(
          icon: CupertinoIcons.search,
          tooltip: 'Search',
          onTap: () {
            _toggleExpand();
            Future.delayed(const Duration(milliseconds: 300), () {
              _searchFocusNode.requestFocus();
            });
          },
          isActive: false,
        ),
        
        const SizedBox(height: 16),
        
        // Menu / Grid
        _buildSidebarIconButton(
          icon: CupertinoIcons.square_grid_2x2_fill,
          tooltip: 'Menu',
          onTap: () {
             widget.onReportTapped(); // As an example action
          },
          isActive: false,
        ),
        
        const SizedBox(height: 16),
        
        // Action / Share
        _buildSidebarIconButton(
          icon: CupertinoIcons.arrow_turn_up_right,
          tooltip: 'Action',
          onTap: () {},
          isActive: false,
        ),
      ],
    );
  }

  Widget _buildSidebarIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return _TooltipWithPointer(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive 
              ? Colors.white.withValues(alpha: 0.2) 
              : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14), // Squircle
          ),
          child: Icon(
            icon, 
            color: Colors.white, 
            size: 22,
          ),
        ),
      ),
    );
  }


  Widget _buildExpandedContent() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header with Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleExpand,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(CupertinoIcons.sidebar_left, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.map_fill, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Maps",
                    style: TextStyle(fontFamily: 'GoogleSansFlex', 
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(),
            ),

            const SizedBox(height: 16),

            // Content: Search Results OR Navigation Links
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isSearchActive || _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : _buildNavigationLinks(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(
          color: _searchFocusNode.hasFocus 
              ? const Color(0xFF0A84FF).withValues(alpha: 0.8) 
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
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

  Widget _buildNavigationLinks() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildNavTile(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          title: 'Report Issue',
          onTap: widget.onReportTapped,
          color: const Color(0xFFE84A5F), 
        ),
        _buildNavTile(
          icon: CupertinoIcons.building_2_fill,
          title: 'Council',
          isSelected: widget.selectedActionIndex == 1,
          onTap: () => widget.onActionSelected?.call(1),
          color: const Color(0xFF0A84FF), 
        ),
        _buildNavTile(
          icon: CupertinoIcons.bolt_fill,
          title: 'Electrician',
          isSelected: widget.selectedActionIndex == 2,
          onTap: () => widget.onActionSelected?.call(2),
          color: const Color(0xFF34C759), 
        ),
        _buildNavTile(
          icon: CupertinoIcons.map_pin_ellipse,
          title: 'Marker Mode',
          isSelected: widget.selectedActionIndex == 3,
          onTap: () => widget.onActionSelected?.call(3),
          color: const Color(0xFFAF52DE), 
        ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color color = Colors.white54,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(6),
               decoration: BoxDecoration(
                 color: color.withValues(alpha: 0.8),
                 shape: BoxShape.circle,
               ),
               child: Icon(icon, color: Colors.white, size: 20),
             ),
             const SizedBox(width: 14),
             Text(
               title,
               style: TextStyle(fontFamily: 'GoogleSansFlex', 
                 color: isSelected ? const Color(0xFF0A84FF) : Colors.white,
                 fontSize: 15,
                 fontWeight: FontWeight.w500,
               ),
             ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.location_solid, color: Colors.white, size: 16),
          ),
          title: Text(
            result['display_name'],
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onLocationSelected?.call(
              result['lat'],
              result['lon'],
              result['display_name'],
            );
            _clearSearch();
            if (MediaQuery.of(context).size.width < 768) {
               _toggleExpand(); // hide on mobile after search
            }
          },
        );
      },
    );
  }
}

class _TooltipWithPointer extends StatefulWidget {
  final Widget child;
  final String message;
  
  const _TooltipWithPointer({
    required this.child,
    required this.message,
  });

  @override
  State<_TooltipWithPointer> createState() => _TooltipWithPointerState();
}

class _TooltipWithPointerState extends State<_TooltipWithPointer> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;

  void _showTooltip() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 100,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(55, 6), // Offset right the width of the icon + a bit
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(8, 12),
                      painter: _PointerPainter(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF868A91), // Tooltip color mimicking screenshot
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.message,
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _showTooltip();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hideTooltip();
        },
        child: widget.child,
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF868A91)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
