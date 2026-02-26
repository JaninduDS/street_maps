/// Lumina Lanka - Pole Model
/// Represents a street light pole with all its properties
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Street light pole data model
class Pole {
  /// Unique identifier (e.g., MUC-WARD1-004)
  final String poleId;
  
  /// GPS latitude coordinate
  final double latitude;
  
  /// GPS longitude coordinate
  final double longitude;
  
  /// Ward number within Maharagama UC
  final int wardNumber;
  
  /// Current status of the pole
  final PoleStatus status;
  
  /// Type of pole structure
  final PoleType poleType;
  
  /// Type of bulb installed
  final BulbType bulbType;
  
  /// Date when pole was marked/registered
  final DateTime createdAt;
  
  /// User ID who marked this pole
  final String createdBy;
  
  /// Last service/repair date
  final DateTime? lastServiceDate;
  
  /// Current bulb serial number (for warranty tracking)
  final String? bulbSerial;
  
  /// Warranty expiration date
  final DateTime? warrantyExpires;

  const Pole({
    required this.poleId,
    required this.latitude,
    required this.longitude,
    required this.wardNumber,
    required this.status,
    required this.poleType,
    required this.bulbType,
    required this.createdAt,
    required this.createdBy,
    this.lastServiceDate,
    this.bulbSerial,
    this.warrantyExpires,
  });

  /// Create a Pole from Firestore document
  factory Pole.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pole(
      poleId: doc.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      wardNumber: data['ward_number'] as int,
      status: PoleStatus.values.firstWhere(
        (e) => e.value == data['status'],
        orElse: () => PoleStatus.working,
      ),
      poleType: PoleType.values.firstWhere(
        (e) => e.value == data['pole_type'],
        orElse: () => PoleType.concrete,
      ),
      bulbType: BulbType.values.firstWhere(
        (e) => e.value == data['bulb_type'],
        orElse: () => BulbType.led30w,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      createdBy: data['created_by'] as String,
      lastServiceDate: data['last_service_date'] != null
          ? (data['last_service_date'] as Timestamp).toDate()
          : null,
      bulbSerial: data['bulb_serial'] as String?,
      warrantyExpires: data['warranty_expires'] != null
          ? (data['warranty_expires'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert Pole to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'ward_number': wardNumber,
      'status': status.value,
      'pole_type': poleType.value,
      'bulb_type': bulbType.value,
      'created_at': Timestamp.fromDate(createdAt),
      'created_by': createdBy,
      if (lastServiceDate != null)
        'last_service_date': Timestamp.fromDate(lastServiceDate!),
      if (bulbSerial != null) 'bulb_serial': bulbSerial,
      if (warrantyExpires != null)
        'warranty_expires': Timestamp.fromDate(warrantyExpires!),
    };
  }

  /// Create a copy with updated fields
  Pole copyWith({
    String? poleId,
    double? latitude,
    double? longitude,
    int? wardNumber,
    PoleStatus? status,
    PoleType? poleType,
    BulbType? bulbType,
    DateTime? createdAt,
    String? createdBy,
    DateTime? lastServiceDate,
    String? bulbSerial,
    DateTime? warrantyExpires,
  }) {
    return Pole(
      poleId: poleId ?? this.poleId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      wardNumber: wardNumber ?? this.wardNumber,
      status: status ?? this.status,
      poleType: poleType ?? this.poleType,
      bulbType: bulbType ?? this.bulbType,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      bulbSerial: bulbSerial ?? this.bulbSerial,
      warrantyExpires: warrantyExpires ?? this.warrantyExpires,
    );
  }

  @override
  String toString() => 'Pole($poleId, status: ${status.label})';
}
