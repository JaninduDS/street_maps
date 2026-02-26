/// Lumina Lanka - Main Map Screen
/// OpenStreetMap integration (flutter_map) with CartoDB Dark Matter
/// Cross-platform support (Linux, Web, Mobile)
library;

import 'dart:async';
import 'dart:io'; // Required for Platform check
import 'package:flutter/foundation.dart'; // Required for kIsWeb check
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../shared/widgets/unified_glass_sheet.dart';
import '../../report/presentation/report_side_panel.dart';
import '../../report/presentation/report_issue_dialog.dart';
import '../../../shared/widgets/web_sidebar.dart';

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
  
  // Initial Center (Colombo/Maharagama area)
  static const LatLng _initialCenter = LatLng(6.9271, 79.8612);

  // Map Mode State - CartoDB Positron Light
  String _currentTileUrl = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  String _currentMapMode = 'Explore'; // Explore, Driving, Transit, Satellite
  List<String> _currentSubdomains = ['a', 'b', 'c', 'd'];
  bool _isMapModeOpen = false; // Track if Map Modes sheet is open
  
  // Report Panel State
  bool _isReportPanelOpen = false;
  
  // Search State
  bool _isSearchFocused = false;
  bool _isSearchActive = false; // Tracks if search results are shown (submitted)

  // Report State
  bool _showReportModal = false; // New modal state

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocation();
    _addDemoPoles();
    // Initialize center
    _currentMapCenter = _initialCenter;
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Street Light #${i + 100}: ${poles[i].$3}')),
                  );
                },
                child: Icon(
                  Icons.lightbulb,
                  color: poles[i].$4,
                  size: 30,
                  shadows: [
                    BoxShadow(
                      color: poles[i].$4.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
          );
        }
      });
    }
  }

  /// Show Map Modes Bottom Sheet
  void _showMapModeSheet() {
    setState(() => _isMapModeOpen = true); // Hide search bar

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Unified "Liquid Glass" Styling
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), // Floating margins
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 290, // Reduced height for tighter layout
            borderRadius: 20, // Match UnifiedGlassSheet
            blur: 5,         // Match UnifiedGlassSheet
            alignment: Alignment.center,
            border: 1.5,     // Match UnifiedGlassSheet
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF202020).withValues(alpha: 0.15),
                const Color(0xFF101010).withValues(alpha: 0.15),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header (Centered Title + Close Button)
                SizedBox(
                  height: 48, // Slightly taller for better touch targets
                  width: double.infinity, // Force full width for Stack positioning
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Title
                      Text(
                        'Map Modes',
                        style: TextStyle(fontFamily: 'GoogleSansFlex', 
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Close Button (Top Right)
                      Positioned(
                        right: 16, // Align to right edge with padding
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white70, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Grid Options (Using Assets)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeItem('Explore', 'assets/icons/explore.png'),
                      const SizedBox(width: 20),
                      _buildModeItem('Driving', 'assets/icons/driving.png'),
                      const SizedBox(width: 20),
                      _buildModeItem('Transit', 'assets/icons/transit.png'),
                      const SizedBox(width: 20),
                      _buildModeItem('Satellite', 'assets/icons/satellite.png'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25), // Fixed spacing instead of Expanded

                // Footer attribution
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    '© OpenStreetMap and other data providers',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Re-show search bar when sheet closes
      if (mounted) setState(() => _isMapModeOpen = false);
    });
  }

  Widget _buildModeItem(String title, String imagePath) {
    final isSelected = _currentMapMode == title;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentMapMode = title;
          if (title == 'Explore') {
            // CartoDB Positron
            _currentTileUrl = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
            _currentSubdomains = ['a', 'b', 'c', 'd'];
          } else if (title == 'Driving') {
            // CartoDB Voyager
            _currentTileUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
            _currentSubdomains = ['a', 'b', 'c', 'd'];
          } else if (title == 'Transit') {
            // CartoDB Positron Labels
            _currentTileUrl = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
            _currentSubdomains = ['a', 'b', 'c', 'd'];
          } else if (title == 'Satellite') {
            // Google Maps Satellite 
            _currentTileUrl = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
            _currentSubdomains = [];
          }
        });
        Navigator.pop(context);
      },
      child: Column(
        children: [
          // Image Container
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? Border.all(color: const Color(0xFF008FFF), width: 3) : Border.all(color: Colors.white.withValues(alpha: 0.1)),
              image: DecorationImage(
                 image: AssetImage(imagePath),
                 fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // Checkmark overlay if selected
            child: isSelected 
              ? const Align(
                  alignment: Alignment.topRight, 
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.check_circle, color: Color(0xFF008FFF), size: 20),
                  ),
                ) 
              : null,
          ),
          const SizedBox(height: 10),
          
          // Text
          Text(
            title,
            style: TextStyle(fontFamily: 'GoogleSansFlex', 
              color: isSelected ? const Color(0xFF008FFF) : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Match light map background
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
              },
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Dynamic Tile Layer - Clean OSM Bright style
              TileLayer(
                urlTemplate: _currentTileUrl,
                userAgentPackageName: 'com.maharagama.lumina_lanka',
                subdomains: _currentSubdomains,
                // Disable retina mode to prevent tiny text on high-DPI screens
                retinaMode: false,
                tileSize: 256, // Ensure standard tile sizing
              ),
              
              // Markers Layer
              MarkerLayer(markers: _markers),
            ],
          ),
          
          // === BLUR OVERLAY (Visible when Report Modal is Open) ===
          if (_showReportModal)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1), // Slight dim
                ),
              ),
            ),
              
          // === FLOATING ACTION PILL (Right Side) ===
          // Hide when Map Mode is open too
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: MediaQuery.of(context).padding.top + 16,
            right: _isMapModeOpen ? -70 : 16, // Slide out if map mode open
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showReportModal ? 0.0 : 1.0,
              child: GlassmorphicContainer(
              width: 54, // Pill width
              height: 120, // Height for 2 buttons
              borderRadius: 27, // Fully rounded pill
              blur: 5,
              alignment: Alignment.center,
              border: 1.5,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.8),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.05),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Map Mode Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showMapModeSheet();
                    },
                    child: const Icon(
                      CupertinoIcons.map_fill, // Folded map icon
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                  
                  // Divider
                  Container(
                    width: 30,
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),

                  // Location Arrow
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _initLocation();
                    },
                    child: const Icon(
                      CupertinoIcons.location_fill,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                ],
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
                                child: _buildActionButtons(),
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
  Widget _buildActionButtons() {
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
                  color: Colors.black.withValues(alpha: 0.5), // Lighter black to match widget
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(100), // Pill shape
                ),
                child: Row(
                  children: [
                    Icon(action.$2, color: const Color(0xFF008FFF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      action.$1,
                      style: TextStyle(fontFamily: 'GoogleSansFlex', 
                        color: Colors.white.withValues(alpha: 0.9), // Slightly brighter text
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

