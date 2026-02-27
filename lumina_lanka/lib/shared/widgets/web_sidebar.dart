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
  final VoidCallback? onSearchTapped;
  
  const WebSidebar({
    super.key,
    this.selectedActionIndex,
    this.onActionSelected,
    this.onLocationSelected,
    required this.onReportTapped,
    this.onSearchTapped,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double width = 64.0;
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50), // 000000 50%
              blurRadius: 60, // Shadow - Blur - BG: 60
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: GlassmorphicContainer(
          width: width,
          height: double.infinity,
          borderRadius: 24, // Global Radius: 6 -> 24 for more curved edges
          blur: 14, // Frost - Large: 14
          alignment: Alignment.topCenter,
          border: 1.0,
          linearGradient: LinearGradient(
            begin: const Alignment(-1.0, -1.0), // approximating -45 degrees
            end: const Alignment(1.0, 1.0),
            colors: [
              const Color(0xFF262626).withValues(alpha: 0.60), // Liquid Glass Opacity: 60
              const Color(0xFF262626).withValues(alpha: 0.60), 
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.20), // 000000 20% (inverted for border)
              Colors.white.withValues(alpha: 0.11), // 000000 11% (inverted for border)
            ],
          ),
          child: SafeArea( 
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: width,
                maxWidth: width,
                child: _buildCollapsedContent(),
              ),
            ),
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
        // Sidebar Toggle placeholder (Optional now, maybe disabled)
        _buildSidebarIconButton(
          icon: CupertinoIcons.sidebar_left,
          tooltip: 'Menu',
          onTap: () {},
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
        _buildCollapsedSearchPill(),
        
        const SizedBox(height: 16),
        
        // Report Issue
        _buildSidebarIconButton(
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          tooltip: 'Report Issue',
          onTap: () {
             widget.onReportTapped(); 
          },
          isActive: false,
        ),
        
        const Spacer(),

        // Bottom Staff Login (Collapsed)
        _buildSidebarIconButton(
          icon: CupertinoIcons.person_solid,
          tooltip: 'Ward Login',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ward Login coming soon!')),
            );
          },
          isActive: false,
        ),
        
        const SizedBox(height: 16),

        // Time & Date Display
        const _TimeDateDisplay(isExpanded: false),
        const SizedBox(height: 24),
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
              : Colors.transparent, // cleaner dark mode buttons
            borderRadius: BorderRadius.circular(6), // Global Radius: 6
          ),
          child: Icon(
            icon, 
            color: isActive ? Colors.white : const Color(0xFFF5F5F5).withValues(alpha: 0.67), // F5F5F5 67%
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
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
          ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

            // Bottom Staff Login (Expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildExpandedStaffLogin(),
            ),

            // Time & Date Display
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: const _TimeDateDisplay(isExpanded: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSearchPill() {
    return _TooltipWithPointer(
      message: 'Search',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onSearchTapped?.call();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.search, 
            color: Colors.white, 
            size: 20,
          ),
        ),
      ),
    );
  }

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

/// Time and Date Display Widget (IST/SLST)
class _TimeDateDisplay extends StatefulWidget {
  final bool isExpanded;
  const _TimeDateDisplay({required this.isExpanded});

  @override
  State<_TimeDateDisplay> createState() => _TimeDateDisplayState();
}

class _TimeDateDisplayState extends State<_TimeDateDisplay> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final utcNow = DateTime.now().toUtc();
    // IST / SLST is UTC + 5:30
    final istNow = utcNow.add(const Duration(hours: 5, minutes: 30));
    if (mounted) {
      setState(() {
        _currentTime = istNow;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _currentTime.hour.toString().padLeft(2, '0');
    final minutes = _currentTime.minute.toString().padLeft(2, '0');
    final day = _currentTime.day.toString().padLeft(2, '0');
    final month = _currentTime.month.toString().padLeft(2, '0');

    if (widget.isExpanded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(CupertinoIcons.clock, color: Colors.white.withValues(alpha: 0.5), size: 20),
            const SizedBox(width: 12),
            Text(
              '$hours:$minutes',
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$day/$month',
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hours,
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        Text(
          minutes,
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Text(
          '$day/',
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(
            month,
            style: TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
