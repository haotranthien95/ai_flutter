import '../../../../core/models/user.dart';

/// Authentication repository interface.
///
/// Defines contract for authentication operations including registration,
/// login, OTP verification, token management, and password reset.
abstract class AuthRepository {
  /// Register a new user with phone number, password, and full name.
  ///
  /// Throws:
  /// - [Exception] if phone number already exists (409 conflict)
  /// - [Exception] for network or server errors
  Future<User> register({
    required String phoneNumber,
    required String password,
    required String fullName,
  });

  /// Verify OTP code for phone number verification.
  ///
  /// Returns authentication tokens (access and refresh) on success.
  ///
  /// Throws:
  /// - [Exception] if OTP is invalid or expired
  Future<Map<String, String>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  });

  /// Login with phone number and password.
  ///
  /// Returns user data with authentication tokens.
  ///
  /// Throws:
  /// - [Exception] if credentials are invalid (401 unauthorized)
  /// - [Exception] if account is suspended
  Future<User> login({
    required String phoneNumber,
    required String password,
  });

  /// Logout current user and clear stored tokens.
  Future<void> logout();

  /// Refresh access token using refresh token.
  ///
  /// Returns new access and refresh tokens.
  ///
  /// Throws:
  /// - [Exception] if refresh token is invalid or expired
  Future<Map<String, String>> refreshToken({
    required String refreshToken,
  });

  /// Request password reset by sending OTP to phone number.
  ///
  /// Throws:
  /// - [Exception] if phone number is not registered
  Future<void> forgotPassword({
    required String phoneNumber,
  });

  /// Reset password with OTP verification.
  ///
  /// Throws:
  /// - [Exception] if OTP is invalid
  Future<void> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  });

  /// Get current authenticated user from stored tokens.
  ///
  /// Returns null if no user is authenticated.
  Future<User?> getCurrentUser();

  /// Check if user is authenticated (has valid tokens).
  Future<bool> isAuthenticated();
}
