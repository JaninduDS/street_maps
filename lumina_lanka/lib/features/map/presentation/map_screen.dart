/// Lumina Lanka - Main Map Screen
/// OpenStreetMap integration (flutter_map) with CartoDB Dark Matter
/// Cross-platform support (Linux, Web, Mobile)
library;

import 'dart:async';
import 'dart:io'; // Required for Platform check
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'dart:ui' as ui; // Required for ImageFilter and Path
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:lumina_lanka/features/map/presentation/widgets/pole_info_sidebar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../shared/widgets/unified_glass_sheet.dart';
import '../../report/presentation/report_side_panel.dart';
import '../../report/presentation/report_issue_dialog.dart';
import '../../../shared/widgets/web_sidebar.dart';
import '../../../core/theme/theme_provider.dart'; // Added theme provider import
import 'widgets/street_view_widget.dart';

/// Main map screen with OpenStreetMap and Unified Bottom Sheet
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Map controller
  late final MapController _mapController;
  
  // Location state
  // ignore: unused_field
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  
  // Selected action (role)
  // 0: Report, 1: Mark, 2: Tasks, 3: Admin
  int? _selectedActionIndex;
  
  // Markers
  final List<Marker> _markers = [];
  
  // Mark Pole State
  LatLng? _currentMapCenter;
  bool _isSavingPole = false;
  
  // Selected Pole Info Sidebar State
  Map<String, dynamic>? _selectedPole;
  
  // Track WebSidebar expansion to shift PoleInfoSidebar
  bool _isWebSidebarExpanded = false;
  
  // Initial Center (Colombo/Maharagama area)
  static const LatLng _initialCenter = LatLng(6.9271, 79.8612);

  // Map Mode State
  String _currentTileUrl = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  String _currentMapMode = 'Standard'; // Standard, Hybrid, Satellite
  List<String> _currentSubdomains = [];
  bool _isMapModeOpen = false; // Track if Map Modes popup is open
  double _mapRotation = 0.0; // Track map rotation for compass
  
  // Report Panel State
  bool _isReportPanelOpen = false;
  
  // Search State
  bool _isSearchFocused = false;
  bool _isSearchActive = false; // Tracks if search results are shown (submitted)

  // Report State
  bool _showReportModal = false; // New modal state

  // Street View State (Web Only)
  bool _showStreetView = false;
  bool _isStreetViewExpanded = false;
  // TODO: Securely fetch this in production. Using from google-services for demo.
  final String _googleApiKey = const String.fromEnvironment('MAPS_API_KEY', defaultValue: 'AIzaSyDFImn7B8kTLT944M4Tga6V9m57J6C05x8');

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
    _fetchPolesFromSupabase();
    // Initialize center
    _currentMapCenter = _initialCenter;
  }

  /// Fetch real-time pole data from Supabase
  Future<void> _fetchPolesFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('poles')
          .select();

      final List<dynamic> data = response as List<dynamic>;

      if (mounted) {
        setState(() {
          _markers.clear(); // Clear existing markers
          for (var pole in data) {
            final lat = pole['latitude'] as double;
            final lng = pole['longitude'] as double;
            final status = pole['status'] as String;
            final id = pole['id'].toString().substring(0, 5); // Short ID for display

            // Determine color based on status
            Color markerColor;
            switch (status) {
              case 'Reported':
                markerColor = Colors.red;
                break;
              case 'Maintenance':
                markerColor = Colors.orange;
                break;
              default:
                markerColor = Colors.blue;
            }

            _markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      setState(() {
                         _selectedPole = {
                           'id': id,
                           'status': status,
                           'latitude': lat,
                           'longitude': lng,
                         };
                      });
                      _mapController.move(LatLng(lat, lng), 18.0);
                    }
                  },
                  child: Image.asset(
                    'assets/icons/light_icon.png',
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching poles from Supabase: $e');
    }
  }

  /// Initialize location services
  Future<void> _initLocation() async {
    // 🛑 Prevent crash on platforms without Geolocator implementation (e.g. Linux Desktop)
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      debugPrint('Location services skipped on Desktop (Linux/Windows)');
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        
        // Move map to current location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16.0,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
      debugPrint('Location error: $e');
    }
  }

  /// Add demo pole markers
  void _addDemoPoles() {
    // Demo data
    final poles = [
      (6.8472, 79.9266, 'Working', Colors.blue),
      (6.8485, 79.9280, 'Working', Colors.blue),
      (6.8460, 79.9250, 'Reported', Colors.red),
      (6.8490, 79.9240, 'Working', Colors.blue),
      (6.8455, 79.9275, 'Maintenance', Colors.orange),
    ];

    if (mounted) {
      setState(() {
        for (int i = 0; i < poles.length; i++) {
          _markers.add(
            Marker(
              point: LatLng(poles[i].$1, poles[i].$2),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      setState(() {
                         _selectedPole = {
                           'id': '${i + 100}',
                           'status': poles[i].$3,
                           'latitude': poles[i].$1,
                           'longitude': poles[i].$2,
                         };
                      });
                      _mapController.move(LatLng(poles[i].$1, poles[i].$2), 18.0);
                    }
                },
                child: Image.asset(
                  'assets/icons/light_icon.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          );
        }
      });
    }
  }

  /// Toggle Map Modes Popup
  void _toggleMapModePopup() {
    setState(() => _isMapModeOpen = !_isMapModeOpen);
  }

  Widget _buildModeItem(String title, String imagePath) {
    final isSelected = _currentMapMode == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _currentMapMode = title;
            if (title == 'Standard') {
              _currentTileUrl = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
              _currentSubdomains = [];
            } else if (title == 'Hybrid') {
              // Satellite + Labels/Roads
              _currentTileUrl = 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
              _currentSubdomains = [];
            } else if (title == 'Satellite') {
              // Pure Satellite Image
              _currentTileUrl = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
              _currentSubdomains = [];
            } else if (title == 'Plain') {
              // Positron (light) by default, Dark Matter logic handled in build method dynamically
              _currentTileUrl = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
              _currentSubdomains = ['a', 'b', 'c', 'd'];
            }
          });
        },
        child: Column(
          children: [
            // Image Container
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // Match squircle
                border: isSelected 
                  ? Border.all(color: const Color(0xFF007BFF), width: 2.5) // Blue border
                  : Border.all(color: Colors.transparent, width: 2.5),
                image: DecorationImage(
                   image: AssetImage(imagePath),
                   fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Text Below
            Text(
              title,
              style: TextStyle(fontFamily: 'GoogleSansFlex', 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Save pole location to Firestore
  Future<void> _confirmPoleLocation() async {
    if (_currentMapCenter == null) return;
    
    setState(() => _isSavingPole = true);
    
    try {
      await FirebaseFirestore.instance.collection('poles').add({
        'latitude': _currentMapCenter!.latitude,
        'longitude': _currentMapCenter!.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Working', // Default status
        'addedBy': 'Admin',   // Placeholder
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pole Marked Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset and show sheet again
        setState(() {
          _selectedActionIndex = null;
          _isSavingPole = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pole: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSavingPole = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if in "Mark Pole" mode (Index 1)
    final isMarkingPole = _selectedActionIndex == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Automatically switch CartoDB tile URLs based on theme for Plain mode
    if (_currentMapMode == 'Plain') {
      _currentTileUrl = isDark 
          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15.0,
              minZoom: 7.0, // Prevent zooming out too far
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(5.8, 79.5), // South West
                  const LatLng(9.9, 82.0), // North East
                ),
              ),
              onPositionChanged: (position, hasGesture) {
                _currentMapCenter = position.center;
                if (position.rotation != _mapRotation) {
                  setState(() => _mapRotation = position.rotation);
                }
              },
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Dynamic Tile Layer - Clean OSM Bright style with Dark Reader filter
              TileLayer(
                urlTemplate: _currentTileUrl,
                userAgentPackageName: 'com.maharagama.lumina_lanka',
                subdomains: _currentSubdomains,
                retinaMode: false,
                tileSize: 256,
                tileBuilder: (context, widget, tile) {
                  // Plain mode handles its dark/light theme directly via the cartoDB URL strings.

                  // Only apply the Dark Reader filter if in Dark Mode AND using the Standard map
                  if (isDark && _currentMapMode == 'Standard') {
                    return ColorFiltered(
                      // This specific matrix inverts colors AND rotates hue by 180deg
                      // It turns white roads black, blue water dark blue, and green parks dark green
                      colorFilter: const ColorFilter.matrix([
                         0.333, -0.667, -0.667, 0, 255,
                        -0.667,  0.333, -0.667, 0, 255,
                        -0.667, -0.667,  0.333, 0, 255,
                         0,      0,      0,     1, 0,
                      ]),
                      child: widget,
                    );
                  }
                  return widget;
                },
              ),
              
              // Markers Layer
              MarkerLayer(markers: _markers),
            ],
          ),
          
          // === BLUR OVERLAY (Visible when Report Modal is Open) ===
          if (_showReportModal)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1), // Slight dim
                ),
              ),
            ),
              
          // === MAP MODE POPUP MENU ===
          if (_isMapModeOpen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 80, // Offset to the left of the buttons
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showReportModal ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white, // Dark iOS style surface
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Hug contents
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeItem('Standard', 'assets/icons/explore.png'),
                      const SizedBox(width: 16),
                      _buildModeItem('Hybrid', 'assets/icons/transit.png'),
                      const SizedBox(width: 16),
                      _buildModeItem('Satellite', 'assets/icons/satellite.png'),
                      const SizedBox(width: 16),
                      _buildModeItem('Plain', 'assets/icons/explore.png'), // Using explore.png as fallback

                    ],
                  ),
                ),
              ),
            ),
              
          // === FLOATING ACTION BUTTONS (Right Side) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showReportModal ? 0.0 : 1.0,
              child: Column(
                children: [
                  // === MAP, LOCATION & THEME PILL ===
                  Container(
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 30, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: GlassmorphicContainer(
                      width: 48,
                      height: 144, // Increased to fit 3 buttons
                      borderRadius: 16,
                      blur: 14,
                      alignment: Alignment.center,
                      border: 1.0,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                          ? [
                              const Color(0xFF262626).withValues(alpha: 0.60),
                              const Color(0xFF262626).withValues(alpha: 0.60),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.75),
                            ],
                      ),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.20),
                              Colors.white.withValues(alpha: 0.11),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.05),
                            ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Map Mode Button
                          Tooltip(
                            message: "Change the map type",
                            textStyle: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 13),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            preferBelow: false,
                            verticalOffset: 24,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _toggleMapModePopup();
                                },
                                child: Container(
                                  width: 48,
                                  height: 47,
                                  color: Colors.transparent,
                                  child: Icon(
                                    CupertinoIcons.square_stack_3d_down_right_fill, // Layers icon like iOS
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Divider
                          Container(
                            height: 1,
                            width: 32,
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                          ),
                          // Location Button
                          Tooltip(
                            message: "My Location",
                            textStyle: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 13),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            preferBelow: false,
                            verticalOffset: 24,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _initLocation();
                                  if (_mapRotation != 0.0) {
                                    _mapController.rotate(0.0);
                                  }
                                },
                                child: Container(
                                  width: 48,
                                  height: 47,
                                  color: Colors.transparent,
                                  child: Icon(
                                    CupertinoIcons.location_fill, // More star-like
                                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87.withValues(alpha: 0.7),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Divider 2
                          Container(
                            height: 1,
                            width: 32,
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                          ),
                          // Theme Toggle Button
                          Tooltip(
                            message: "Toggle Theme",
                            textStyle: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 13),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            preferBelow: false,
                            verticalOffset: 24,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(themeModeProvider.notifier).state = 
                                      isDark ? ThemeMode.light : ThemeMode.dark;
                                },
                                child: Container(
                                  width: 48,
                                  height: 47,
                                  color: Colors.transparent,
                                  child: Icon(
                                    isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87.withValues(alpha: 0.9),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Responsive Compass Button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: 1.0, // Always visible
                    child: IgnorePointer(
                      ignoring: false,
                      child: Tooltip(
                        message: "Reset North",
                        textStyle: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 13),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        preferBelow: true,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _mapController.rotate(0.0);
                            },
                            child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF262626).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
                                  ],
                                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1), width: 1.0),
                                ),
                              child: Transform.rotate(
                                angle: -_mapRotation * (pi / 180.0), // Rotate opposite to map to point North
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Static Tick Marks
                                    for (int i = 0; i < 12; i++)
                                      Transform.rotate(
                                        angle: (i * 30.0) * (pi / 180.0),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            width: i % 3 == 0 ? 3 : 2,
                                            height: i % 3 == 0 ? 6 : 4,
                                            decoration: BoxDecoration(
                                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: i == 0 ? 0.0 : 0.4), // Hide top tick for arrow
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Red North Triangle
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: CustomPaint(
                                          size: const Size(8, 6),
                                          painter: TrianglePainter(color: const Color(0xFFE53935)),
                                        ),
                                      ),
                                    ),
                                    // 'N' Text
                                    Text(
                                      'N',
                                      style: TextStyle(
                                        fontFamily: 'GoogleSansFlex',
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  // === ZOOM PILL ===
                  Container(
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 30, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: GlassmorphicContainer(
                      width: 48,
                      height: 96, // 48 * 2
                      borderRadius: 16,
                      blur: 14,
                      alignment: Alignment.center,
                      border: 1.0,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                          ? [
                              const Color(0xFF262626).withValues(alpha: 0.60),
                              const Color(0xFF262626).withValues(alpha: 0.60),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.75),
                            ],
                      ),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.20),
                              Colors.white.withValues(alpha: 0.11),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.05),
                            ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Zoom In
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(_mapController.camera.center, currentZoom + 1);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                color: Colors.transparent,
                                child: Icon(
                                  CupertinoIcons.plus,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Divider
                          Container(
                            height: 1,
                            width: 32,
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                          ),
                          // Zoom Out
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                final currentZoom = _mapController.camera.zoom;
                                _mapController.move(_mapController.camera.center, currentZoom - 1);
                              },
                              child: Container(
                                width: 48,
                                height: 47,
                                color: Colors.transparent,
                                child: Icon(
                                  CupertinoIcons.minus,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                ],
              ),
            ),
          ),
        
          // === STREET VIEW OVERLAY (Web Only) === ...
          if (kIsWeb && _showStreetView)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              bottom: _isStreetViewExpanded ? 0 : MediaQuery.of(context).padding.bottom + 24,
              right: _isStreetViewExpanded ? 0 : 24,
              left: _isStreetViewExpanded ? 0 : null,
              top: _isStreetViewExpanded ? 0 : null,
              child: StreetViewWidget(
                latitude: _currentMapCenter?.latitude ?? _initialCenter.latitude,
                longitude: _currentMapCenter?.longitude ?? _initialCenter.longitude,
                apiKey: _googleApiKey,
                isExpanded: _isStreetViewExpanded,
                onExpand: () {
                  setState(() => _isStreetViewExpanded = !_isStreetViewExpanded);
                },
                onDone: () {
                  setState(() {
                    _showStreetView = false;
                    _isStreetViewExpanded = false;
                  });
                },
              ),
            ),

          // === BOTTOM RIGHT CONTROLS ===
          if (kIsWeb)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showStreetView ? 0.0 : 1.0, 
                child: IgnorePointer(
                  ignoring: _showStreetView,
                  child: Tooltip(
                    message: "Street View",
                    textStyle: const TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontSize: 13),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    preferBelow: true,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _showStreetView = true);
                        },
                        child: GlassmorphicContainer(
                          width: 48,
                          height: 48,
                          borderRadius: 16,
                          blur: 14,
                          alignment: Alignment.center,
                          border: 1.0,
                          linearGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark 
                              ? [
                                  const Color(0xFF262626).withValues(alpha: 0.60),
                                  const Color(0xFF262626).withValues(alpha: 0.60),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.85),
                                  Colors.white.withValues(alpha: 0.75),
                                ],
                          ),
                          borderGradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.20),
                                  Colors.white.withValues(alpha: 0.11),
                                ]
                              : [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.05),
                                ],
                          ),
                          child: Icon(
                            Icons.remove_red_eye_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // === REPORT BUTTON (Bottom Left/Center) - Mobile Only ===
          if (MediaQuery.of(context).size.width < 768)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: MediaQuery.of(context).padding.bottom + 24, // Bottom anchored
              left: 24, // Left aligned, below search panel
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isSearchActive || _showReportModal ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isSearchActive || _showReportModal,
                  child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _showReportModal = true);
                  },
                  child: GlassmorphicContainer(
                    width: 180, // Increased width
                    height: 52,
                    borderRadius: 16, // Apple-like squircle
                    blur: 35,
                    alignment: Alignment.center,
                    border: 1.5,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFA56969).withValues(alpha: 0.8), // Dusty rose/brown
                        const Color(0xFF8D5A5A).withValues(alpha: 0.9),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Report Issue',
                          style: TextStyle(fontFamily: 'GoogleSansFlex', 
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // === LOADING INDICATOR (Initializing) ===
          if (_isLoadingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF008FFF)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Locating...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          // === CONFIRMATION BUTTONS (When Marking) ===
          if (isMarkingPole)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _selectedActionIndex = null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Confirm Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSavingPole ? null : () {
                          HapticFeedback.heavyImpact();
                          _confirmPoleLocation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSavingPole 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text('Confirm Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // === UNIFIED BOTTOM SHEET (Normal Mode) ===
          // Hide if Marking Pole OR Map Mode is Open.
          // If Report Panel is open, we KEEP it but shrink it (handled by width param)
          // === UNIFIED BOTTOM SHEET & ACTION BUTTONS (Moved to Top Left) - Mobile Only ===
          if (!isMarkingPole && !_isMapModeOpen && MediaQuery.of(context).size.width < 768)
            AnimatedAlign(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: Alignment.topLeft, // Anchor to Top Left
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showReportModal ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _showReportModal,
                  child: Padding(
                    // Pad from the top and left to float
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16, 
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start, // Align left
                      children: [
                        // Removed Lumina Title Text

                        // Unified Search Sheet
                        UnifiedGlassSheet(
                          width: MediaQuery.of(context).size.width * 0.35, // Desktop/iPad sidebar width
                          selectedActionIndex: _selectedActionIndex,
                          onActionSelected: (index) {
                            setState(() => _selectedActionIndex = (_selectedActionIndex == index) ? null : index);
                          },
                          onFocusChange: (isFocused) {
                            setState(() => _isSearchFocused = isFocused);
                          },
                          onSearchModeChanged: (isActive) {
                            setState(() => _isSearchActive = isActive);
                          },
                          onLocationSelected: (lat, lng, displayName) {
                            _mapController.move(LatLng(lat, lng), 16.0);
                            FocusManager.instance.primaryFocus?.unfocus();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Moved to: $displayName'),
                                backgroundColor: const Color(0xFF0A84FF),
                              ),
                            );
                          },
                        ),

                        // Separate Action Buttons (Floating UNDER the search bar)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          alignment: Alignment.topCenter,
                          child: Container(
                           height: _isSearchActive ? 0 : null, // Collapse when searching
                           child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _isSearchActive ? 0.0 : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildActionButtons(isDark),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // === POLE INFO SIDEBAR ===
          if (MediaQuery.of(context).size.width >= 768)
            PoleInfoSidebar(
              poleData: _selectedPole,
              isVisible: _selectedPole != null,
              leftPosition: _isWebSidebarExpanded ? 240 : 104, // Shift right if sidebar is expanded
              onClose: () => setState(() => _selectedPole = null),
            ),

          // === REPORT SIDE PANEL ===
          ReportSidePanel(
            isOpen: _isReportPanelOpen,
            onClose: () => setState(() => _isReportPanelOpen = false),
          ),

          // === REPORT MODAL ===
          if (_showReportModal)
            Positioned.fill(
              child: Stack(
                children: [
                   // Scrim to dismiss
                   GestureDetector(
                     onTap: () {
                         // Optional: Allow dismissing by tapping outside?
                         // setState(() => _showReportModal = false);
                     },
                     child: Container(color: Colors.transparent),
                   ),
                   Center(
                     child: ReportIssueDialog(
                       onClose: () => setState(() => _showReportModal = false),
                       onContinue: () {
                         // Handle continue
                         HapticFeedback.lightImpact();
                       },
                     ),
                   ),
                ],
              ),
            ),
          
          // === WEB SIDEBAR (Wide Screens Only) ===
          if (MediaQuery.of(context).size.width >= 768)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: WebSidebar(
                selectedActionIndex: _selectedActionIndex,
                onExpandedChanged: (expanded) {
                  setState(() => _isWebSidebarExpanded = expanded);
                },
                onActionSelected: (index) {
                  setState(() => _selectedActionIndex = (_selectedActionIndex == index) ? null : index);
                },
                onLocationSelected: (lat, lng, displayName) {
                  _mapController.move(LatLng(lat, lng), 16.0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moved to: $displayName'),
                      backgroundColor: const Color(0xFF0A84FF),
                    ),
                  );
                },
                onReportTapped: () {
                  setState(() => _showReportModal = true);
                },
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildActionButtons(bool isDark) {
    final actions = [
      ('Public User', CupertinoIcons.person_2_fill),
      ('Council', CupertinoIcons.building_2_fill),
      ('Electrician', CupertinoIcons.bolt_fill),
      ('Marker', CupertinoIcons.map_pin_ellipse),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Handle action tap
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8), 
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(100), // Pill shape
                ),
                child: Row(
                  children: [
                    Icon(action.$2, color: const Color(0xFF008FFF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      action.$1,
                      style: TextStyle(fontFamily: 'GoogleSansFlex', 
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Custom painter for the red North triangle in the compass
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = ui.Path();
    path.moveTo(size.width / 2, 0); // Top center
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height); // Bottom left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


