import 'package:flutter/material.dart';

// Import the stub by default
import 'street_view_stub.dart'
    // Import the web implementation only if we are compiling for the web
    if (dart.library.html) 'street_view_web.dart';

/// A widget that safely displays a Google Maps Street View iframe on the web,
/// and falls back to an empty Container on native platforms like Linux.
class StreetViewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String apiKey;
  final VoidCallback onExpand;
  final VoidCallback onDone;

  const StreetViewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.apiKey,
    required this.onExpand,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // WebStreetView is exported by both the stub AND the web implementation.
    // The conditional import above ensures the correct one is used based on the platform.
    return WebStreetView(
      latitude: latitude,
      longitude: longitude,
      apiKey: apiKey,
      onExpand: onExpand,
      onDone: onDone,
    );
  }
}
