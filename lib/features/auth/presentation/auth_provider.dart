import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub auth provider for Phase 5 development
/// TODO: Replace with actual Phase 4 auth provider implementation

/// User model stub
class User {
  const User({
    required this.id,
    required this.phone,
    this.email,
    this.name,
  });

  final String id;
  final String phone;
  final String? email;
  final String? name;
}

/// Auth state notifier stub
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  /// Get current user (null if not authenticated)
  User? get currentUser => state.value;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Login stub (always returns null - not authenticated)
  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 100));
    state = const AsyncValue.data(null);
  }

  /// Logout stub
  Future<void> logout() async {
    state = const AsyncValue.data(null);
  }

  /// Set mock user for testing
  void setMockUser(User user) {
    state = AsyncValue.data(user);
  }
}

/// Auth provider stub
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);
