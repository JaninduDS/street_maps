import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:lumina_lanka/shared/widgets/noise_overlay.dart';
import '../../../core/utils/app_notifications.dart';

class ReportSidePanel extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const ReportSidePanel({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  State<ReportSidePanel> createState() => _ReportSidePanelState();
}

class _ReportSidePanelState extends State<ReportSidePanel> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = (screenWidth * 0.35).clamp(400.0, 600.0);
    // Increased panel height to 85% to accommodate wizard content on landscape screens (Web)
    final panelHeight = (screenHeight * 0.85).clamp(400.0, 800.0);
    
    // Bottom padding to avoid home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      top: null, // Don't constrain top
      height: panelHeight, // Fix height
      bottom: bottomPadding,
      left: widget.isOpen ? 16 : -panelWidth - 20, // Slide from Left
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
                      Text(
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
                  child: _ReportWizard(onClose: widget.onClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportWizard extends StatefulWidget {
  final VoidCallback onClose;

  const _ReportWizard({required this.onClose});

  @override
  State<_ReportWizard> createState() => _ReportWizardState();
}

class _ReportWizardState extends State<_ReportWizard> {
  int _currentStep = 0;
  
  // Form Data
  String? _selectedIssue;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _notifyResolved = false;

  final List<String> _issues = [
    'Single light out',
    'Streetlight is flickering',
    'Streetlight on during the day',
    'Light is dim',
    'Two or more lights out in a row',
    'Pole is leaning',
    'Pole is damaged',
  ];

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress Steps
        _buildProgressIndicator(),
        
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(),
          ),
        ),

        // Bottom Actions
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            // Circle
            _buildStepCircle(i),
            
            // Connecting Line (if not last)
            if (i < 3)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < _currentStep ? const Color(0xFF0A84FF) : Colors.white10,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    final isActive = index <= _currentStep;
    final isCompleted = index < _currentStep;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? const Color(0xFF0A84FF) : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '${index + 1}',
                style: TextStyle(fontFamily: 'GoogleSansFlex', 
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildIssueStep();
      case 2:
        return _buildContactStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Before we begin...',
          style: TextStyle(fontFamily: 'GoogleSansFlex', 
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.red, size: 32),
              const SizedBox(height: 12),
              Text(
                'Emergency Warning',
                style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'For downed powerlines, exposed wires, and hanging light fixtures, do NOT report here. Call the Council Emergency Line immediately at 119.',
                style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white70, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIssueStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "What's wrong with the streetlight?",
          style: TextStyle(fontFamily: 'GoogleSansFlex', 
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        ..._issues.map((issue) => _buildRadioOption(issue)),
      ],
    );
  }

  Widget _buildRadioOption(String value) {
    final isSelected = _selectedIssue == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedIssue = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A84FF) : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
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
                style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Can we follow up with questions?",
          style: TextStyle(fontFamily: 'GoogleSansFlex', 
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField("Full name", _nameController),
        const SizedBox(height: 16),
        _buildTextField("Email address", _emailController),
        const SizedBox(height: 16),
        _buildTextField("Phone number (optional)", _phoneController),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Review details",
          style: TextStyle(fontFamily: 'GoogleSansFlex', 
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewItem("Issue", _selectedIssue ?? "Not selected"),
              const Divider(color: Colors.white10, height: 24),
              _buildReviewItem("Name", _nameController.text.isEmpty ? "Anonymous" : _nameController.text),
              const SizedBox(height: 12),
              _buildReviewItem("Contact", _emailController.text.isEmpty ? "None" : _emailController.text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 15)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.transparent, // Make transparent to show glass background
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _prevStep,
              child: Text(
                'Back',
                style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white54),
              ),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 3) {
                _nextStep();
              } else {
                // Submit
                AppNotifications.show(
                  context: context,
                  message: 'Report Submitted Successfully!',
                  icon: CupertinoIcons.check_mark_circled_solid,
                  iconColor: Colors.green,
                );
                widget.onClose();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF), // iOS Blue Button
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // iOS Standard Button Squircle
            ),
            child: Text(
              _currentStep == 3 ? 'Submit Report' : 'Continue',
              style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
