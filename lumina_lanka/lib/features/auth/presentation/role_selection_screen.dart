/// Lumina Lanka - Role Selection Screen
/// Landing screen for users to select their role
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../map_marker/presentation/map_marker_screen.dart';

/// Role selection screen after splash
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              
              // Logo and branding
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGreen,
                      boxShadow: GlowStyles.greenGlow,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.black,
                      size: 24,
                    ),
                  ).animate().scale(
                    begin: const Offset(0, 0),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LUMINA LANKA',
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Maharagama Pilot',
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
              const SizedBox(height: 48),

              // Welcome text
              Text(
                'Welcome',
                style: TextStyle(fontFamily: 'GoogleSansFlex', 
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                'Select your role to continue',
                style: TextStyle(fontFamily: 'GoogleSansFlex', 
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),

              // Role cards
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      role: UserRole.public_user,
                      title: 'Report an Issue',
                      subtitle: 'Report faulty street lights',
                      icon: Icons.report_problem_outlined,
                      color: AppColors.accentRed,
                      delay: 500.ms,
                      onTap: () {
                        // TODO: Navigate to public map
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      role: UserRole.marker,
                      title: 'Mark Poles',
                      subtitle: 'Register new street light locations',
                      icon: Icons.add_location_alt_outlined,
                      color: AppColors.accentBlue,
                      delay: 600.ms,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MapMarkerScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      role: UserRole.electrician,
                      title: 'Electrician',
                      subtitle: 'View and resolve assigned tasks',
                      icon: Icons.electrical_services_outlined,
                      color: AppColors.accentAmber,
                      delay: 700.ms,
                      onTap: () {
                        // TODO: Navigate to electrician screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login required')),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      role: UserRole.council,
                      title: 'Council Admin',
                      subtitle: 'Manage issues and electricians',
                      icon: Icons.admin_panel_settings_outlined,
                      color: AppColors.accentGreen,
                      delay: 800.ms,
                      onTap: () {
                        // TODO: Navigate to council dashboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login required')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Version info
              Center(
                child: Text(
                  'v1.0.0 • Maharagama Urban Council',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', 
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual role card widget
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Duration delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.1);
  }
}
