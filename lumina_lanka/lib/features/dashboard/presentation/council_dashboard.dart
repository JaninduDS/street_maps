import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class CouncilDashboard extends StatefulWidget {
  const CouncilDashboard({super.key});

  @override
  State<CouncilDashboard> createState() => _CouncilDashboardState();
}

class _CouncilDashboardState extends State<CouncilDashboard> {
  bool _isLoading = true;
  int _totalPoles = 0;
  int _pendingIssues = 0;
  List<dynamic> _recentReports = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Get total poles count
      final polesResponse = await supabase.from('poles').select().count(CountOption.exact);

      // 2. Get pending reports count
      final pendingResponse = await supabase.from('reports').select().eq('status', 'Pending').count(CountOption.exact);

      // 3. Get recent reports
      final reports = await supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _totalPoles = polesResponse.count;
          _pendingIssues = pendingResponse.count;
          _recentReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Council Dashboard',
          style: TextStyle(
            fontFamily: 'GoogleSansFlex',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === STATS ROW ===
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Poles',
                          value: _totalPoles.toString(),
                          icon: CupertinoIcons.lightbulb_fill,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pending Repairs',
                          value: _pendingIssues.toString(),
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppColors.accentRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Resolved',
                          value: (_recentReports.where((r) => r['status'] == 'Resolved').length).toString(),
                          icon: CupertinoIcons.checkmark_seal_fill,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // === RECENT REPORTS LIST ===
                  const Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: _recentReports.isEmpty
                          ? const Center(
                              child: Text(
                                'No reports found.',
                                style: TextStyle(color: Colors.white54, fontFamily: 'GoogleSansFlex'),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _recentReports.length,
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final report = _recentReports[index];
                                final date = DateTime.parse(report['created_at']).toLocal();
                                final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
                                final isPending = report['status'] == 'Pending';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isPending 
                                          ? AppColors.accentRed.withOpacity(0.15)
                                          : AppColors.accentGreen.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPending ? CupertinoIcons.wrench_fill : CupertinoIcons.check_mark,
                                      color: isPending ? AppColors.accentRed : AppColors.accentGreen,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    report['issue_type'] ?? 'Unknown Issue',
                                    style: const TextStyle(
                                      fontFamily: 'GoogleSansFlex',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Reported by ${report['name'] ?? 'Anonymous'} • $formattedDate',
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPending 
                                          ? AppColors.accentRed.withOpacity(0.2)
                                          : AppColors.accentGreen.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPending ? AppColors.accentRed : AppColors.accentGreen,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      report['status'],
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: isPending ? AppColors.accentRed : AppColors.accentGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}