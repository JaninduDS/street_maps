import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole { public, council, electrician, marker }

class AuthState {
  final User? user;
  final AppRole role;
  final bool isLoading;

  AuthState({this.user, this.role = AppRole.public, this.isLoading = false});

  AuthState copyWith({User? user, AppRole? role, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  void _init() {
    // Listen to Auth changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        final role = await _fetchUserRole(user.id);
        state = AuthState(user: user, role: role, isLoading: false);
      } else {
        state = AuthState(user: null, role: AppRole.public, isLoading: false);
      }
    });
  }

  Future<AppRole> _fetchUserRole(String uid) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      
      final roleString = data['role'] as String;
      return AppRole.values.firstWhere(
        (e) => e.name == roleString,
        orElse: () => AppRole.marker,
      );
    } catch (e) {
      return AppRole.public;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});