/// Lumina Lanka - Map Marker Screen
/// Primary screen for volunteers to mark street light pole locations
/// Uses OpenStreetMap with CartoDB Dark Matter tiles
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_notifications.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import 'widgets/pole_form_sheet.dart';

/// CartoDB Dark Matter tile URL for iOS 26 dark theme
const String _darkTileUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

/// Map Marker screen for placing street light poles
class MapMarkerScreen extends ConsumerStatefulWidget {
  const MapMarkerScreen({super.key});

  @override
  ConsumerState<MapMarkerScreen> createState() => _MapMarkerScreenState();
}

class _MapMarkerScreenState extends ConsumerState<MapMarkerScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;
  bool _isAccurate = false;
  int _polesMarkedToday = 0;
  
  // Map markers for placed poles
  final List<Marker> _markers = [];
  
  // Center point for the ghost pin
  LatLng _centerPosition = LatLng(
    GeoConstants.maharagamaCenterLat,
    GeoConstants.maharagamaCenterLng,
  );

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Initialize location services and start tracking
  Future<void> _initLocationService() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them.');
        setState(() => _isLoading = false);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied.');
        setState(() => _isLoading = false);
        return;
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _centerPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _isAccurate = position.accuracy <= GeoConstants.gpsAccuracyThresholdMeters;
      });

      // Move map to current position
      _mapController.move(_centerPosition, GeoConstants.markerModeZoom);

      // Start listening to position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Update every 1 meter
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
          _isAccurate = position.accuracy <= GeoConstants.gpsAccuracyThresholdMeters;
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to get location: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppNotifications.show(
      context: context,
      message: message,
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      iconColor: AppColors.accentRed,
    );
  }

  /// Generate a unique pole ID
  String _generatePoleId(int wardNumber) {
    final uuid = const Uuid().v4().substring(0, 4).toUpperCase();
    return 'MUC-W$wardNumber-$uuid';
  }

  /// Handle marking a pole at current position
  Future<void> _markPole() async {
    if (_currentPosition == null) {
      _showError('Unable to get your current location.');
      return;
    }

    if (!_isAccurate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Low GPS Accuracy'),
          content: Text(
            'Current accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m\n'
            'Recommended: ≤${GeoConstants.gpsAccuracyThresholdMeters}m\n\n'
            'Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Wait'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Use map center position for marking
    final markPosition = _centerPosition;

    // Show pole form sheet
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PoleFormSheet(
        latitude: markPosition.latitude,
        longitude: markPosition.longitude,
        poleId: _generatePoleId(1), // TODO: Detect ward from GPS
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true); // Show loading state
      
      try {
        // 1. Save to Supabase
        await Supabase.instance.client.from('poles').insert({
          'latitude': result['latitude'],
          'longitude': result['longitude'],
          'pole_type': result['poleType'],
          'bulb_type': result['bulbType'],
          'status': 'Working',
          'created_by': Supabase.instance.client.auth.currentUser?.id,
        });

        // 2. Add marker to map locally so they see it immediately
        setState(() {
          _markers.add(
            Marker(
              point: LatLng(result['latitude'], result['longitude']),
              width: 32,
              height: 32,
              child: const GlowOrbMarker(
                status: PoleStatus.working,
                size: 20,
                animate: false,
              ),
            ),
          );
          _polesMarkedToday++;
          _isLoading = false;
        });

        // 3. Show success feedback
        if (mounted) {
          HapticFeedback.heavyImpact();
          AppNotifications.show(
            context: context,
            message: 'Pole marked successfully!',
            icon: CupertinoIcons.check_mark_circled_solid,
            iconColor: AppColors.accentGreen,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Failed to save pole: $e');
      }
    }
  }

  /// Recenter map on current position
  void _recenterMap() {
    if (_currentPosition != null) {
      final position = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _mapController.move(position, GeoConstants.markerModeZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mark Poles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Stats indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGlass),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGreen,
                    boxShadow: GlowStyles.greenGlow,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_polesMarkedToday today',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GhostPinMarker(size: 48, isAccurate: false),
                  SizedBox(height: 24),
                  Text(
                    'Getting your location...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // OpenStreetMap with CartoDB Dark Matter tiles
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _centerPosition,
                    initialZoom: GeoConstants.markerModeZoom,
                    minZoom: GeoConstants.minZoom,
                    maxZoom: GeoConstants.maxZoom,
                    onPositionChanged: (position, hasGesture) {
                      setState(() {
                        _centerPosition = position.center;
                      });
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Dark tile layer (CartoDB Dark Matter)
                    TileLayer(
                      urlTemplate: _darkTileUrl,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.maharagama.lumina_lanka',
                      tileProvider: NetworkTileProvider(),
                    ),
                    
                    // Current location marker
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentBlue,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: GlowStyles.blueGlow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                    // Placed pole markers
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Center crosshair / ghost pin
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GhostPinMarker(
                        size: 32,
                        isAccurate: _isAccurate,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isAccurate
                              ? AppColors.accentBlue
                              : AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                // GPS Accuracy indicator
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 16,
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAccurate
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed,
                              color: _isAccurate
                                  ? AppColors.accentGreen
                                  : AppColors.accentAmber,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_currentPosition?.accuracy.toStringAsFixed(1) ?? '—'}m',
                              style: TextStyle(
                                color: _isAccurate
                                    ? AppColors.accentGreen
                                    : AppColors.accentAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAccurate ? 'High accuracy' : 'Move to open area',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Legend
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  right: 16,
                  child: const StatusLegend(),
                ),

                // Recenter button
                Positioned(
                  bottom: 140,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: AppColors.bgSecondary,
                    onPressed: _recenterMap,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ),

                // Mark Pole Button
                Positioned(
                  bottom: 32,
                  left: 24,
                  right: 24,
                  child: GlassButton(
                    label: 'MARK POLE',
                    icon: Icons.add_location_alt,
                    onPressed: _markPole,
                    expanded: true,
                    color: _isAccurate
                        ? AppColors.accentGreen
                        : AppColors.accentAmber,
                  ),
                ),
              ],
            ),
    );
  }
}
