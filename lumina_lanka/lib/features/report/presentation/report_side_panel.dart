import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_notifications.dart';
import '../../../l10n/app_localizations.dart';

// ============================================================================
// SHARED UI CONSTANTS FROM FIGMA
// ============================================================================
const Color _figmaBg = Color(0xFF1B1B1B);
const Color _figmaCardBg = Color(0xFF252525);
const Color _figmaBlue = Color(0xFF5AC8F5); // Light blue from the design
const Color _figmaDarkBlue = Color(0xFF0A84FF);
const Color _figmaRedBg = Color(0xFF2A1616);
const Color _figmaRedAccent = Color(0xFFFF6B6B);

class ReportSidePanel extends StatefulWidget {
  final bool isOpen;
  final double? leftPosition;
  final String? poleId;
  final VoidCallback onClose;
  final VoidCallback? onSuccess;

  const ReportSidePanel({
    super.key,
    required this.isOpen,
    this.leftPosition,
    this.poleId,
    required this.onClose,
    this.onSuccess,
  });

  @override
  State<ReportSidePanel> createState() => _ReportSidePanelState();
}

class _ReportSidePanelState extends State<ReportSidePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth >= 1024;
    
    final panelWidth = isDesktop ? 440.0 : screenWidth;
    final panelHeight = isDesktop ? double.infinity : (screenHeight * 0.9);
    final targetLeft = isDesktop ? (widget.leftPosition ?? 24.0) : 0.0;
    final bottomPadding = isDesktop ? 24.0 : 0.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      top: isDesktop ? 24.0 : null,
      bottom: bottomPadding,
      left: widget.isOpen ? targetLeft : -panelWidth - 20,
      width: panelWidth,
      height: isDesktop ? null : panelHeight,
      child: Container(
        width: panelWidth,
        decoration: BoxDecoration(
          color: _figmaBg,
          borderRadius: BorderRadius.circular(isDesktop ? 32 : 32),
          border: Border.all(color: const Color(0x1A414755), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 50, offset: const Offset(0, 20)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDesktop ? 32 : 32),
          child: Column(
            children: [
              if (!isDesktop) ...[
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                ),
              ],
              Expanded(
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(4),
                  thickness: 6,
                  thumbColor: Colors.white.withOpacity(0.2),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onClose,
                              child: const Icon(CupertinoIcons.arrow_left, color: _figmaBlue, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Report an Issue',
                              style: TextStyle(fontFamily: 'GoogleSansFlex', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Form Content
                        ReportContent(
                          onClose: widget.onClose,
                          poleId: widget.poleId,
                          onSuccess: widget.onSuccess,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportContent extends StatefulWidget {
  final VoidCallback onClose;
  final String? poleId;
  final VoidCallback? onSuccess;

  const ReportContent({super.key, required this.onClose, this.poleId, this.onSuccess});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  
  String? _selectedIssue;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autofillFromProfile();
  }

  Future<void> _autofillFromProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client.from('profiles').select('name, phone').eq('id', user.id).maybeSingle();
      if (mounted && profile != null) {
        setState(() {
          if (_nameController.text.isEmpty) _nameController.text = profile['name'] ?? '';
          if (_emailController.text.isEmpty) _emailController.text = user.email ?? '';
          if (_phoneController.text.isEmpty) _phoneController.text = profile['phone'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> issues = [
      {'label': l10n.issueSingleOut, 'icon': CupertinoIcons.lightbulb_slash},
      {'label': l10n.issueFlickering, 'icon': CupertinoIcons.bolt},
      {'label': l10n.issueDaytime, 'icon': CupertinoIcons.sun_max},
      {'label': l10n.issueDim, 'icon': CupertinoIcons.cloud_rain},
      {'label': l10n.issueMultipleOut, 'icon': CupertinoIcons.list_bullet},
      {'label': l10n.issueLeaning, 'icon': CupertinoIcons.arrow_down_to_line},
      {'label': l10n.issueDamaged, 'icon': CupertinoIcons.wrench},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency Warning
        IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(color: _figmaRedBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: const BoxDecoration(color: _figmaRedAccent, borderRadius: BorderRadius.horizontal(left: Radius.circular(16))),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: _figmaRedAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.emergencyWarning.toUpperCase(),
                              style: const TextStyle(fontFamily: 'GoogleSansFlex', color: _figmaRedAccent, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.emergencyDesc,
                          style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // What's wrong section
        Text(
          l10n.whatsWrong,
          style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...issues.map((issue) => _buildRadioOption(issue['label'], issue['icon'])),
        const SizedBox(height: 32),

        // Additional Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              l10n.additionalInfo.split(' (')[0],
              style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '(optional)',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(l10n.egLandmarks, _additionalInfoController, maxLines: 4, isTextArea: true),
        const SizedBox(height: 16),

        // Photo Upload
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            try {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1080, maxHeight: 1080);
              if (image != null) {
                final bytes = await image.readAsBytes();
                setState(() { _selectedImage = image; _selectedImageBytes = bytes; });
              }
            } catch (e) {
              if (mounted) AppNotifications.show(context: context, message: 'Error accessing camera', icon: CupertinoIcons.exclamationmark_triangle_fill, iconColor: Colors.redAccent);
            }
          },
          child: CustomPaint(
            painter: _DashedRectPainter(color: Colors.white.withOpacity(0.2), strokeWidth: 1, gap: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: _selectedImage != null ? _figmaBlue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedImage != null ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.camera_viewfinder, 
                    color: _selectedImage != null ? _figmaBlue : Colors.white.withOpacity(0.6), 
                    size: 28
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedImage != null ? _selectedImage!.name : l10n.uploadPhoto,
                    style: TextStyle(fontFamily: 'GoogleSansFlex', color: _selectedImage != null ? _figmaBlue : Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedImage == null) ...[
                    const SizedBox(height: 4),
                    Text('Help us locate the issue faster', style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ]
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Contact Info
        Text(
          l10n.followUpQ,
          style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildTextField(l10n.fullName, _nameController),
        const SizedBox(height: 16),
        _buildTextField(l10n.email, _emailController),
        const SizedBox(height: 16),
        _buildTextField(l10n.phoneOpt, _phoneController),
        const SizedBox(height: 40),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_figmaBlue, _figmaDarkBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(color: _figmaDarkBlue.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting || _isUploadingImage || _selectedIssue == null ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: _isSubmitting || _isUploadingImage
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    l10n.submitReport.toUpperCase(),
                    style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String value, IconData icon) {
    final isSelected = _selectedIssue == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIssue = value);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _figmaCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _figmaBlue : Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _figmaBlue : Colors.transparent,
                border: Border.all(color: isSelected ? _figmaBlue : Colors.white.withOpacity(0.2), width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool isTextArea = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isTextArea) ...[
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: _figmaCardBg,
            borderRadius: BorderRadius.circular(isTextArea ? 20 : 100),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            cursorColor: _figmaBlue,
            style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: isTextArea ? label.toUpperCase() : '',
              hintStyle: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_selectedImageBytes != null && _selectedImage != null) {
        setState(() => _isUploadingImage = true);
        final ext = _selectedImage!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$ext';
        await Supabase.instance.client.storage.from('report_images').uploadBinary(fileName, _selectedImageBytes!, fileOptions: const FileOptions(upsert: true));
        imageUrl = Supabase.instance.client.storage.from('report_images').getPublicUrl(fileName);
      }

      final insertedReport = await Supabase.instance.client.from('reports').insert({
        'issue_type': _selectedIssue,
        'name': _nameController.text.trim().isEmpty ? 'Anonymous' : _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'status': 'Pending',
        'pole_id': widget.poleId,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        if (imageUrl != null) 'image_url': imageUrl,
      }).select('id').single();

      final box = Hive.box<List<dynamic>>('guest_reports');
      final currentList = box.get('report_ids', defaultValue: []) ?? [];
      currentList.add(insertedReport['id']);
      await box.put('report_ids', currentList);

      if (widget.poleId != null) {
        await Supabase.instance.client.from('poles').update({'status': 'Reported'}).eq('id', widget.poleId!);
      }

      if (mounted) {
        AppNotifications.show(context: context, message: 'Report Submitted Successfully!', icon: CupertinoIcons.check_mark_circled_solid, iconColor: Colors.green);
        widget.onSuccess?.call();
        widget.onClose();
      }
    } catch (e) {
      if (mounted) AppNotifications.show(context: context, message: 'Error: ${e.toString()}', icon: CupertinoIcons.exclamationmark_triangle_fill, iconColor: Colors.redAccent);
    } finally {
      if (mounted) setState(() { _isSubmitting = false; _isUploadingImage = false; });
    }
  }
}

// Custom Painter for Dashed Border
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedRectPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16));
    path.addRRect(rrect);

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(pathMetric.extractPath(distance, distance + gap), Offset.zero);
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
