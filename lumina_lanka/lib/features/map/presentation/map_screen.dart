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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Local Imports
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/unified_glass_sheet.dart';
import '../../../shared/widgets/web_sidebar.dart';
import '../../map_marker/presentation/map_marker_screen.dart';
import '../../report/presentation/report_side_panel.dart';
import 'widgets/pole_info_sidebar.dart';
import 'widgets/search_wards_sidebar.dart';
import 'widgets/street_view_widget.dart';
import '../../../core/utils/app_notifications.dart';
import '../../profile/presentation/profile_screen.dart';

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
  final List<Map<String, dynamic>> _poleDataList = []; // Raw pole data for distance calc
  
  // Nearest Pole Button State
  bool _showNearestPoleButton = false;
  Map<String, dynamic>? _nearestPoleCache; // Cached nearest pole data
  String _nearestPoleLocation = ''; // Reverse-geocoded location of nearest pole
  String? _expandedPoleId; // Track which marker is expanded to show status
  
  // Mark Pole State
  LatLng? _currentMapCenter;
  bool _isSavingPole = false;
  
  // Filter State
  bool _showOnlyBroken = false;
  
  // Selected Pole Info Sidebar State
  Map<String, dynamic>? _selectedPole;
  
  // Track WebSidebar expansion to shift PoleInfoSidebar
  bool _isWebSidebarExpanded = false;
  
  // Search Wards Sidebar State
  bool _isSearchWardsOpen = false;
  
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
  // Removed _showReportModal

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
          _poleDataList.clear(); // Clear raw data
          for (var pole in data) {
            _poleDataList.add({
              'id': pole['id'].toString(),
              'status': pole['status'] as String,
              'latitude': pole['latitude'] as double,
              'longitude': pole['longitude'] as double,
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching poles from Supabase: $e');
    }
  }




  /// Calculate Haversine distance between two points in meters
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth's radius in meters
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Find the nearest pole to a given reference point
  Map<String, dynamic>? _findNearestPole(double refLat, double refLon) {
    if (_poleDataList.isEmpty) return null;

    Map<String, dynamic>? nearest;
    double minDist = double.infinity;

    for (final pole in _poleDataList) {
      final d = _haversineDistance(
        refLat,
        refLon,
        pole['latitude'] as double,
        pole['longitude'] as double,
      );
      if (d < minDist) {
        minDist = d;
        nearest = pole;
      }
    }
    return nearest;
  }

  /// Navigate to the nearest streetlight from the user's live GPS position
  Future<void> _navigateToNearestPole() async {
    HapticFeedback.mediumImpact();

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // 2. Request / Check permissions specifically for Web
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are denied.');
      }

      // 3. Fetch fresh position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update stored position
      _currentPosition = position;

      final nearest = _findNearestPole(position.latitude, position.longitude);
      if (nearest == null) return;

      final lat = nearest['latitude'] as double;
      final lng = nearest['longitude'] as double;

      if (mounted) {
        setState(() {
          _selectedPole = nearest;
          _isSearchWardsOpen = false;
          _showNearestPoleButton = false;
        });
        _mapController.move(LatLng(lat, lng), 18.0);

        // Reverse geocode to get city name from user's position
        _reverseGeocode(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.show(
          context: context,
          message: 'Unable to get your location. Please allow location access.',
          icon: CupertinoIcons.location_slash_fill,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  /// Reverse geocode coordinates to get a human-readable location name
  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://photon.komoot.io/reverse?lat=$lat&lon=$lon',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];

        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>;
          final city = props['city'] ?? props['town'] ?? props['village'] ?? props['county'] ?? '';
          final country = props['country'] ?? '';
          final locationName = [city, country].where((s) => s.toString().isNotEmpty).join(', ');

          if (mounted && locationName.isNotEmpty) {
            AppNotifications.show(
              context: context,
              message: 'Your location: $locationName',
              icon: CupertinoIcons.location_fill,
              iconColor: const Color(0xFF0A84FF),
            );
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback to coordinates if reverse geocoding fails
    if (mounted) {
      AppNotifications.show(
        context: context,
        message: 'Your location: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
        icon: CupertinoIcons.location_fill,
        iconColor: const Color(0xFF0A84FF),
      );
    }
  }

  /// Check if the nearest pole button should be visible
  void _checkNearestPoleVisibility() {
    if (_poleDataList.isEmpty || _currentMapCenter == null) return;

    // Find the nearest pole to the camera center
    double minDist = double.infinity;
    Map<String, dynamic>? closestPole;
    for (final pole in _poleDataList) {
      final d = _haversineDistance(
        _currentMapCenter!.latitude,
        _currentMapCenter!.longitude,
        pole['latitude'] as double,
        pole['longitude'] as double,
      );
      if (d < minDist) {
        minDist = d;
        closestPole = pole;
      }
    }

    // Show button when camera is more than 200m from nearest pole
    final shouldShow = minDist > 200;
    if (shouldShow != _showNearestPoleButton) {
      setState(() {
        _showNearestPoleButton = shouldShow;
        if (shouldShow && closestPole != null) {
          // Cache the nearest pole and reverse geocode its location
          if (_nearestPoleCache?['id'] != closestPole!['id']) {
            _nearestPoleCache = closestPole;
            _nearestPoleLocation = '';
            _reverseGeocodePole(
              closestPole['latitude'] as double,
              closestPole['longitude'] as double,
            );
          }
        }
      });
    }
  }

  /// Reverse geocode the nearest pole's location for display
  Future<void> _reverseGeocodePole(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lon');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>;
          final street = props['street'] ?? '';
          final city = props['city'] ?? props['town'] ?? props['village'] ?? '';
          final loc = [street, city].where((s) => s.toString().isNotEmpty).join(', ');
          if (mounted && loc.isNotEmpty) {
            setState(() => _nearestPoleLocation = loc);
          }
        }
      }
    } catch (_) {}
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
        
        // Only move map if user is within Sri Lanka bounds
        final inSriLanka = position.latitude >= 5.8 && position.latitude <= 9.9 &&
                            position.longitude >= 79.5 && position.longitude <= 82.0;
        if (inSriLanka) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            16.0,
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
      debugPrint('Location error: $e');
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

  @override
  Widget build(BuildContext context) {
    // Watch the current user's role
    final authState = ref.watch(authProvider);
    
    // Check if in "Mark Pole" mode (Index 1)
    final isMarkingPole = _selectedActionIndex == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const wDark = true; // Floating widgets always use dark styling

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
              backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF9F9F9),
              initialCenter: _initialCenter,
              initialZoom: 13.0, // Show Colombo area clearly on startup
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
                // Check if nearest pole button should appear
                _checkNearestPoleVisibility();
              },
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Dynamic Tile Layer - Clean OSM Bright style with Dark Reader filter
              if (isDark && _currentMapMode == 'Standard')
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                     0.333, -0.667, -0.667, 0, 255,
                    -0.667,  0.333, -0.667, 0, 255,
                    -0.667, -0.667,  0.333, 0, 255,
                     0,      0,      0,     1, 0,
                  ]),
                  child: TileLayer(
                    urlTemplate: _currentTileUrl,
                    userAgentPackageName: 'com.maharagama.lumina_lanka',
                    subdomains: _currentSubdomains,
                    retinaMode: false,
                    tileSize: 256,
                    keepBuffer: 2,
                    panBuffer: 1,
                  ),
                )
              else
                TileLayer(
                  urlTemplate: _currentTileUrl,
                  userAgentPackageName: 'com.maharagama.lumina_lanka',
                  subdomains: _currentSubdomains,
                  retinaMode: false,
                  tileSize: 256,
                  keepBuffer: 2,
                  panBuffer: 1,
                ),
              
              // Markers Layer
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          
          // === BLUR OVERLAY (Visible when Report Modal is Open) ===
          if (_isReportPanelOpen)
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
                opacity: _isReportPanelOpen ? 0.0 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: wDark ? const Color(0xFF1C1C1E) : Colors.white, // Dark iOS style surface
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: wDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
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
          
          // === PROFILE BUTTON (Top Right) ===
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isReportPanelOpen ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _isReportPanelOpen,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: wDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: wDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          color: authState.user != null ? const Color(0xFF0A84FF) : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // === FLOATING ACTION BUTTONS (Right Side) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isReportPanelOpen ? 0.0 : 1.0,
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
                      height: 192, // Fits 4 buttons (Map, Location, Theme, Filter)
                      borderRadius: 16,
                      blur: 14,
                      alignment: Alignment.center,
                      border: 1.0,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: wDark 
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
                        colors: wDark
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
                                    color: wDark ? Colors.white : Colors.black87,
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
                            color: wDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
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
                                    color: wDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87.withValues(alpha: 0.7),
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
                            color: wDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
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
                                    color: wDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87.withValues(alpha: 0.9),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Divider 3
                          Container(
                            height: 1,
                            width: 32,
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                          ),
                          // Filter Broken Poles Button
                          Tooltip(
                            message: "Show Only Broken",
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
                                  setState(() => _showOnlyBroken = !_showOnlyBroken);
                                },
                                child: Container(
                                  width: 48,
                                  height: 47,
                                  color: Colors.transparent,
                                  child: Icon(
                                    _showOnlyBroken
                                        ? CupertinoIcons.line_horizontal_3_decrease_circle_fill
                                        : CupertinoIcons.line_horizontal_3_decrease,
                                    color: _showOnlyBroken
                                        ? const Color(0xFF0A84FF)
                                        : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87.withValues(alpha: 0.9)),
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
                                  color: wDark ? const Color(0xFF262626).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
                                  ],
                                  border: Border.all(color: wDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1), width: 1.0),
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
                                              color: (wDark ? Colors.white : Colors.black).withValues(alpha: i == 0 ? 0.0 : 0.4), // Hide top tick for arrow
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
                                        color: wDark ? Colors.white70 : Colors.black87,
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
                        colors: wDark 
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
                        colors: wDark
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
                                  color: wDark ? Colors.white : Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Divider
                          Container(
                            height: 1,
                            width: 32,
                            color: wDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
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
                                  color: wDark ? Colors.white : Colors.black87,
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
        
          // === STREET VIEW OVERLAY (Web Only) ===
          if (kIsWeb && _showStreetView)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              bottom: _isStreetViewExpanded ? 24 : MediaQuery.of(context).padding.bottom + 24,
              right: _isStreetViewExpanded ? 88 : 88, // Pulls the expanded view left to clear the FABs
              left: null,
              top: null,
              child: StreetViewWidget(
                latitude: _currentMapCenter?.latitude ?? _initialCenter.latitude,
                longitude: _currentMapCenter?.longitude ?? _initialCenter.longitude,
                apiKey: _googleApiKey,
                isExpanded: _isStreetViewExpanded,
                isSidebarExpanded: _isWebSidebarExpanded,
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
                            colors: wDark 
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
                            colors: wDark
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
                            color: wDark ? Colors.white70 : Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // === MARK POLE BUTTON (Map Marker Role Only) ===
          if (authState.role == AppRole.marker && !isMarkingPole)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: MediaQuery.of(context).padding.bottom + 24,
              right: kIsWeb ? 90 : 24, // Avoid overlapping StreetView button on web
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isReportPanelOpen ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isReportPanelOpen,
                  child: FloatingActionButton.extended(
                    backgroundColor: const Color(0xFF0A84FF),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      // Navigate to the Map Marker Screen
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const MapMarkerScreen())
                      );
                    },
                    icon: const Icon(Icons.add_location_alt, color: Colors.white),
                    label: const Text(
                      "Mark Pole", 
                      style: TextStyle(fontFamily: 'GoogleSansFlex', color: Colors.white, fontWeight: FontWeight.bold)
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
                opacity: _isSearchActive || _isReportPanelOpen ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isSearchActive || _isReportPanelOpen,
                  child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isReportPanelOpen = true);
                  },
                  child: GlassmorphicContainer(
                    width: 180, // Increased width
                    height: 52,
                    borderRadius: 100, // Apple-like squircle
                    blur: 35,
                    alignment: Alignment.center,
                    border: 1.5,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E2C3A).withValues(alpha: 0.95), // Deep navy
                        const Color(0xFF16202A).withValues(alpha: 0.95),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_bubble, color: Color(0xFF4A90E2), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Report an Issue',
                          style: TextStyle(fontFamily: 'GoogleSansFlex', 
                            color: const Color(0xFF4A90E2),
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

          // === NEAREST STREETLIGHT CARD (Bottom Center) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: _showNearestPoleButton && !_isReportPanelOpen
                ? MediaQuery.of(context).padding.bottom + 24
                : -120, // Slide off-screen when hidden
            left: 0,
            right: 0,
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                  child: Container(
                  width: 340,
                  decoration: BoxDecoration(
                    color: wDark
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: wDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                        children: [
                          // Left: Text info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Nearest Streetlight',
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    color: wDark ? Colors.white : Colors.black87,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_nearestPoleLocation.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _nearestPoleLocation,
                                    style: TextStyle(
                                      fontFamily: 'GoogleSansFlex',
                                      color: wDark
                                          ? Colors.white.withValues(alpha: 0.55)
                                          : Colors.black54,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right: GO button
                          GestureDetector(
                            onTap: _navigateToNearestPole,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  'GO',
                                  style: TextStyle(
                                    fontFamily: 'GoogleSansFlex',
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
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
                opacity: _isReportPanelOpen ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _isReportPanelOpen,
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
                            
                            AppNotifications.show(
                              context: context,
                              message: 'Moved to: $displayName',
                              icon: CupertinoIcons.location_solid,
                              iconColor: const Color(0xFF0A84FF),
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
                                child: _buildActionButtons(wDark),
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
              onClose: () => setState(() {
                _selectedPole = null;
                _isReportPanelOpen = false;
              }),
              onReportTapped: () => setState(() => _isReportPanelOpen = true),
            ),

          // === SEARCH WARDS SIDEBAR ===
          if (MediaQuery.of(context).size.width >= 768)
            SearchWardsSidebar(
              isVisible: _isSearchWardsOpen,
              leftPosition: _isWebSidebarExpanded ? 240 : 104,
              onClose: () => setState(() => _isSearchWardsOpen = false),
              poleDataList: _poleDataList,
              userLat: _currentPosition?.latitude ?? _currentMapCenter?.latitude,
              userLon: _currentPosition?.longitude ?? _currentMapCenter?.longitude,
              onPoleSelected: (pole) {
                HapticFeedback.mediumImpact();
                final lat = pole['latitude'] as double;
                final lng = pole['longitude'] as double;
                setState(() {
                  _selectedPole = pole;
                  _isSearchWardsOpen = false;
                  _showNearestPoleButton = false;
                });
                _mapController.move(LatLng(lat, lng), 18.0);
              },
              onLocationSelected: (lat, lng, displayName) {
                _mapController.move(LatLng(lat, lng), 16.0);
                setState(() => _isSearchWardsOpen = false);
                AppNotifications.show(
                  context: context,
                  message: 'Moved to: $displayName',
                  icon: CupertinoIcons.location_solid,
                  iconColor: const Color(0xFF0A84FF),
                );
              },
            ),

          // === REPORT SIDE PANEL ===
          Builder(
            builder: (context) {
              final isDesktop = MediaQuery.of(context).size.width >= 768;
              double baseLeft = _isWebSidebarExpanded ? 240 : 104;
              
              if (isDesktop) {
                if (_selectedPole != null) {
                  baseLeft += 420 + 16;
                } else if (_isSearchWardsOpen) {
                  baseLeft += 420 + 16;
                }
              }
              
              return ReportSidePanel(
                isOpen: _isReportPanelOpen,
                leftPosition: isDesktop ? baseLeft : null,
                poleId: _selectedPole?['id'],
                onClose: () => setState(() => _isReportPanelOpen = false),
              );
            },
          ),

          // === REPORT MODAL ===
          // Removed: ReportIssueDialog is deprecated in favor of ReportSidePanel
          
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
                  AppNotifications.show(
                    context: context,
                    message: 'Moved to: $displayName',
                    icon: CupertinoIcons.location_solid,
                    iconColor: const Color(0xFF0A84FF),
                  );
                },
                onReportTapped: () {
                  setState(() => _isReportPanelOpen = true);
                },
                onSearchTapped: () {
                  setState(() {
                    _isSearchWardsOpen = !_isSearchWardsOpen;
                    // Close pole info if search is opening
                    if (_isSearchWardsOpen) _selectedPole = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(bool wDark) {
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
                  color: wDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8), 
                  border: Border.all(color: wDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(100), // Pill shape
                ),
                child: Row(
                  children: [
                    Icon(action.$2, color: const Color(0xFF008FFF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      action.$1,
                      style: TextStyle(fontFamily: 'GoogleSansFlex', 
                        color: wDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
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

  List<Marker> _buildMarkers() {
    return _poleDataList.where((pole) {
      if (_showOnlyBroken) {
        final status = pole['status'] as String;
        return status == 'Reported' || status == 'Maintenance';
      }
      return true;
    }).map((pole) {
      final lat = pole['latitude'] as double;
      final lng = pole['longitude'] as double;
      final status = pole['status'] as String;
      final fullId = pole['id'].toString();

      final isExpanded = _expandedPoleId == fullId;

      // Status color mapping (Light Outline/Text)
      Color statusColor;

      switch (status) {
        case 'Maintenance': // Not Working
          statusColor = const Color(0xFFFE3D2F);
          break;
        case 'Reported':
          statusColor = const Color(0xFFFE9500);
          break;
        case 'Active': // Working
          statusColor = const Color(0xFF53B36F);
          break;
        default:
          statusColor = const Color(0xFF0A84FF); // Light Blue fallback
      }

      return Marker(
        point: LatLng(lat, lng),
        width: isExpanded ? 140 : 54, // slightly larger for the box look
        height: 54,
        child: GestureDetector(
          onTap: () {
          HapticFeedback.lightImpact();
          if (mounted) {
            if (isExpanded) {
              // If already expanded, tap again to collapse
              setState(() {
                _expandedPoleId = null;
                if (_selectedPole?['id'] == fullId) {
                  _selectedPole = null; // Close side panel if it's the currently selected pole
                }
              });
            } else {
              // Single tap: Expand marker AND open pole info sidebar
              setState(() {
                _expandedPoleId = fullId;
                _selectedPole = {
                  'id': fullId,
                  'status': status,
                  'latitude': lat,
                  'longitude': lng,
                };
                _isSearchWardsOpen = false;
              });
              _mapController.move(LatLng(lat, lng), 18.0); // Center and zoom in
            }
          }
        },
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF202020).withOpacity(0.95), // Original Dark, sleek box
              borderRadius: BorderRadius.circular(100), // Perfect circle pill shape
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), // Reverted shadow
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  isExpanded
                      ? 'assets/icons/fluent-color--lightbulb-checkmark-32.svg'
                      : 'assets/icons/fluent-color--lightbulb-48.svg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'GoogleSansFlex',
                        color: statusColor, // Light text color
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
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