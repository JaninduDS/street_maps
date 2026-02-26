/// Lumina Lanka - Liquid Glass Engine
/// Apple Music-style "Liquid Glass" frosted material with vibrancy
/// Heavy blur, gradient background, and light-catching gradient borders
library;

import 'dart:ui';
import 'package:flutter/material.dart';

/// Design tokens for the Liquid Glass system
class LiquidGlassTokens {
  LiquidGlassTokens._();
  
  // Blur intensity
  static const double blurSigma = 25.0;
  
  // Background gradient opacity
  static const double bgOpacityStart = 0.12;
  static const double bgOpacityEnd = 0.05;
  
  // Border colors
  static Color borderLight = Colors.white.withValues(alpha: 0.2);
  static Color borderMid = Colors.transparent;
  static Color borderDark = Colors.black.withValues(alpha: 0.1);
  
  // Deep glass for icons
  static Color deepGlass = Colors.black.withValues(alpha: 0.3);
  
  // Accent colors
  static const Color neonAzure = Color(0xFF008FFF);
  static const Color activeGlow = Color(0xFF008FFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static Color textSecondary = Colors.white.withValues(alpha: 0.6);
  static Color textTertiary = Colors.white.withValues(alpha: 0.4);
}

/// The core Liquid Glass container with frosted vibrancy effect
/// Use this for all floating UI elements to achieve premium look
class LiquidGlassContainer extends StatelessWidget {
  /// Child widget
  final Widget child;
  
  /// Border radius (default 20 for rounded rect, 40+ for stadium)
  final double borderRadius;
  
  /// Padding inside the container
  final EdgeInsetsGeometry padding;
  
  /// Custom blur sigma (default 25)
  final double blurSigma;
  
  /// Whether to show the gradient border
  final bool showBorder;
  
  /// Custom background tint color
  final Color? backgroundTint;
  
  /// Extra shadow for depth
  final bool enableShadow;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding = EdgeInsets.zero,
    this.blurSigma = LiquidGlassTokens.blurSigma,
    this.showBorder = true,
    this.backgroundTint,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: enableShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                  spreadRadius: -10,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: CustomPaint(
            painter: showBorder 
                ? _GradientBorderPainter(borderRadius: borderRadius)
                : null,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                // The secret sauce: flowing gradient background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (backgroundTint ?? Colors.white)
                        .withValues(alpha: LiquidGlassTokens.bgOpacityStart),
                    (backgroundTint ?? Colors.white)
                        .withValues(alpha: LiquidGlassTokens.bgOpacityEnd),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the gradient border that simulates light catching glass edges
class _GradientBorderPainter extends CustomPainter {
  final double borderRadius;
  
  _GradientBorderPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    // Create gradient that flows around the border
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: 3.14159 * 2,
      colors: [
        LiquidGlassTokens.borderLight,
        LiquidGlassTokens.borderMid,
        LiquidGlassTokens.borderDark,
        LiquidGlassTokens.borderMid,
        LiquidGlassTokens.borderLight,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Deep Glass circle for action icons - darker, more translucent
class DeepGlassCircle extends StatelessWidget {
  /// Icon to display
  final IconData icon;
  
  /// Label below the icon
  final String label;
  
  /// Whether this icon is currently active
  final bool isActive;
  
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Circle diameter
  final double size;
  
  /// Icon size
  final double iconSize;

  const DeepGlassCircle({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.size = 56,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Deep glass circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiquidGlassTokens.deepGlass,
              border: Border.all(
                color: isActive 
                    ? LiquidGlassTokens.neonAzure.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: isActive ? 1.5 : 0.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: LiquidGlassTokens.neonAzure.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: LiquidGlassTokens.neonAzure,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 6),
          
          // Label
          Text(
            label,
            style: TextStyle(
              color: isActive 
                  ? LiquidGlassTokens.textPrimary
                  : LiquidGlassTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          
          // Active indicator dot
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive 
                  ? LiquidGlassTokens.activeGlow
                  : Colors.transparent,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: LiquidGlassTokens.activeGlow.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Liquid Glass search pill - floating search bar with frosted effect
class LiquidGlassSearchPill extends StatelessWidget {
  /// Placeholder text
  final String placeholder;
  
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Show microphone icon
  final bool showMic;

  const LiquidGlassSearchPill({
    super.key,
    this.placeholder = 'Search',
    this.onTap,
    this.showMic = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: LiquidGlassTokens.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                placeholder,
                style: TextStyle(
                  color: LiquidGlassTokens.textTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (showMic) ...[
              Container(
                width: 1,
                height: 20,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.mic,
                color: LiquidGlassTokens.textTertiary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom island controller - the sleek floating action bar
class LiquidGlassIsland extends StatelessWidget {
  /// List of action items
  final List<LiquidGlassAction> actions;
  
  /// Currently active action index
  final int? activeIndex;
  
  /// Selection callback
  final ValueChanged<int>? onActionSelected;
  
  /// Island height
  final double height;

  const LiquidGlassIsland({
    super.key,
    required this.actions,
    this.activeIndex,
    this.onActionSelected,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 40, // Stadium shape
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        height: height - 24, // Account for padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < actions.length; i++)
              DeepGlassCircle(
                icon: actions[i].icon,
                label: actions[i].label,
                isActive: activeIndex == i,
                onTap: () => onActionSelected?.call(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// Data class for liquid glass actions
class LiquidGlassAction {
  final IconData icon;
  final String label;
  
  const LiquidGlassAction({
    required this.icon,
    required this.label,
  });
}
