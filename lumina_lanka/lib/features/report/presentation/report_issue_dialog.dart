import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class ReportIssueDialog extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onContinue;

  const ReportIssueDialog({
    super.key,
    required this.onClose,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3236).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report an Issue',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', 
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white54, size: 18),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Stepper
            Row(
              children: [
                _buildStep(1, isActive: true),
                _buildStepDivider(),
                _buildStep(2),
                _buildStepDivider(),
                _buildStep(3),
                _buildStepDivider(),
                _buildStep(4),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Before we begin...',
              style: TextStyle(fontFamily: 'GoogleSansFlex', 
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Warning Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF251818), // Dark reddish background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Color(0xFFEF5350), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Emergency Warning',
                    style: TextStyle(fontFamily: 'GoogleSansFlex', 
                      color: const Color(0xFFEF5350),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For downed powerlines, exposed wires, and hanging light fixtures, do NOT report here. Call the Council Emergency Line immediately at 119.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'GoogleSansFlex', 
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontFamily: 'GoogleSansFlex', 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, {bool isActive = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF008FFF) : Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(fontFamily: 'GoogleSansFlex', 
          color: isActive ? Colors.white : Colors.white24,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}
