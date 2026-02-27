import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// A web-only widget that embeds Google Maps Street View via an iframe
class WebStreetView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String apiKey;
  final VoidCallback onExpand;
  final VoidCallback onDone;
  final bool isExpanded;

  const WebStreetView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.apiKey,
    required this.onExpand,
    required this.onDone,
    this.isExpanded = false,
  });

  @override
  State<WebStreetView> createState() => _WebStreetViewState();
}

class _WebStreetViewState extends State<WebStreetView> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    // Generate a unique ID for the iframe viewer
    _viewId = 'street-view-${Random().nextInt(10000)}';

    // Register the iframe to display the Google Maps embed URL
    final streetViewUrl =
        'https://www.google.com/maps/embed/v1/streetview?key=${widget.apiKey}&location=${widget.latitude},${widget.longitude}&heading=210&pitch=10&fov=35';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => html.IFrameElement()
        ..src = streetViewUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '20px' // Match our rounded popup style
        ..allowFullscreen = false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, // Align top-left to avoid right-side map controls
      children: [
        // Top left controls (OUTSIDE the iframe container)
        PointerInterceptor(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expand Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Listener(
                  onPointerDown: (_) => widget.onExpand(),
                  child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isExpanded ? CupertinoIcons.arrow_down_right_arrow_up_left : CupertinoIcons.arrow_up_left_arrow_down_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Done Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Listener(
                onPointerDown: (_) => widget.onDone(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: 'GoogleSansFlex',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12), // Space between buttons and floating box
        
        // The Map Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: widget.isExpanded ? MediaQuery.of(context).size.width - 48 : 340,
          // Subtract the height of the buttons + spacing when expanded to avoid overflow
          height: widget.isExpanded ? MediaQuery.of(context).size.height - 120 : 220,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 20), // Apple-like squircle
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // The embedded iframe
              ClipRRect(
                borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 20),
                child: HtmlElementView(viewType: _viewId),
              ),
              
              // Bottom Left Binoculars icon overlay (can stay inside since it's non-interactive)
              if (!widget.isExpanded)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.streetview,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
