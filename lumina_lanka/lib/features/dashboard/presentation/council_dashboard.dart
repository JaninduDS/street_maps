import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

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

      // 2. Fetch Reports for Line Chart (Last 7 Days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
      final reportsData = await supabase
          .from('reports')
          .select('created_at, status')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      // Process Line Chart Data
      Map<int, int> dailyCounts = {for (var i = 0; i < 7; i++) i: 0};
      final now = DateTime.now();
      
      int pendingCount = 0;

      for (var report in reportsData) {
        if (report['status'] == 'Pending') pendingCount++;
        
        final date = DateTime.parse(report['created_at']).toLocal();
        // Calculate how many days ago this was (0 = today, 1 = yesterday, etc.)
        final difference = DateTime(now.year, now.month, now.day)
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;
            
        if (difference >= 0 && difference < 7) {
          dailyCounts[difference] = (dailyCounts[difference] ?? 0) + 1;
        }
      }

      // Generate FlSpots (X: 0 to 6, Y: count). X=0 is 6 days ago, X=6 is today.
      List<FlSpot> spots = [];
      List<String> days = [];
      for (int i = 6; i >= 0; i--) {
        spots.add(FlSpot((6 - i).toDouble(), dailyCounts[i]!.toDouble()));
        final dayDate = now.subtract(Duration(days: i));
        days.add(DateFormat('E').format(dayDate)); // 'Mon', 'Tue', etc.
      }

      if (mounted) {
        setState(() {
          _totalPoles = polesData.length;
          _workingPoles = working;
          _brokenPoles = broken;
          _pendingIssues = pendingCount;
          _weeklyReportSpots = spots;
          _weekDays = days;
          _recentReports = reportsData.take(20).toList(); // Show top 20 in list
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
          style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
          : SingleChildScrollView(
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // === CHARTS ROW ===
                  if (MediaQuery.of(context).size.width >= 768)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildLineChartCard()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildPieChartCard()),
                      ],
                    )
                  else ...[
                    _buildLineChartCard(),
                    const SizedBox(height: 24),
                    _buildPieChartCard(),
                  ],

                  const SizedBox(height: 32),

                  // === RECENT REPORTS LIST ===
                  const Text(
                    'Recent Reports',
                    style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: _recentReports.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('No recent reports.', style: TextStyle(color: Colors.white54))),
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
                                trailing: Text(
                                  report['status'],
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    color: isPending ? AppColors.accentRed : AppColors.accentGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Network Health', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
              _buildLegendItem(AppColors.accentGreen, 'Working'),
              const SizedBox(width: 16),
              _buildLegendItem(AppColors.accentRed, 'Faulty'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLineChartCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports (Last 7 Days)', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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