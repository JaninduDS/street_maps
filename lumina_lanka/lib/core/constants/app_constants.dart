/// Lumina Lanka - App Constants
/// Central location for all application constants
library;

/// Geographic constants for Maharagama Urban Council
class GeoConstants {
  GeoConstants._();
  
  /// Center point of Maharagama Urban Council area
  static const double maharagamaCenterLat = 6.85;
  static const double maharagamaCenterLng = 79.92;
  
  /// Pilot zone radius in kilometers (5km from center)
  static const double pilotZoneRadiusKm = 5.0;
  
  /// High accuracy GPS threshold in meters
  static const double gpsAccuracyThresholdMeters = 5.0;
  
  /// Default map zoom levels
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;
  static const double markerModeZoom = 18.0;
}

/// Pole status enum
enum PoleStatus {
  working('working', 'Working'),
  reported('reported', 'Reported'),
  assigned('assigned', 'Assigned'),
  maintenance('maintenance', 'In Maintenance'),
  resolved('resolved', 'Resolved');
  
  const PoleStatus(this.value, this.label);
  final String value;
  final String label;
}

/// Pole type enum
enum PoleType {
  concrete('concrete', 'Concrete'),
  iron('iron', 'Iron');
  
  const PoleType(this.value, this.label);
  final String value;
  final String label;
}

/// Bulb type enum
enum BulbType {
  led30w('led_30w', 'LED 30W'),
  led50w('led_50w', 'LED 50W'),
  sodium('sodium', 'Sodium Vapor'),
  cfl('cfl', 'CFL');
  
  const BulbType(this.value, this.label);
  final String value;
  final String label;
}

/// Issue type enum
enum IssueType {
  burnt('burnt', 'Light Not ON'),
  flickering('flickering', 'Flickering'),
  damaged('damaged', 'Pole Damaged'),
  other('other', 'Other Issue');
  
  const IssueType(this.value, this.label);
  final String value;
  final String label;
}

/// User role enum
enum UserRole {
  public_user('public', 'Public User'),
  council('council', 'Council Admin'),
  electrician('electrician', 'Electrician'),
  marker('marker', 'Map Marker');
  
  const UserRole(this.value, this.label);
  final String value;
  final String label;
}

/// Assignment status enum
enum AssignmentStatus {
  assigned('assigned', 'Assigned'),
  inspected('inspected', 'Inspected'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');
  
  const AssignmentStatus(this.value, this.label);
  final String value;
  final String label;
}
