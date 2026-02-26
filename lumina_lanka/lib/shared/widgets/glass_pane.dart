/// Lumina Lanka - Glass Pane Widget
/// Reusable Apple Maps-style glassmorphism panel with real blur
/// Based on iOS Human Interface Guidelines
library;

import 'dart:ui';
import 'package:flutter/material.dart';

/// Apple-style glassmorphism colors
class AppleColors {
  AppleColors._();
  
  // Primary colors
  static const Color blue = Color(0xFF007AFF);
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color orange = Color(0xFFFF9500);
  static const Color yellow = Color(0xFFFFCC00);
  
  // Background colors (dark mode)
  static const Color backgroundPrimary = Color(0xFF000000);
  static const Color backgroundSecondary = Color(0xFF1C1C1E);
  static const Color backgroundTertiary = Color(0xFF2C2C2E);
  static const Color backgroundElevated = Color(0xFF3A3A3C);
  
  // Glass colors
  static Color glassBackground = const Color(0xFF1C1C1E).withValues(alpha: 0.75);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.05);
  
  // Text colors
  static const Color labelPrimary = Color(0xFFFFFFFF);
  static const Color labelSecondary = Color(0xFF8E8E93);
  static const Color labelTertiary = Color(0xFF636366);
  static const Color labelQuaternary = Color(0xFF48484A);
  
  // Separator
  static Color separator = Colors.white.withValues(alpha: 0.15);
}

/// Apple Maps-style glass pane with real blur effect
/// Use this for all floating UI elements
class GlassPane extends StatelessWidget {
  /// Child widget
  final Widget child;
  
  /// Border radius (default 20 for Apple style)
  final double borderRadius;
  
  /// Padding inside the pane
  final EdgeInsetsGeometry padding;
  
  /// Blur intensity (sigma X and Y)
  final double blurSigma;
  
  /// Background opacity (0.0 - 1.0)
  final double backgroundOpacity;
  
  /// Whether to show the subtle border
  final bool showBorder;
  
  /// Custom background color
  final Color? backgroundColor;

  const GlassPane({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding = EdgeInsets.zero,
    this.blurSigma = 25.0,
    this.backgroundOpacity = 0.75,
    this.showBorder = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (backgroundColor ?? AppleColors.backgroundSecondary)
                .withValues(alpha: backgroundOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: AppleColors.glassBorder,
                    width: 0.5,
                  )
                : null,
            // Subtle gradient highlight at top edge
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppleColors.glassHighlight,
                Colors.transparent,
              ],
              stops: const [0.0, 0.3],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Floating capsule-style search bar (Apple Maps style)
class SearchPill extends StatelessWidget {
  /// Placeholder text
  final String placeholder;
  
  /// Avatar image URL (optional)
  final String? avatarUrl;
  
  /// Tap callback
  final VoidCallback? onTap;

  const SearchPill({
    super.key,
    this.placeholder = 'Search Maps',
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPane(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Search icon
            const Icon(
              Icons.search,
              color: AppleColors.labelSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            
            // Placeholder text
            Expanded(
              child: Text(
                placeholder,
                style: const TextStyle(
                  color: AppleColors.labelSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            
            // Microphone icon
            const Icon(
              Icons.mic,
              color: AppleColors.labelSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            
            // Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppleColors.backgroundTertiary,
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: AppleColors.labelSecondary,
                      size: 18,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple Maps-style circular action button
class ActionCircle extends StatelessWidget {
  /// Icon to display
  final IconData icon;
  
  /// Label text below the circle
  final String label;
  
  /// Circle color (default Apple Blue)
  final Color color;
  
  /// Icon color
  final Color iconColor;
  
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Whether this action is highlighted/selected
  final bool isSelected;

  const ActionCircle({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppleColors.blue,
    this.iconColor = Colors.white,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : AppleColors.backgroundTertiary,
              border: isSelected
                  ? null
                  : Border.all(
                      color: AppleColors.separator,
                      width: 0.5,
                    ),
            ),
            child: Icon(
              icon,
              color: isSelected ? iconColor : AppleColors.labelSecondary,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          
          // Label
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? color : AppleColors.labelSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple Maps-style action row with horizontal scrolling circles
class ActionRow extends StatelessWidget {
  /// List of actions
  final List<ActionCircleData> actions;
  
  /// Currently selected action index
  final int? selectedIndex;
  
  /// Selection callback
  final ValueChanged<int>? onSelected;

  const ActionRow({
    super.key,
    required this.actions,
    this.selectedIndex,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final action = actions[index];
          return ActionCircle(
            icon: action.icon,
            label: action.label,
            color: action.color,
            isSelected: selectedIndex == index,
            onTap: () => onSelected?.call(index),
          );
        },
      ),
    );
  }
}

/// Data class for action circles
class ActionCircleData {
  final IconData icon;
  final String label;
  final Color color;
  
  const ActionCircleData({
    required this.icon,
    required this.label,
    this.color = AppleColors.blue,
  });
}

/// Map layer button (top right floating button)
class MapLayerButton extends StatelessWidget {
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Current layer icon
  final IconData icon;

  const MapLayerButton({
    super.key,
    this.onTap,
    this.icon = Icons.layers,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPane(
        borderRadius: 22,
        padding: const EdgeInsets.all(11),
        child: Icon(
          icon,
          color: AppleColors.labelPrimary,
          size: 22,
        ),
      ),
    );
  }
}

/// Location button (recenter on user)
class LocationButton extends StatelessWidget {
  /// Tap callback
  final VoidCallback? onTap;
  
  /// Whether actively tracking
  final bool isTracking;

  const LocationButton({
    super.key,
    this.onTap,
    this.isTracking = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPane(
        borderRadius: 22,
        padding: const EdgeInsets.all(11),
        child: Icon(
          isTracking ? Icons.near_me : Icons.near_me_outlined,
          color: isTracking ? AppleColors.blue : AppleColors.labelPrimary,
          size: 22,
        ),
      ),
    );
  }
}
