/// Lumina Lanka - Glow Orb Marker
/// Neon glow orb markers for map display with pulse animations
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// A glowing orb marker representing a street light on the map
class GlowOrbMarker extends StatefulWidget {
  /// Status of the street light
  final PoleStatus status;
  
  /// Size of the orb
  final double size;
  
  /// Whether to animate (pulse for faulty lights)
  final bool animate;
  
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Whether marker is selected
  final bool isSelected;

  const GlowOrbMarker({
    super.key,
    required this.status,
    this.size = 16.0,
    this.animate = true,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<GlowOrbMarker> createState() => _GlowOrbMarkerState();
}

class _GlowOrbMarkerState extends State<GlowOrbMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Only animate for faulty lights
    if (widget.animate && _shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowOrbMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && _shouldPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _shouldPulse =>
      widget.status == PoleStatus.reported || 
      widget.status == PoleStatus.assigned;

  Color get _orbColor {
    switch (widget.status) {
      case PoleStatus.working:
      case PoleStatus.resolved:
        return AppColors.accentGreen;
      case PoleStatus.reported:
        return AppColors.accentRed;
      case PoleStatus.assigned:
      case PoleStatus.maintenance:
        return AppColors.accentAmber;
    }
  }

  List<BoxShadow> get _glowShadow {
    switch (widget.status) {
      case PoleStatus.working:
      case PoleStatus.resolved:
        return GlowStyles.greenGlow;
      case PoleStatus.reported:
        return GlowStyles.redGlow;
      case PoleStatus.assigned:
      case PoleStatus.maintenance:
        return GlowStyles.amberGlow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _shouldPulse && widget.animate 
              ? _scaleAnimation.value 
              : 1.0;
          final opacity = _shouldPulse && widget.animate 
              ? _opacityAnimation.value 
              : 1.0;
          
          return Transform.scale(
            scale: widget.isSelected ? 1.3 : scale,
            child: widget.isSelected
                ? Image.asset(
                    'assets/icons/light_icon.png',
                    width: widget.size * 1.5,
                    height: widget.size * 1.5,
                  )
                : Image.asset(
                    'assets/icons/light_icon.png',
                    width: widget.size,
                    height: widget.size,
                  ),
          );
        },
      ),
    );
  }
}

/// A "ghost" pin marker used during pole placement
class GhostPinMarker extends StatefulWidget {
  /// Size of the marker
  final double size;
  
  /// Whether GPS accuracy is sufficient
  final bool isAccurate;

  const GhostPinMarker({
    super.key,
    this.size = 24.0,
    this.isAccurate = false,
  });

  @override
  State<GhostPinMarker> createState() => _GhostPinMarkerState();
}

class _GhostPinMarkerState extends State<GhostPinMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (widget.isAccurate ? AppColors.accentBlue : AppColors.textTertiary)
                .withOpacity(_pulseAnimation.value * 0.8),
            border: Border.all(
              color: widget.isAccurate 
                  ? AppColors.accentBlue 
                  : AppColors.textTertiary,
              width: 2,
            ),
            boxShadow: widget.isAccurate
                ? GlowStyles.blueGlow
                : [
                    BoxShadow(
                      color: AppColors.textTertiary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Icon(
            widget.isAccurate ? Icons.gps_fixed : Icons.gps_not_fixed,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// Status legend widget for map views
class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(
            color: AppColors.accentGreen,
            label: 'Working',
          ),
          SizedBox(height: 8),
          _LegendItem(
            color: AppColors.accentRed,
            label: 'Reported',
            isPulsing: true,
          ),
          SizedBox(height: 8),
          _LegendItem(
            color: AppColors.accentAmber,
            label: 'In Maintenance',
          ),
          SizedBox(height: 8),
          _LegendItem(
            color: AppColors.accentBlue,
            label: 'Draft / New',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isPulsing;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
