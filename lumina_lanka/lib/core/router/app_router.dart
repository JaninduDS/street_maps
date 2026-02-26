/// Lumina Lanka - App Router
/// Placeholder for GoRouter navigation setup
/// Will be implemented with proper role-based routing
library;

import 'package:flutter/material.dart';

/// Router configuration placeholder
/// TODO: Implement GoRouter with:
/// - Authentication guard
/// - Role-based routing (public, council, electrician, marker)
/// - Deep linking support
class AppRouter {
  AppRouter._();
  
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String roleSelect = '/role-select';
  
  // Public routes
  static const String publicMap = '/map';
  static const String publicReport = '/report';
  
  // Map Marker routes
  static const String markerMap = '/marker';
  static const String markerHistory = '/marker/history';
  
  // Council routes
  static const String councilDashboard = '/council';
  static const String councilIssues = '/council/issues';
  static const String councilElectricians = '/council/electricians';
  static const String councilAnalytics = '/council/analytics';
  
  // Electrician routes
  static const String electricianTasks = '/electrician';
  static const String electricianTask = '/electrician/task/:id';
}
