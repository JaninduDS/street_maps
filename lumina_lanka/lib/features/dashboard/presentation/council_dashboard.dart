import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/utils/app_notifications.dart';

class CouncilDashboard extends StatefulWidget {
  const CouncilDashboard({super.key});

  @override
  State<CouncilDashboard> createState() => _CouncilDashboardState();
}

class _CouncilDashboardState extends State<CouncilDashboard> {
  bool _isLoading = true;
  
  // Stats
  int _totalPoles = 0;
  int _pendingIssues = 0;
  int _workingPoles = 0;
  int _brokenPoles = 0;
  int _fixedThisWeek = 0; // NEW STAT
  
  // Chart Data
  List<FlSpot> _weeklyReportSpots = [];
  List<String> _weekDays = [];
  
  // List Data
  List<dynamic> _recentReports = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch Poles for Pie Chart
      final polesData = await supabase.from('poles').select('status');
      int working = 0;
      int broken = 0;
      for (var pole in polesData) {
        if (pole['status'] == 'Working') {
          working++;
        } else {
          broken++;
        }
      }

      // 2. Fetch Reports for Line Chart & List
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
      final reportsData = await supabase
          .from('reports')
          // Fetching all necessary columns for the assignment feature
          .select('id, created_at, status, issue_type, pole_id, name') 
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      // Process Data
      Map<int, int> dailyCounts = {for (var i = 0; i < 7; i++) i: 0};
      final now = DateTime.now();
      
      int pendingCount = 0;
      int fixedCount = 0;

      for (var report in reportsData) {
        if (report['status'] == 'Pending') pendingCount++;
        if (report['status'] == 'Resolved') fixedCount++; // Count resolved
        
        final date = DateTime.parse(report['created_at']).toLocal();
        final difference = DateTime(now.year, now.month, now.day)
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;
            
        if (difference >= 0 && difference < 7) {
          dailyCounts[difference] = (dailyCounts[difference] ?? 0) + 1;
        }
      }

      // Generate FlSpots
      List<FlSpot> spots = [];
      List<String> days = [];
      for (int i = 6; i >= 0; i--) {
        spots.add(FlSpot((6 - i).toDouble(), dailyCounts[i]!.toDouble()));
        final dayDate = now.subtract(Duration(days: i));
        days.add(DateFormat('E').format(dayDate)); 
      }

      if (mounted) {
        setState(() {
          _totalPoles = polesData.length;
          _workingPoles = working;
          _brokenPoles = broken;
          _pendingIssues = pendingCount;
          _fixedThisWeek = fixedCount;
          _weeklyReportSpots = spots;
          _weekDays = days;
          _recentReports = reportsData.take(20).toList(); 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCsv() async {
    HapticFeedback.mediumImpact();
    
    // 1. Define the CSV Headers
    List<List<dynamic>> rows = [
      ['Report ID', 'Date', 'Issue Type', 'Status', 'Reporter Name', 'Pole ID']
    ];

    // 2. Add the data rows
    for (var report in _recentReports) {
      final date = DateTime.parse(report['created_at']).toLocal();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
      
      rows.add([
        report['id'],
        formattedDate,
        report['issue_type'] ?? 'Unknown',
        report['status'],
        report['name'] ?? 'Anonymous',
        report['pole_id'],
      ]);
    }

    // 3. Convert to CSV string
    String csv = const CsvEncoder().convert(rows);

    // 4. Trigger browser download
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Lumina_Reports_${DateTime.now().toIso8601String().split('T')[0]}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    AppNotifications.show(
      context: context,
      message: 'Report downloaded successfully!',
      icon: CupertinoIcons.check_mark_circled_solid,
      iconColor: AppColors.accentGreen,
    );
  }

  void _showAssignSheet(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AssignElectricianSheet(
        reportId: report['id'].toString(),
        poleId: report['pole_id'].toString(),
        issueType: report['issue_type'] ?? 'Unknown Issue',
        onAssigned: () {
          _fetchDashboardData(); // Refresh dashboard after assignment
        },
      ),
    );
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
          l10n.councilDashboard,
          style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === STATS ROW (Now with 3 cards) ===
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: l10n.totalPoles,
                          value: _totalPoles.toString(),
                          icon: CupertinoIcons.lightbulb_fill,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: l10n.pendingRepairs,
                          value: _pendingIssues.toString(),
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppColors.accentRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Fixed (7d)', // Hardcoded to avoid translation errors for now
                          value: _fixedThisWeek.toString(),
                          icon: CupertinoIcons.checkmark_shield_fill,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === CHARTS ROW ===
                  if (MediaQuery.of(context).size.width >= 768)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildLineChartCard(l10n)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildPieChartCard(l10n)),
                      ],
                    )
                  else ...[
                    _buildLineChartCard(l10n),
                    const SizedBox(height: 24),
                    _buildPieChartCard(l10n),
                  ],

                  const SizedBox(height: 32),

                  // === RECENT REPORTS LIST ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentReports,
                        style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton.icon(
                        onPressed: _recentReports.isEmpty ? null : _exportToCsv,
                        icon: const Icon(CupertinoIcons.cloud_download, size: 18, color: Colors.white),
                        label: const Text('Export CSV', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: _recentReports.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(child: Text(l10n.noReportsFound, style: const TextStyle(color: Colors.white54))),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentReports.length,
                            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                            itemBuilder: (context, index) {
                              final report = _recentReports[index];
                              final date = DateTime.parse(report['created_at']).toLocal();
                              final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
                              final isPending = report['status'] == 'Pending';

                              return ListTile(
                                onTap: isPending ? () => _showAssignSheet(report) : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPending ? AppColors.accentRed.withOpacity(0.15) : AppColors.accentGreen.withOpacity(0.15),
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
                                  style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(formattedDate, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      report['status'],
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: isPending ? AppColors.accentRed : AppColors.accentGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isPending) ...[
                                      const SizedBox(width: 8),
                                      const Icon(CupertinoIcons.chevron_right, color: Colors.white38, size: 16),
                                    ]
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            title, 
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.networkHealth, style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: AppColors.accentGreen,
                    value: _workingPoles.toDouble(),
                    title: '$_workingPoles',
                    radius: 20,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppColors.accentRed,
                    value: _brokenPoles.toDouble(),
                    title: '$_brokenPoles',
                    radius: 20,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.accentGreen, l10n.working),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.accentRed, l10n.faulty),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLineChartCard(AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reportsLast7Days, style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _weekDays.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_weekDays[value.toInt()], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == value.toInt()) {
                          return Text(value.toInt().toString(), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyReportSpots,
                    isCurved: true,
                    color: AppColors.accentBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.accentBlue.withOpacity(0.3), AppColors.accentBlue.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.7), fontSize: 13)),
      ],
    );
  }
}

// ============================================================================
// ASSIGN ELECTRICIAN BOTTOM SHEET
// ============================================================================

class AssignElectricianSheet extends StatefulWidget {
  final String reportId;
  final String poleId;
  final String issueType;
  final VoidCallback onAssigned;

  const AssignElectricianSheet({
    super.key,
    required this.reportId,
    required this.poleId,
    required this.issueType,
    required this.onAssigned,
  });

  @override
  State<AssignElectricianSheet> createState() => _AssignElectricianSheetState();
}

class _AssignElectricianSheetState extends State<AssignElectricianSheet> {
  bool _isLoading = true;
  bool _isAssigning = false;
  List<dynamic> _electricians = [];

  @override
  void initState() {
    super.initState();
    _fetchElectricians();
  }

  Future<void> _fetchElectricians() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id, name, phone')
          .eq('role', 'electrician');
      
      if (mounted) {
        setState(() {
          _electricians = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignTask(String electricianId) async {
    HapticFeedback.mediumImpact();
    setState(() => _isAssigning = true);

    try {
      // 1. Update Report Status & Assignment
      await Supabase.instance.client.from('reports').update({
        'status': 'Assigned',
        'assigned_to': electricianId,
      }).eq('id', widget.reportId);

      // 2. Update Pole Status to Maintenance (so it turns orange on map)
      await Supabase.instance.client.from('poles').update({
        'status': 'Maintenance',
      }).eq('id', widget.poleId);

      if (mounted) {
        AppNotifications.show(
          context: context,
          message: 'Task Assigned Successfully!',
          icon: CupertinoIcons.check_mark_circled_solid,
          iconColor: AppColors.accentGreen,
        );
        widget.onAssigned();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.show(
          context: context,
          message: 'Failed to assign task.',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          iconColor: Colors.redAccent,
        );
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: const Color(0xFF1C1C1E).withOpacity(0.9),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Assign Task',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Issue: ${widget.issueType}',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
                )
              else if (_electricians.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No electricians found in the system. Please add an electrician account first.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _electricians.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final elec = _electricians[index];
                    return GestureDetector(
                      onTap: _isAssigning ? null : () => _assignTask(elec['id']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.bolt_fill, color: AppColors.accentAmber, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    elec['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontFamily: 'GoogleSansFlex',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (elec['phone'] != null)
                                    Text(
                                      elec['phone'],
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_right, color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}