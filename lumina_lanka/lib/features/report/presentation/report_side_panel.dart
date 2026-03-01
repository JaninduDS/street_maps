import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_notifications.dart';

class ReportSidePanel extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double? leftPosition;
  final String? poleId;

  const ReportSidePanel({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.leftPosition,
    this.poleId,
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
    
    final isDesktop = screenWidth >= 768;
    
    final panelWidth = isDesktop ? 440.0 : (screenWidth * 0.35).clamp(400.0, 600.0);
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
        borderRadius: 24,
        blur: 14,
        alignment: Alignment.topCenter,
        border: 1.0,
        linearGradient: LinearGradient(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, 1.0),
          colors: [
            const Color(0xFF1E1E1E).withValues(alpha: 0.75),
            const Color(0xFF1E1E1E).withValues(alpha: 0.85),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: RawScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            radius: const Radius.circular(4),
            thickness: 6,
            thumbColor: Colors.white.withValues(alpha: 0.3),
            padding: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Back Button
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
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
                    // Header Title
                    const Text(
                      'Report an Issue',
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Report Content (inline, not nested widget)
                    ReportContent(onClose: widget.onClose, poleId: widget.poleId),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportContent extends StatefulWidget {
  final VoidCallback onClose;
  final String? poleId;

  const ReportContent({super.key, required this.onClose, this.poleId});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  
  // Image Upload Data
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  
  // Form Data
  String? _selectedIssue;
  String? _selectedDirection;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _poleNumberController = TextEditingController();
  final _additionalInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autofillFromProfile();
  }

  /// Pre-fill contact fields from the logged-in user's profile
  Future<void> _autofillFromProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('name, phone')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && profile != null) {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = profile['name'] ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = user.email ?? '';
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = profile['phone'] ?? '';
          }
        });
      }
    } catch (_) {}
  }

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFlightStyleCard(
          title: "Emergency Warning",
          titleColor: const Color(0xFFEF5350),
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
          title: "Streetlight Details",
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Additional information (optional)",
                style: TextStyle(
                  fontFamily: 'GoogleSansFlex',
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField("e.g. landmarks, side of street", _additionalInfoController, maxLines: 3),
              const SizedBox(height: 16),
              // Upload Photo Button
              if (_selectedImage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.photo_fill, color: Color(0xFF0A84FF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImage!.name,
                          style: const TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            color: Color(0xFF0A84FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        }),
                        child: const Icon(CupertinoIcons.clear_thick_circled, color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    try {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _selectedImage = image;
                          _selectedImageBytes = bytes;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        AppNotifications.show(
                          context: context,
                          message: 'Error accessing camera/gallery',
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          iconColor: Colors.redAccent,
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.camera_fill, color: Colors.white.withValues(alpha: 0.6), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Upload a Photo (optional)',
                          style: TextStyle(
                            fontFamily: 'GoogleSansFlex',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
        const SizedBox(height: 24),
        // Submit Button
        _buildSubmitButton(),
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

  Widget _buildDirectionOption(String label, IconData icon) {
    final isSelected = _selectedDirection == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDirection = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0A84FF) : Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E).withValues(alpha: 0.5),
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
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            cursorColor: Colors.white,
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting || _isUploadingImage || _selectedIssue == null ? null : () async {
          // === SUBMIT TO SUPABASE ===
          setState(() => _isSubmitting = true);
          
          try {
            String? imageUrl;
            if (_selectedImageBytes != null && _selectedImage != null) {
              setState(() => _isUploadingImage = true);
              final ext = _selectedImage!.name.split('.').last;
              final fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$ext';

              await Supabase.instance.client.storage
                  .from('report_images')
                  .uploadBinary(
                    fileName,
                    _selectedImageBytes!,
                    fileOptions: const FileOptions(upsert: true),
                  );
              
              imageUrl = Supabase.instance.client.storage
                  .from('report_images')
                  .getPublicUrl(fileName);
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

            // Save the report ID locally using Hive
            final box = Hive.box<List<dynamic>>('guest_reports');
            final currentList = box.get('report_ids', defaultValue: []) ?? [];
            currentList.add(insertedReport['id']);
            await box.put('report_ids', currentList);

            if (widget.poleId != null) {
              await Supabase.instance.client
                  .from('poles')
                  .update({'status': 'Reported'})
                  .eq('id', widget.poleId!);
            }

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
            debugPrint("Report submit error: $e");
            if (mounted) {
              AppNotifications.show(
                context: context,
                message: 'Error: ${e.toString()}',
                // message: 'Error: Could not submit report.',
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                iconColor: Colors.redAccent,
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
                _isUploadingImage = false;
              });
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9E47FF),
          disabledBackgroundColor: const Color(0xFF9E47FF).withValues(alpha: 0.3),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
          elevation: 0,
        ),
        child: _isSubmitting || _isUploadingImage
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
    );
  }
}
