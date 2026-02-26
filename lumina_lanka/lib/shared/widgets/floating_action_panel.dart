/// Lumina Lanka - Floating Action Panel
/// Apple Maps-style "Floating Island" panel that hovers above the map
/// Features glassmorphism, action circles, and animated map modes grid
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_pane.dart';
import 'map_modes_modal.dart';

/// Design constants for the floating island UI
class FloatingIslandColors {
  FloatingIslandColors._();
  
  /// Action circle background (Deep Blue-Grey)
  static const Color circleBackground = Color(0xFF283D50);
  
  /// Icon color (Neon Apple Blue)
  static const Color iconBlue = Color(0xFF008FFF);
  
  /// Glass background
  static const Color glassBackground = Color(0xFF1C1C1E);
  
  /// Border color
  static Color borderColor = Colors.white.withValues(alpha: 0.1);
}

/// Floating Action Panel - Apple Maps style floating island
class FloatingActionPanel extends StatefulWidget {
  /// Current map mode
  final MapMode currentMapMode;
  
  /// Callback when map mode is changed
  final ValueChanged<MapMode> onMapModeChanged;
  
  /// List of action circle data
  final List<ActionCircleData> actions;
  
  /// Currently selected action index
  final int? selectedActionIndex;
  
  /// Callback when an action is selected
  final ValueChanged<int>? onActionSelected;
  
  /// Number of nearby poles to display
  final int nearbyPolesCount;

  const FloatingActionPanel({
    super.key,
    required this.currentMapMode,
    required this.onMapModeChanged,
    required this.actions,
    this.selectedActionIndex,
    this.onActionSelected,
    this.nearbyPolesCount = 0,
  });

  @override
  State<FloatingActionPanel> createState() => _FloatingActionPanelState();
}

class _FloatingActionPanelState extends State<FloatingActionPanel>
    with SingleTickerProviderStateMixin {
  /// Whether map modes grid is visible
  bool _showMapModes = false;
  
  /// Animation controller for content transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.1),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Toggle between actions view and map modes view
  void _toggleMapModes() {
    HapticFeedback.lightImpact();
    if (_showMapModes) {
      _animationController.reverse().then((_) {
        setState(() => _showMapModes = false);
      });
    } else {
      setState(() => _showMapModes = true);
      _animationController.forward();
    }
  }

  /// Handle map mode selection
  void _onModeSelected(MapMode mode) {
    HapticFeedback.mediumImpact();
    widget.onMapModeChanged(mode);
    // Animate back to actions view
    _animationController.reverse().then((_) {
      setState(() => _showMapModes = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: FloatingIslandColors.borderColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: FloatingIslandColors.glassBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showMapModes
                  ? _buildMapModesContent()
                  : _buildActionsContent(),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the main actions content
  Widget _buildActionsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppleColors.labelTertiary,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Search pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchPill(
              placeholder: 'Search Lumina Lanka',
              onTap: () {
                // TODO: Open search
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Street Lights',
              style: TextStyle(
                color: AppleColors.labelPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action circles - centered with spaceEvenly
          _FloatingActionRow(
            actions: widget.actions,
            selectedIndex: widget.selectedActionIndex,
            onSelected: widget.onActionSelected,
            onLayersTap: _toggleMapModes,
          ),
          const SizedBox(height: 24),
          
          // Nearby lights section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Lights',
                  style: TextStyle(
                    color: AppleColors.labelPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.nearbyPolesCount} poles',
                  style: TextStyle(
                    color: AppleColors.labelSecondary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Status legend
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _StatusRow(),
          ),
        ],
      ),
    );
  }

  /// Build the map modes grid content
  Widget _buildMapModesContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back button
          Row(
            children: [
              GestureDetector(
                onTap: _toggleMapModes,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppleColors.backgroundTertiary,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppleColors.labelPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Map Modes',
                style: TextStyle(
                  color: AppleColors.labelPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Map modes grid (2x2)
          Row(
            children: [
              Expanded(
                child: _MapModeCard(
                  mode: MapMode.explore,
                  label: 'Explore',
                  isSelected: widget.currentMapMode == MapMode.explore,
                  onTap: () => _onModeSelected(MapMode.explore),
                  gradientColors: const [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MapModeCard(
                  mode: MapMode.satellite,
                  label: 'Satellite',
                  isSelected: widget.currentMapMode == MapMode.satellite,
                  onTap: () => _onModeSelected(MapMode.satellite),
                  gradientColors: const [Color(0xFF2D4A2D), Color(0xFF1A3A1A)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MapModeCard(
                  mode: MapMode.hybrid,
                  label: 'Hybrid',
                  isSelected: widget.currentMapMode == MapMode.hybrid,
                  onTap: () => _onModeSelected(MapMode.hybrid),
                  gradientColors: const [Color(0xFF3A4A3A), Color(0xFF2A3A2A)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MapModeCard(
                  mode: MapMode.explore,
                  label: 'Traffic',
                  isSelected: false, // Traffic mode placeholder
                  onTap: () {
                    // Traffic mode not yet implemented
                    HapticFeedback.lightImpact();
                  },
                  gradientColors: const [Color(0xFF4A3A2A), Color(0xFF3A2A1A)],
                  isDisabled: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Attribution
          Text(
            '© OpenStreetMap contributors',
            style: TextStyle(
              color: AppleColors.labelTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action row with floating island style circles
class _FloatingActionRow extends StatelessWidget {
  final List<ActionCircleData> actions;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onLayersTap;

  const _FloatingActionRow({
    required this.actions,
    this.selectedIndex,
    this.onSelected,
    this.onLayersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < actions.length; i++)
            _FloatingActionCircle(
              icon: actions[i].icon,
              label: actions[i].label,
              color: actions[i].color,
              isSelected: selectedIndex == i,
              onTap: () {
                HapticFeedback.mediumImpact();
                onSelected?.call(i);
              },
            ),
        ],
      ),
    );
  }
}

/// Individual floating action circle with Apple Maps styling
class _FloatingActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FloatingActionCircle({
    required this.icon,
    required this.label,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle - 72px diameter
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : FloatingIslandColors.circleBackground,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : FloatingIslandColors.iconBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          
          // Label - 12px, white, SF Pro style
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppleColors.labelPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Map mode selection card
class _MapModeCard extends StatelessWidget {
  final MapMode mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final bool isDisabled;

  const _MapModeCard({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.gradientColors,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? FloatingIslandColors.iconBlue 
                : AppleColors.labelTertiary,
            width: isSelected ? 3 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Add road pattern for explore/hybrid
            if (mode == MapMode.explore || mode == MapMode.hybrid)
              ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 13 : 15),
                child: CustomPaint(
                  size: const Size(double.infinity, 100),
                  painter: _RoadPatternPainter(),
                ),
              ),
            
            // Label
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                label,
                style: TextStyle(
                  color: isDisabled 
                      ? AppleColors.labelTertiary 
                      : AppleColors.labelPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Disabled overlay
            if (isDisabled)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: AppleColors.labelSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple road pattern painter for map mode previews
class _RoadPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal road
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      paint,
    );

    // Vertical road
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.6, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Status indicators row
class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusIndicator(
          color: const Color(0xFF30D158),
          label: 'Working',
          count: 3,
        ),
        const SizedBox(width: 16),
        _StatusIndicator(
          color: const Color(0xFFFF453A),
          label: 'Faulty',
          count: 1,
        ),
        const SizedBox(width: 16),
        _StatusIndicator(
          color: const Color(0xFFFFD60A),
          label: 'Repair',
          count: 1,
        ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusIndicator({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: AppleColors.labelSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
