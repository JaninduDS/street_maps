/// Lumina Lanka - Unified Map Sheet
/// Cross-platform glass bottom panel (Linux, Web, iOS, Android)
/// Using glassmorphism package for consistent visuals
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';

/// Unified Map Sheet - Dark frosted glass bottom panel
/// Responsive width, wrap-content height
class UnifiedMapSheet extends StatelessWidget {
  /// Currently selected action index
  final int? selectedActionIndex;
  
  /// Callback when action is selected
  final ValueChanged<int>? onActionSelected;
  
  /// Search tap callback
  final VoidCallback? onSearchTap;

  const UnifiedMapSheet({
    super.key,
    this.selectedActionIndex,
    this.onActionSelected,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate height: padding(16+24) + handle(4) + gap(20) + search(~48) + gap(20) + buttons(68+8+14) + buffer
    const contentHeight = 235.0;
    
    return GlassmorphicContainer(
      width: screenWidth * 0.9,
      height: contentHeight,
      borderRadius: 30,
      blur: 30,
      alignment: Alignment.bottomCenter,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF202020).withValues(alpha: 0.75),
          const Color(0xFF101010).withValues(alpha: 0.65),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar (40x4)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Search bar pill
            _SearchPill(onTap: onSearchTap),
            
            const SizedBox(height: 20),
            
            // Action grid (4 big buttons)
            _ActionGrid(
              selectedIndex: selectedActionIndex,
              onSelected: onActionSelected,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark search pill
class _SearchPill extends StatelessWidget {
  final VoidCallback? onTap;

  const _SearchPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF000000).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Search Lumina Lanka',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.mic,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Action grid with 4 big circular buttons
class _ActionGrid extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;

  const _ActionGrid({
    this.selectedIndex,
    this.onSelected,
  });

  static const _actions = [
    (Icons.warning_amber_rounded, 'Report'),
    (Icons.add_location_alt, 'Mark'),
    (Icons.flash_on, 'Tasks'),
    (Icons.shield, 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < _actions.length; i++)
          _ActionButton(
            icon: _actions[i].$1,
            label: _actions[i].$2,
            isSelected: selectedIndex == i,
            onTap: () {
              HapticFeedback.mediumImpact();
              onSelected?.call(i);
            },
          ),
      ],
    );
  }
}

/// Big circular action button (68px)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const circleSize = 68.0;
    const iconColor = Color(0xFF008FFF);
    const circleColor = Color(0xFF283D50);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circle (68px)
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: Border.all(
                color: isSelected
                    ? iconColor
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                if (isSelected)
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          // Label (11px, white, centered)
          Text(
            label,
            style: TextStyle(
              color: isSelected ? iconColor : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
