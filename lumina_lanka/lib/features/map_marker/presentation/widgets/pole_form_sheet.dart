/// Lumina Lanka - Pole Form Sheet
/// Bottom sheet form for entering pole details during marking
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';

/// Form sheet for entering pole details
class PoleFormSheet extends StatefulWidget {
  /// GPS latitude
  final double latitude;
  
  /// GPS longitude
  final double longitude;
  
  /// Pre-generated pole ID
  final String poleId;

  const PoleFormSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.poleId,
  });

  @override
  State<PoleFormSheet> createState() => _PoleFormSheetState();
}

class _PoleFormSheetState extends State<PoleFormSheet> {
  PoleType _selectedPoleType = PoleType.concrete;
  BulbType _selectedBulbType = BulbType.led30w;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Simulate network delay (will be replaced with Firebase)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.of(context).pop({
        'poleId': widget.poleId,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'poleType': _selectedPoleType.value,
        'bulbType': _selectedBulbType.value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title with glowing orb
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentBlue,
                        boxShadow: GlowStyles.blueGlow,
                      ),
                    ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Pole',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pole ID (read-only)
                _buildInfoRow(
                  icon: Icons.qr_code,
                  label: 'Pole ID',
                  value: widget.poleId,
                ),
                const SizedBox(height: 12),

                // Coordinates (read-only)
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 24),

                // Pole Type selector
                const Text(
                  'Pole Type',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: PoleType.values.map((type) {
                    final isSelected = type == _selectedPoleType;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPoleType = type);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                            right: type == PoleType.values.first ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentBlue.withOpacity(0.2)
                                : AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentBlue
                                  : AppColors.borderPrimary,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                type == PoleType.concrete
                                    ? Icons.foundation
                                    : Icons.hardware,
                                color: isSelected
                                    ? AppColors.accentBlue
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Bulb Type selector
                const Text(
                  'Bulb Type',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BulbType.values.map((type) {
                    final isSelected = type == _selectedBulbType;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedBulbType = type);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentGreen.withOpacity(0.2)
                              : AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentGreen
                                : AppColors.borderPrimary,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accentGreen,
                                  boxShadow: GlowStyles.greenGlow,
                                ),
                              ),
                            Text(
                              type.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Submit button
                GlassButton(
                  label: _isSubmitting ? 'Saving...' : 'Confirm & Mark',
                  icon: Icons.check_circle,
                  onPressed: _submit,
                  isLoading: _isSubmitting,
                  expanded: true,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
