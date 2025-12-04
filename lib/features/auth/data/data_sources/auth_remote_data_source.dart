import 'package:dio/dio.dart';
import '../../../../core/models/user.dart';

/// Remote data source for authentication operations.
///
/// Communicates with backend API for user registration, login,
/// OTP verification, and password management.
class AuthRemoteDataSource {
  /// Creates an AuthRemoteDataSource instance.
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Register new user account.
  ///
  /// POST /auth/register
  ///
  /// Returns registered user (unverified).
  ///
  /// Throws:
  /// - [DioException] with 409 status if phone already exists
  Future<User> register({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'fullName': fullName,
      },
    );

    return User.fromJson(response.data!);
  }

  /// Verify OTP code for phone verification.
  ///
  /// POST /auth/verify-otp
  ///
  /// Returns authentication tokens.
  ///
  /// Throws:
  /// - [DioException] with 400 status if OTP invalid/expired
  Future<Map<String, String>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
      },
    );

    return {
      'accessToken': response.data!['accessToken'] as String,
      'refreshToken': response.data!['refreshToken'] as String,
    };
  }

  /// Login with credentials.
  ///
  /// POST /auth/login
  ///
  /// Returns user data and tokens.
  ///
  /// Throws:
  /// - [DioException] with 401 status if credentials invalid
  /// - [DioException] with 403 status if account suspended
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );

    return {
      'user': User.fromJson(response.data!['user'] as Map<String, dynamic>),
      'accessToken': response.data!['accessToken'] as String,
      'refreshToken': response.data!['refreshToken'] as String,
    };
  }

  /// Logout current session.
  ///
  /// POST /auth/logout
  ///
  /// Invalidates refresh token on server.
  Future<void> logout() async {
    await _dio.post<void>('/auth/logout');
  }

  /// Refresh access token.
  ///
  /// POST /auth/refresh
  ///
  /// Returns new token pair.
  ///
  /// Throws:
  /// - [DioException] with 401 status if refresh token invalid
  Future<Map<String, String>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );

    return {
      'accessToken': response.data!['accessToken'] as String,
      'refreshToken': response.data!['refreshToken'] as String,
    };
  }

  /// Request password reset OTP.
  ///
  /// POST /auth/forgot-password
  ///
  /// Sends OTP to registered phone number.
  ///
  /// Throws:
  /// - [DioException] with 404 status if phone not registered
  Future<void> forgotPassword({
    required String phoneNumber,
  }) async {
    await _dio.post<void>(
      '/auth/forgot-password',
      data: {
        'phoneNumber': phoneNumber,
      },
    );
  }

  /// Reset password with OTP verification.
  ///
  /// POST /auth/reset-password
  ///
  /// Throws:
  /// - [DioException] with 400 status if OTP invalid
  Future<void> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/auth/reset-password',
      data: {
        'phoneNumber': phoneNumber,
        'otpCode': otpCode,
        'newPassword': newPassword,
      },
    );
  }
}
