import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Default to English ('en'). 
// Sinhala is 'si', Tamil is 'ta'.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));