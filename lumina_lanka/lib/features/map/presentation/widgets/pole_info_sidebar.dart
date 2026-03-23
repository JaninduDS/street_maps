import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../l10n/app_localizations.dart';

// ============================================================================
// SHARED UI CONSTANTS FROM FIGMA
// ============================================================================
const Color _figmaBg = Color(0xFF1B1B1B);
const Color _figmaCardBg = Color(0xFF252525);
const Color _figmaLightBlue = Color(0xFF5AC8F5); // Added Light Blue
const Color _figmaDarkBlue = Color(0xFF0A84FF);  // Renamed to Dark Blue
const Color _figmaBorder = Color(0x1A414755);

// ============================================================================
// DESKTOP POLE INFO SIDEBAR
// ============================================================================
class PoleInfoSidebar extends ConsumerStatefulWidget {
  final Map<String, dynamic>? poleData;
  final VoidCallback onClose;
  final VoidCallback onReportTapped;
  final bool isVisible;
  final double leftPosition;

  const PoleInfoSidebar({
    super.key,
    required this.poleData,
    required this.onClose,
    required this.onReportTapped,
    required this.isVisible,
    required this.leftPosition,
  });

  @override
  ConsumerState<PoleInfoSidebar> createState() => _PoleInfoSidebarState();
}

class _PoleInfoSidebarState extends ConsumerState<PoleInfoSidebar> {
  double get _currentWidth => (!widget.isVisible || widget.poleData == null) ? 0.0 : 420.0;
  List<dynamic> _reports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    if (widget.poleData != null) _fetchReports();
  }

  @override
  void didUpdateWidget(covariant PoleInfoSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idChanged = widget.poleData?['id'] != oldWidget.poleData?['id'];
    final becameVisible = widget.isVisible && !oldWidget.isVisible;
    if ((idChanged || becameVisible) && widget.poleData != null) _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final data = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('pole_id', widget.poleData!['id'])
          .order('created_at', ascending: false);
      if (mounted) setState(() { _reports = data; _isLoadingReports = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: widget.leftPosition,
      top: 24,
      bottom: 24,
      width: _currentWidth,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: (!widget.isVisible || widget.poleData == null)
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(widget.poleData?['id'] ?? 'none'),
                decoration: BoxDecoration(
                  color: _figmaBg,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _figmaBorder, width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 50, offset: const Offset(0, 20)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildFigmaContent(context, widget.poleData!, authState, l10n, _reports, _isLoadingReports, widget.onClose, widget.onReportTapped, _fetchReports),
                  ),
                ),
              ),
      ),
    );
  }
}

// ============================================================================
// MOBILE POLE INFO BOTTOM SHEET
// ============================================================================
class MobilePoleInfoSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> poleData;
  final VoidCallback onClose;
  final VoidCallback onReportTapped;

  const MobilePoleInfoSheet({
    super.key,
    required this.poleData,
    required this.onClose,
    required this.onReportTapped,
  });

  @override
  ConsumerState<MobilePoleInfoSheet> createState() => _MobilePoleInfoSheetState();
}

class _MobilePoleInfoSheetState extends ConsumerState<MobilePoleInfoSheet> {
  List<dynamic> _reports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final data = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('pole_id', widget.poleData['id'])
          .order('created_at', ascending: false);
      if (mounted) setState(() { _reports = data; _isLoadingReports = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingReports = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: _figmaBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(
          top: BorderSide(color: _figmaBorder, width: 1),
          left: BorderSide(color: _figmaBorder, width: 1),
          right: BorderSide(color: _figmaBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 50, offset: const Offset(0, -20)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _buildFigmaContent(context, widget.poleData, authState, l10n, _reports, _isLoadingReports, widget.onClose, widget.onReportTapped, _fetchReports),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED FIGMA CONTENT BUILDER
// ============================================================================
Widget _buildFigmaContent(
  BuildContext context, 
  Map<String, dynamic> poleData, 
  AuthState authState, 
  AppLocalizations l10n, 
  List<dynamic> reports, 
  bool isLoadingReports, 
  VoidCallback onClose, 
  VoidCallback onReportTapped,
  Future<void> Function() refreshReports,
) {
  final lat = poleData['latitude'] as double;
  final lng = poleData['longitude'] as double;
  final status = poleData['status'] as String;
  final shortId = poleData['id'].toString().substring(0, 5);

  Color statusColor;
  switch (status) {
    case 'Working': statusColor = const Color(0xFF34C759); break;
    case 'Reported': statusColor = const Color(0xFFFF3B30); break;
    case 'Maintenance': statusColor = const Color(0xFFFF9500); break;
    default: statusColor = Colors.white;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Back Button
      GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onClose();
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.chevron_back,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Title
      Text(
        'Street Light $shortId',
        style: const TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
      ),
      const SizedBox(height: 16),

      // Lat/Lng Row
      Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LATITUDE', style: TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('${lat.toStringAsFixed(4)}° N', style: const TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LONGITUDE', style: TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5), letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('${lng.toStringAsFixed(4)}° E', style: const TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Status Indicator
      Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 6)]),
          ),
          const SizedBox(width: 8),
          Text(status, style: TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8))),
        ],
      ),
      const SizedBox(height: 24),

      // Action Buttons Row
      Row(
        children: [
          Expanded(
            child: _FigmaActionButton(
              label: l10n.directions,
              icon: CupertinoIcons.arrow_turn_up_right,
              // Replaced bgColor with the gradient
              gradient: const LinearGradient(
                colors: [_figmaLightBlue, _figmaDarkBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              textColor: Colors.white,
              onTap: () async {
                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (_) {}
              },
            ),
          ),
          const SizedBox(width: 12),
          if (authState.role == AppRole.electrician && status != 'Working')
            Expanded(
              child: _FigmaActionButton(
                label: l10n.markAsResolved,
                icon: CupertinoIcons.checkmark_seal_fill,
                bgColor: const Color(0xFF34C759),
                textColor: Colors.white,
                onTap: () async {
                  try {
                    await Supabase.instance.client.from('poles').update({'status': 'Working'}).eq('id', poleData['id']);
                    await Supabase.instance.client.from('reports').update({'status': 'Resolved'}).eq('pole_id', poleData['id']).inFilter('status', ['Pending', 'Assigned']);
                    poleData['status'] = 'Working'; // Update local state
                    AppNotifications.show(context: context, message: 'Pole marked as Working!', icon: CupertinoIcons.check_mark_circled_solid, iconColor: const Color(0xFF34C759));
                    onClose();
                  } catch (_) {}
                },
              ),
            )
          else
            Expanded(
              child: _FigmaActionButton(
                label: l10n.reportAnIssue,
                icon: CupertinoIcons.exclamationmark_triangle,
                bgColor: _figmaCardBg,
                textColor: Colors.white,
                onTap: onReportTapped,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: _FigmaActionButton(
              label: l10n.copyId,
              icon: CupertinoIcons.doc_on_clipboard,
              bgColor: _figmaCardBg,
              textColor: Colors.white,
              onTap: () {
                Clipboard.setData(ClipboardData(text: poleData['id'].toString()));
                AppNotifications.show(context: context, message: 'ID Copied', icon: CupertinoIcons.doc_on_clipboard_fill);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),

      // Details Cards Row
      Row(
        children: [
          Expanded(
            child: _FigmaDetailCard(
              icon: CupertinoIcons.lightbulb,
              title: 'BULB TYPE',
              value: _formatBulbType(poleData['bulb_type']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FigmaDetailCard(
              icon: Icons.vertical_align_bottom_rounded,
              title: 'POLE TYPE',
              value: _formatPoleType(poleData['pole_type']),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),

      // Recent Reports
      Text(l10n.recentReports, style: const TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 16),
      
      if (isLoadingReports)
        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _figmaDarkBlue)))
      else if (reports.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _figmaCardBg, borderRadius: BorderRadius.circular(16)),
          child: Text(l10n.noReportsFound, style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 15), textAlign: TextAlign.center),
        )
      else
        Container(
          decoration: BoxDecoration(color: _figmaCardBg, borderRadius: BorderRadius.circular(16)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: reports.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
            itemBuilder: (context, index) {
              final report = reports[index];
              final isPending = report['status'] == 'Pending';
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isPending ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.check_mark_circled_solid, color: isPending ? const Color(0xFFFF3B30) : const Color(0xFF34C759), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(report['issue_type'] ?? 'Unknown', style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                        Text(report['status'], style: TextStyle(fontFamily: 'GoogleSansFlex', color: isPending ? const Color(0xFFFF3B30) : const Color(0xFF34C759), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Reported by ${report['name'] ?? 'Anonymous'}', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              );
            },
          ),
        ),
    ],
  );
}

// ============================================================================
// FIGMA CUSTOM WIDGETS
// ============================================================================
class _FigmaActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? bgColor;
  final Gradient? gradient;
  final Color textColor;
  final VoidCallback onTap;

  const _FigmaActionButton({
    required this.label, 
    required this.icon, 
    this.bgColor, 
    this.gradient,
    required this.textColor, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: bgColor, 
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          // Add the glowing shadow if it's a gradient button
          boxShadow: gradient != null ? [
            BoxShadow(color: _figmaDarkBlue.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontFamily: 'GoogleSansFlex', color: textColor, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FigmaDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _FigmaDetailCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _figmaCardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.6), size: 14),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Helpers
String _formatBulbType(String? type) {
  if (type == null || type.isEmpty) return 'N/A';
  if (type == 'led_30w') return 'LED 30W';
  if (type == 'led_50w') return 'LED 50W';
  if (type == 'sodium') return 'Sodium Vapor';
  if (type == 'cfl') return 'CFL';
  return type[0].toUpperCase() + type.substring(1);
}

String _formatPoleType(String? type) {
  if (type == null || type.isEmpty) return 'N/A';
  if (type == 'concrete') return 'Concrete';
  if (type == 'iron') return 'Iron';
  return type[0].toUpperCase() + type.substring(1);
}