/// Lumina Lanka - User Model
/// Represents a user with role-based access
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// App user data model
class AppUser {
  /// Unique user identifier (Firebase Auth UID)
  final String userId;
  
  /// User's display name
  final String name;
  
  /// User's phone number
  final String? phone;
  
  /// User's email address
  final String? email;
  
  /// User's role in the system
  final UserRole role;
  
  /// Profile photo URL
  final String? photoUrl;
  
  /// When the user was created
  final DateTime createdAt;
  
  /// Whether the user account is active
  final bool isActive;
  
  /// Ward number (for electricians, optional)
  final int? assignedWard;

  const AppUser({
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.isActive = true,
    this.assignedWard,
  });

  /// Create an AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      userId: doc.id,
      name: data['name'] as String,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.value == data['role'],
        orElse: () => UserRole.public_user,
      ),
      photoUrl: data['photo_url'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      isActive: data['is_active'] as bool? ?? true,
      assignedWard: data['assigned_ward'] as int?,
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'role': role.value,
      if (photoUrl != null) 'photo_url': photoUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'is_active': isActive,
      if (assignedWard != null) 'assigned_ward': assignedWard,
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? userId,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? photoUrl,
    DateTime? createdAt,
    bool? isActive,
    int? assignedWard,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      assignedWard: assignedWard ?? this.assignedWard,
    );
  }

  /// Check if user is council admin
  bool get isCouncil => role == UserRole.council;
  
  /// Check if user is electrician
  bool get isElectrician => role == UserRole.electrician;
  
  /// Check if user is map marker
  bool get isMarker => role == UserRole.marker;
  
  /// Check if user is public user
  bool get isPublic => role == UserRole.public_user;

  @override
  String toString() => 'AppUser($userId, role: ${role.label})';
}
