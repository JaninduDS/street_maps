/// Lumina Lanka - Glass Card Widget
/// iOS 26-inspired glassmorphism card with blur effect
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A glassmorphism-styled card with backdrop blur
class GlassCard extends StatelessWidget {
  /// Child widget to display inside the card
  final Widget child;
  
  /// Border radius of the card
  final double borderRadius;
  
  /// Padding inside the card
  final EdgeInsetsGeometry padding;
  
  /// Blur intensity (sigma)
  final double blurIntensity;
  
  /// Background opacity (0.0 - 1.0)
  final double backgroundOpacity;
  
  /// Optional border color
  final Color? borderColor;
  
  /// Whether to show subtle border
  final bool showBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.blurIntensity = 20.0,
    this.backgroundOpacity = 0.7,
    this.borderColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? AppColors.bgSecondary : Colors.white;
    final defaultBorderColor = isDark ? AppColors.borderGlass : Colors.black.withOpacity(0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurIntensity,
          sigmaY: blurIntensity,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: defaultBgColor.withOpacity(backgroundOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: borderColor ?? defaultBorderColor,
                    width: 1,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A glassmorphism bottom sheet container
class GlassBottomSheet extends StatelessWidget {
  /// Child widget to display
  final Widget child;
  
  /// Maximum height as fraction of screen height
  final double maxHeightFraction;
  
  /// Whether to show handle bar
  final bool showHandle;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.5,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? AppColors.bgSecondary : Colors.white;
    final defaultBorderColor = isDark ? AppColors.borderGlass : Colors.black.withOpacity(0.05);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightFraction,
          ),
          decoration: BoxDecoration(
            color: defaultBgColor.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: defaultBorderColor,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A floating action button with glass effect
class GlassButton extends StatelessWidget {
  /// Label text
  final String label;
  
  /// Leading icon
  final IconData? icon;
  
  /// Button tap callback
  final VoidCallback onPressed;
  
  /// Whether button is in loading state
  final bool isLoading;
  
  /// Button color (defaults to accent green)
  final Color? color;
  
  /// Whether to expand to full width
  final bool expanded;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.accentGreen;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
