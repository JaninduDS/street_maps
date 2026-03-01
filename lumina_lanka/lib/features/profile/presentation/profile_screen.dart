import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/presentation/widgets/login_dialog.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../l10n/app_localizations.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoadingStats = true;
  int _statValue = 0;
  List<dynamic> _pastReports = [];

  @override
  void initState() {
    super.initState();
    // Delay slightly to allow authProvider to initialize if coming from fresh boot
    Future.microtask(() => _fetchUserStats());
  }

  Future<void> _fetchUserStats() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      
      if (authState.role == AppRole.marker) {
        // Count poles marked by this specific user
        final res = await supabase.from('poles').select().eq('created_by', authState.user!.id).count(CountOption.exact);
        _statValue = res.count;
      } else if (authState.role == AppRole.electrician) {
        // Count total resolved issues
        final res = await supabase.from('reports').select().eq('status', 'Resolved').count(CountOption.exact);
        _statValue = res.count;
      } else if (authState.role == AppRole.council) {
        // Count total poles in the system
        final res = await supabase.from('poles').select().count(CountOption.exact);
        _statValue = res.count;
      } else if (authState.role == AppRole.public) {
        // Count reports submitted by this user
        final res = await supabase.from('reports').select().eq('user_id', authState.user!.id);
        _statValue = res.length;
        _pastReports = res;
      }
      
      // Fetch guest reports from local storage if no user is logged in
      if (authState.user == null) {
        final box = Hive.box<List<dynamic>>('guest_reports');
        final localIds = box.get('report_ids', defaultValue: []) ?? [];
        if (localIds.isNotEmpty) {
          final res = await supabase.from('reports').select().inFilter('id', localIds).order('created_at', ascending: false);
          _pastReports = res;
        }
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.user != null;
    final userEmail = authState.user?.email ?? 'guest@luminalanka.lk';
    // Get name from metadata if it exists, otherwise use the first part of the email
    final l10n = AppLocalizations.of(context)!;
    final userName = authState.user?.userMetadata?['name'] ?? 
      (isLoggedIn ? userEmail.split('@')[0].toUpperCase() : l10n.guestUser);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // === ID CARD SECTION ===
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getRoleColor(authState.role).withOpacity(0.2),
                      border: Border.all(color: _getRoleColor(authState.role), width: 2),
                    ),
                    child: Icon(
                      _getRoleIcon(authState.role),
                      size: 48,
                      color: _getRoleColor(authState.role),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name & Email
                  Text(
                    userName,
                    style: const TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getRoleColor(authState.role).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getRoleColor(authState.role).withOpacity(0.5)),
                    ),
                    child: Text(
                      _getRoleName(authState.role, l10n),
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        color: _getRoleColor(authState.role),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // === STATS SECTION ===
            if (isLoggedIn)
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.chart_bar_alt_fill, color: AppColors.accentBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatLabel(authState.role, l10n),
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isLoadingStats
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _statValue.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // === ACTIONS SECTION ===
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildActionTile(
                    icon: CupertinoIcons.settings,
                    title: l10n.appSettings,
                    onTap: () {
                      // Navigate to Settings Screen
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  
                  if (!isLoggedIn) ...[
                    _buildActionTile(
                      icon: CupertinoIcons.person_solid,
                      title: l10n.publicLogin,
                      color: AppColors.accentBlue,
                      onTap: () {
                        showDialog(context: context, builder: (_) => const LoginDialog(isStaffMode: false));
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildActionTile(
                      icon: CupertinoIcons.briefcase_fill,
                      title: l10n.staffLogin,
                      color: Colors.orangeAccent,
                      onTap: () {
                        showDialog(context: context, builder: (_) => const LoginDialog(isStaffMode: true));
                      },
                    ),
                  ] else
                    _buildActionTile(
                      icon: CupertinoIcons.square_arrow_right,
                      title: l10n.logOut,
                      color: AppColors.accentRed,
                      onTap: () {
                        ref.read(authProvider.notifier).signOut();
                        Navigator.pop(context); // Go back to map after logout
                      },
                    ),
                ],
              ),
            ),

            // === MY PAST REPORTS SECTION ===
            if (authState.user == null || authState.role == AppRole.public) ...[
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Past Reports',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingStats)
                const CircularProgressIndicator(color: AppColors.accentBlue)
              else if (_pastReports.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "You haven't submitted any reports yet.",
                    style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._pastReports.map((report) => _buildReportTile(report)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.white}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'GoogleSansFlex', color: color, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(CupertinoIcons.chevron_right, color: Colors.white.withOpacity(0.3), size: 18),
      onTap: onTap,
    );
  }

  Widget _buildReportTile(dynamic report) {
    final status = report['status'] ?? 'Unknown';
    final isPending = status == 'Pending';
    final isWorking = status == 'Working';
    
    Color statusColor;
    if (isPending) statusColor = AppColors.accentRed;
    else if (isWorking) statusColor = AppColors.accentGreen;
    else statusColor = AppColors.accentAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  report['issue_type'] ?? 'Report',
                  style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontFamily: 'GoogleSansFlex', color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pole #${report['pole_id'].toString().substring(0, 5)}',
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Helper methods for dynamic UI
  Color _getRoleColor(AppRole role) {
    switch (role) {
      case AppRole.council: return AppColors.accentGreen;
      case AppRole.electrician: return AppColors.accentAmber;
      case AppRole.marker: return AppColors.accentBlue;
      case AppRole.public: return Colors.white54;
    }
  }

  IconData _getRoleIcon(AppRole role) {
    switch (role) {
      case AppRole.council: return CupertinoIcons.building_2_fill;
      case AppRole.electrician: return CupertinoIcons.bolt_fill;
      case AppRole.marker: return CupertinoIcons.map_pin_ellipse;
      case AppRole.public: return CupertinoIcons.person_fill;
    }
  }

  String _getRoleName(AppRole role, AppLocalizations l10n) {
    switch (role) {
      case AppRole.council: return l10n.councilAdmin;
      case AppRole.electrician: return l10n.electrician;
      case AppRole.marker: return l10n.mapMarker;
      case AppRole.public: return l10n.publicUser;
    }
  }

  String _getStatLabel(AppRole role, AppLocalizations l10n) {
    switch (role) {
      case AppRole.council: return l10n.statTotalPoles;
      case AppRole.electrician: return l10n.statIssuesResolved;
      case AppRole.marker: return l10n.statPolesMarked;
      case AppRole.public: return 'Reports Submitted';
    }
  }
}