/// Unified Search Service
/// Uses the Photon (komoot) API for high-quality, CORS-friendly
/// search suggestions with local bias towards Maharagama, Sri Lanka.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A prediction result from the search service
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? lat;
  final double? lon;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.lat,
    this.lon,
  });

  factory PlacePrediction.fromPhoton(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;

    final name = props['name'] as String? ?? 'Unknown';
    final city = props['city'] as String? ?? props['state'] as String? ?? '';
    final country = props['country'] as String? ?? '';
    
    // Construct secondary text from city/state and country
    final List<String> secondaryParts = [];
    if (city.isNotEmpty) secondaryParts.add(city);
    if (country.isNotEmpty) secondaryParts.add(country);
    
    return PlacePrediction(
      placeId: props['osm_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: '$name${secondaryParts.isNotEmpty ? ', ${secondaryParts.join(', ')}' : ''}',
      mainText: name,
      secondaryText: secondaryParts.join(', '),
      lat: (coords[1] as num).toDouble(),
      lon: (coords[0] as num).toDouble(),
    );
  }
}

/// Service for interacting with search providers (Photon/Google)
class GooglePlacesService {
  // Keeping the name to avoid breaking imports but switching implementation to Photon
  // as it is high quality, supports CORS on Web, and requires no API key.
  
  static const String _photonUrl = 'https://photon.komoot.io/api';

  /// Get autocomplete suggestions for a search query.
  /// Biased towards Maharagama/Colombo area.
  static Future<List<PlacePrediction>> autocomplete(
    String query, {
    int maxResults = 8,
    String? sessionToken,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = {
        'q': query,
        'limit': '15', // Fetch more to allow for filtering
        'lang': 'en',
        // Bounding box for Sri Lanka: left,bottom,right,top
        'bbox': '79.5,5.9,81.9,9.9',
        // Bias towards Maharagama/Colombo area
        'lat': '6.8482',
        'lon': '79.9265',
        'location_bias_scale': '0.8', // Stronger bias
      };

      final uri = Uri.parse(_photonUrl).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];

        return features
            .map((f) => PlacePrediction.fromPhoton(f as Map<String, dynamic>))
            // Strict filter: Ensure country or description contains Sri Lanka/ශ්‍රී ලංකාව/இலங்கை
            .where((p) => p.description.toLowerCase().contains('sri lanka') || 
                          p.description.contains('ශ්‍රී ලංකාව') || 
                          p.description.contains('இலங்கை'))
            .take(maxResults)
            .toList();
      }
    } catch (e) {
      debugPrint('Search Exception: $e');
    }

    return [];
  }

  /// Get lat/lng coordinates for a place.
  /// (With Photon, coordinates are included in the search result, so this is just a passthrough)
  static Future<({double lat, double lng})?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    // Current implementation stores lat/lng in the prediction itself
    return null; 
  }

  static String generateSessionToken() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  }
}
