import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumina_lanka/shared/widgets/noise_overlay.dart';
import '../../../core/utils/app_notifications.dart';

class ReportSidePanel extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double? leftPosition;

  const ReportSidePanel({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.leftPosition,
  });

  @override
  State<ReportSidePanel> createState() => _ReportSidePanelState();
}

class _ReportSidePanelState extends State<ReportSidePanel> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final isDesktop = screenWidth >= 768;
    
    final panelWidth = isDesktop ? 420.0 : (screenWidth * 0.35).clamp(400.0, 600.0);
    // Increased panel height to 85% to accommodate wizard content on landscape screens (Web)
    final panelHeight = isDesktop ? null : (screenHeight * 0.85).clamp(400.0, 800.0);
    
    // Bottom padding to avoid home indicator
    final bottomPadding = isDesktop ? 16.0 : MediaQuery.of(context).padding.bottom + 16.0;
    
    final targetLeft = isDesktop ? (widget.leftPosition ?? 16.0) : 16.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      top: isDesktop ? 16.0 : null, // Desktop anchors to top
      height: panelHeight, // Fix height on mobile, stretch on desktop
      bottom: bottomPadding,
      left: widget.isOpen ? targetLeft : -panelWidth - 20, // Slide from Left
      width: panelWidth,
      child: GlassmorphicContainer(
        width: panelWidth,
        height: double.infinity,
        borderRadius: 38, // Standard Apple Large Sheet Radius
        blur: 35, // Match UnifiedGlassSheet Apple-style blur
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2C2E).withValues(alpha: 0.65), // Elevated Card
            const Color(0xFF1C1C1E).withValues(alpha: 0.75), // Elevated Base
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
        child: Stack(
          children: [
            // Noise Overlay
            const Positioned.fill(
              child: NoiseOverlay(opacity: 0.08, scale: 0.5),
            ),
            
            // Content
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Row(
                    children: [
                      const Text(
                        'Report an Issue',
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.xmark,
                              color: Colors.white70, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                
                // Content (Wizard)
                Expanded(
                  child: ReportContent(onClose: widget.onClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReportContent extends StatefulWidget {
  final VoidCallback onClose;

  const ReportContent({super.key, required this.onClose});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  bool _isSubmitting = false;
  
  // Form Data
  String? _selectedIssue;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<String> _issues = [
    'Single light out',
    'Streetlight is flickering',
    'Streetlight on during the day',
    'Light is dim',
    'Two or more lights out in row',
    'Pole is leaning',
    'Pole is damaged',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFlightStyleCard(
                title: "Emergency Warning",
                titleColor: const Color(0xFFEF5350), // Red Title
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                iconColor: const Color(0xFFEF5350),
                content: const Text(
                  'For downed powerlines, exposed wires, and hanging light fixtures, do NOT report here. Call the Council Emergency Line immediately at 119.',
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildFlightStyleCard(
                title: "Issue Details",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What's wrong with the streetlight?",
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._issues.map((issue) => _buildRadioOption(issue)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFlightStyleCard(
                title: "Contact Information",
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Can we follow up with questions?",
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField("Full Name", _nameController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField("Email", _emailController)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField("Phone (Opt)", _phoneController)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24), // Extra padding at bottom
            ],
          ),
        ),
        // Bottom Action Bar
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildFlightStyleCard({
    required String title,
    Color titleColor = Colors.white,
    IconData? icon,
    Color? iconColor,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.9), // Dark card surface
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor ?? titleColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'GoogleSansFlex',
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value) {
    final isSelected = _selectedIssue == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedIssue = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0A84FF) : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0A84FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex', 
                  color: isSelected ? Colors.white : Colors.white70, 
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E).withValues(alpha: 0.5), // Inner dark field
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.95), // Solid dock area
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting || _selectedIssue == null ? null : () async {
            // === SUBMIT TO SUPABASE ===
            setState(() => _isSubmitting = true);
            
            try {
              await Supabase.instance.client.from('reports').insert({
                'issue_type': _selectedIssue,
                'name': _nameController.text.trim().isEmpty ? 'Anonymous' : _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
                'status': 'Pending',
              });

              if (mounted) {
                AppNotifications.show(
                  context: context,
                  message: 'Report Submitted Successfully!',
                  icon: CupertinoIcons.check_mark_circled_solid,
                  iconColor: Colors.green,
                );
                widget.onClose();
              }
            } catch (e) {
              if (mounted) {
                AppNotifications.show(
                  context: context,
                  message: 'Error: Could not submit report.',
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                  iconColor: Colors.redAccent,
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isSubmitting = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9E47FF), // Purple accent from flight UI reference
            disabledBackgroundColor: const Color(0xFF9E47FF).withValues(alpha: 0.3),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)), // Pill shape
            elevation: 0,
          ),
          child: _isSubmitting 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              )
            : const Text(
                'Submit Report',
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ),
    );
  }
}
