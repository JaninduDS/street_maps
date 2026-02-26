/// Lumina Lanka - Map Modes Modal
/// Apple Maps-style layer switcher modal
/// Shows Explore, Satellite, Hybrid options
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'glass_pane.dart';

/// Available map layer modes
enum MapMode {
  explore('Explore', 'Standard dark map'),
  satellite('Satellite', 'Aerial imagery'),
  hybrid('Hybrid', 'Satellite + labels');
  
  const MapMode(this.label, this.description);
  final String label;
  final String description;
}

/// Tile URLs for each map mode
class MapTiles {
  MapTiles._();
  
  // OpenStreetMap Dark (Carto Dark Matter) - slightly saturated
  static const String explore = 
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';
  
  // Esri World Imagery (Free satellite)
  static const String satellite = 
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  
  // Esri World Imagery + Labels overlay
  static const String hybrid = satellite;
  static const String hybridLabels = 
      'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';
  
  // Standard OSM (fallback)
  static const String standard = 
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}

/// Apple Maps-style map modes modal
class MapModesModal extends StatelessWidget {
  /// Currently selected mode
  final MapMode currentMode;
  
  /// Selection callback
  final ValueChanged<MapMode> onModeSelected;

  const MapModesModal({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  /// Show the modal
  static Future<MapMode?> show(
    BuildContext context, {
    required MapMode currentMode,
  }) {
    return showGeneralDialog<MapMode>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Map Modes',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: MapModesModal(
            currentMode: currentMode,
            onModeSelected: (mode) {
              Navigator.of(context).pop(mode);
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppleColors.backgroundSecondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppleColors.glassBorder,
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Balance for close button
                    const Text(
                      'Map Modes',
                      style: TextStyle(
                        color: AppleColors.labelPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppleColors.backgroundTertiary,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppleColors.labelSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Mode options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: MapMode.values.map((mode) {
                    return _MapModeOption(
                      mode: mode,
                      isSelected: currentMode == mode,
                      onTap: () => onModeSelected(mode),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Attribution
                Text(
                  '© OpenStreetMap and other data providers',
                  style: TextStyle(
                    color: AppleColors.labelTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual map mode option
class _MapModeOption extends StatelessWidget {
  final MapMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapModeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Thumbnail
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppleColors.blue : AppleColors.separator,
                width: isSelected ? 3 : 1,
              ),
              color: AppleColors.backgroundTertiary,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isSelected ? 9 : 11),
              child: _ModePreview(mode: mode),
            ),
          ),
          const SizedBox(height: 8),
          
          // Label
          Text(
            mode.label,
            style: TextStyle(
              color: isSelected ? AppleColors.blue : AppleColors.labelPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode preview thumbnails
class _ModePreview extends StatelessWidget {
  final MapMode mode;

  const _ModePreview({required this.mode});

  @override
  Widget build(BuildContext context) {
    // Simple colored preview based on mode
    switch (mode) {
      case MapMode.explore:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C2C2E),
                Color(0xFF1C1C1E),
              ],
            ),
          ),
          child: CustomPaint(
            size: const Size(85, 85),
            painter: _RoadPatternPainter(isDark: true),
          ),
        );
      case MapMode.satellite:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D4A2D),
                Color(0xFF1A3A1A),
              ],
            ),
          ),
        );
      case MapMode.hybrid:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D4A2D),
                Color(0xFF1A3A1A),
              ],
            ),
          ),
          child: CustomPaint(
            size: const Size(85, 85),
            painter: _RoadPatternPainter(isDark: false),
          ),
        );
    }
  }
}

/// Simple road pattern painter for preview
class _RoadPatternPainter extends CustomPainter {
  final bool isDark;
  
  _RoadPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark 
          ? const Color(0xFF3A3A3C) 
          : Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
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

    // Diagonal road
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width * 0.4, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
