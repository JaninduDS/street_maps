import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_notifications.dart';
import '../../../shared/widgets/glass_card.dart';

class ElectricianTasksScreen extends StatefulWidget {
  const ElectricianTasksScreen({super.key});

  @override
  State<ElectricianTasksScreen> createState() => _ElectricianTasksScreenState();
}

class _ElectricianTasksScreenState extends State<ElectricianTasksScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('reports')
          .select()
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingTasks = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveTask(String reportId) async {
    HapticFeedback.mediumImpact();
    
    // Optimistic UI update (remove it from the list immediately for a snappy feel)
    setState(() {
      _pendingTasks.removeWhere((task) => task['id'] == reportId);
    });

    try {
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'Resolved'})
          .eq('id', reportId);

      if (mounted) {
        AppNotifications.show(
          context: context,
          message: 'Task marked as Resolved!',
          icon: CupertinoIcons.check_mark_circled_solid,
          iconColor: AppColors.accentGreen,
        );
      }
    } catch (e) {
      // If it fails, fetch the list again to restore the item
      _fetchTasks();
      if (mounted) {
        AppNotifications.show(
          context: context,
          message: 'Failed to resolve task.',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.myTasks,
          style: const TextStyle(
            fontFamily: 'GoogleSansFlex',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : _pendingTasks.isEmpty
              ? _buildEmptyState(l10n)
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _pendingTasks.length,
                  itemBuilder: (context, index) {
                    final task = _pendingTasks[index];
                    final date = DateTime.parse(task['created_at']).toLocal();
                    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentAmber.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.wrench_fill,
                                    color: AppColors.accentAmber,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['issue_type'] ?? 'Unknown Issue',
                                        style: const TextStyle(
                                          fontFamily: 'GoogleSansFlex',
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Reported by ${task['name'] ?? 'Anonymous'}',
                                        style: TextStyle(
                                          fontFamily: 'GoogleSansFlex',
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontFamily: 'GoogleSansFlex',
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _resolveTask(task['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentGreen.withOpacity(0.15),
                                  foregroundColor: AppColors.accentGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppColors.accentGreen, width: 1),
                                  ),
                                ),
                                icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
                                label: Text(
                                  l10n.markAsResolved,
                                  style: const TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_shield_fill,
              color: AppColors.accentGreen,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.allCaughtUp,
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noPendingTasks,
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}