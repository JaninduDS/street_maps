/// Lumina Lanka - Report Model
/// Represents an issue report for a street light
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// Issue report data model
class Report {
  /// Unique report identifier
  final String reportId;
  
  /// Reference to the pole being reported
  final String poleId;
  
  /// User ID who submitted the report
  final String reporterId;
  
  /// Type of issue being reported
  final IssueType issueType;
  
  /// Optional description of the issue
  final String? description;
  
  /// Optional photo URL of the issue
  final String? photoUrl;
  
  /// Current status of the report
  final String status; // 'reported', 'acknowledged', 'assigned', 'resolved'
  
  /// When the report was created
  final DateTime createdAt;
  
  /// When the report was last updated
  final DateTime updatedAt;
  
  /// Assigned electrician ID (if assigned)
  final String? assignedTo;
  
  /// When the report was assigned
  final DateTime? assignedAt;
  
  /// When the report was resolved
  final DateTime? resolvedAt;

  const Report({
    required this.reportId,
    required this.poleId,
    required this.reporterId,
    required this.issueType,
    this.description,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.assignedAt,
    this.resolvedAt,
  });

  /// Create a Report from Firestore document
  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      reportId: doc.id,
      poleId: data['pole_id'] as String,
      reporterId: data['reporter_id'] as String,
      issueType: IssueType.values.firstWhere(
        (e) => e.value == data['issue_type'],
        orElse: () => IssueType.burnt,
      ),
      description: data['description'] as String?,
      photoUrl: data['photo_url'] as String?,
      status: data['status'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      assignedTo: data['assigned_to'] as String?,
      assignedAt: data['assigned_at'] != null
          ? (data['assigned_at'] as Timestamp).toDate()
          : null,
      resolvedAt: data['resolved_at'] != null
          ? (data['resolved_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert Report to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'pole_id': poleId,
      'reporter_id': reporterId,
      'issue_type': issueType.value,
      if (description != null) 'description': description,
      if (photoUrl != null) 'photo_url': photoUrl,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (assignedAt != null) 'assigned_at': Timestamp.fromDate(assignedAt!),
      if (resolvedAt != null) 'resolved_at': Timestamp.fromDate(resolvedAt!),
    };
  }

  /// Create a copy with updated fields
  Report copyWith({
    String? reportId,
    String? poleId,
    String? reporterId,
    IssueType? issueType,
    String? description,
    String? photoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedTo,
    DateTime? assignedAt,
    DateTime? resolvedAt,
  }) {
    return Report(
      reportId: reportId ?? this.reportId,
      poleId: poleId ?? this.poleId,
      reporterId: reporterId ?? this.reporterId,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAt: assignedAt ?? this.assignedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Check if report is pending (not yet assigned)
  bool get isPending => status == 'reported' || status == 'acknowledged';
  
  /// Check if report is active (assigned but not resolved)
  bool get isActive => status == 'assigned';
  
  /// Check if report is resolved
  bool get isResolved => status == 'resolved';

  @override
  String toString() => 'Report($reportId, status: $status)';
}
