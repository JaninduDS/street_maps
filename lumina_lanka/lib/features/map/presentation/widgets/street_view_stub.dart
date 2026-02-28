import 'package:flutter/material.dart';

/// Stub widget for non-web platforms.
/// Returns an empty container since Street View isn't supported on Linux natively.
class WebStreetView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String apiKey;
  final VoidCallback onExpand;
  final VoidCallback onDone;
  final bool isExpanded;
  final bool isSidebarExpanded;

  const WebStreetView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.apiKey,
    required this.onExpand,
    required this.onDone,
    this.isExpanded = false,
    this.isSidebarExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
