import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:url_launcher/url_launcher.dart';

class PoleInfoSidebar extends StatefulWidget {
  final Map<String, dynamic>? poleData;
  final VoidCallback onClose;
  final bool isVisible;

  const PoleInfoSidebar({
    super.key,
    required this.poleData,
    required this.onClose,
    required this.isVisible,
  });

  @override
  State<PoleInfoSidebar> createState() => _PoleInfoSidebarState();
}

class _PoleInfoSidebarState extends State<PoleInfoSidebar> {
  // To handle the opening animation
  double get _currentWidth {
    if (!widget.isVisible || widget.poleData == null) {
      return 0.0;
    }
    return 420.0; 
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
      left: 104, // Right outside the WebSidebar
      top: 16,
      bottom: 16,
      width: _currentWidth,
      child: GlassmorphicContainer(
        width: _currentWidth,
        height: double.infinity,
        borderRadius: 24,
        blur: 14,
        alignment: Alignment.topCenter,
        border: 1.0,
        linearGradient: LinearGradient(
          begin: const Alignment(-1.0, -1.0),
          end: const Alignment(1.0, 1.0),
          colors: [
            const Color(0xFF1E1E1E).withValues(alpha: 0.75), // Dark sleek background 
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: (!widget.isVisible || widget.poleData == null)
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    key: ValueKey(widget.poleData?['id'] ?? 'none'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Back Button
                          _buildBackButton(),
                          
                          const SizedBox(height: 16),

                          // Header Title & Subtitle
                          Text(
                            'Street Light #${widget.poleData!['id']}',
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status · ${widget.poleData!['status']}',
                            style: TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons Row (Directions, Call, Website - Apple Maps style)
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Directions',
                                  icon: CupertinoIcons.arrow_turn_up_right,
                                  color: const Color(0xFF0A84FF),
                                  textColor: Colors.white,
                                  onTap: () {
                                     // Placeholder
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Report',
                                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  textColor: Colors.white,
                                  onTap: () {
                                    // Placeholder
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Copy ID',
                                  icon: CupertinoIcons.doc_on_clipboard_fill,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  textColor: Colors.white,
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: widget.poleData!['id'].toString()));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('ID Copied')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // divider
                          _buildDivider(),

                          const SizedBox(height: 16),
                          
                          // Quick Info (Hours / Accepts style from image)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('STATUS', style: _labelStyle()),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.poleData!['status'], 
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: _getStatusColor(widget.poleData!['status']),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1, 
                                height: 30, 
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('LAST UPDATED', style: _labelStyle()),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Recently', 
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildDivider(),
                          const SizedBox(height: 24),

                          // About Section
                          Text(
                            'About',
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'This street light is managed by the local municipal council. Routine maintenance is scheduled every 6 months. For immediate issues such as flickering or complete outage, please use the Report button.',
                              style: TextStyle(
                                fontFamily: 'GoogleSansFlex',
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Details Section
                          Text(
                            'Details',
                            style: const TextStyle(
                              fontFamily: 'GoogleSansFlex',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow('Latitude', widget.poleData!['latitude'].toStringAsFixed(6)),
                                _buildDivider(),
                                _buildDetailRow('Longitude', widget.poleData!['longitude'].toStringAsFixed(6)),
                                _buildDivider(),
                                _buildDetailRow('Power Draw', '150W LED', isLast: true),
                              ],
                            ),
                          ),

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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onClose();
      },
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
    );
  }

  Widget _buildActionButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'GoogleSansFlex',
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontFamily: 'GoogleSansFlex',
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Working': return const Color(0xFF34C759);
      case 'Reported': return const Color(0xFFFF3B30);
      case 'Maintenance': return const Color(0xFFFF9500);
      default: return Colors.white;
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'GoogleSansFlex',
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
