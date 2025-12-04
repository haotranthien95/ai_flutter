import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

/// Implementation of AuthRepository.
///
/// Manages authentication state with secure token storage.
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an AuthRepositoryImpl instance.
  AuthRepositoryImpl(this._dataSource, this._secureStorage);

  final AuthRemoteDataSource _dataSource;
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  @override
  Future<User> register({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    return _dataSource.register(
      phoneNumber: phoneNumber,
      password: password,
      fullName: fullName,
    );
  }

  @override
  Future<Map<String, String>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final tokens = await _dataSource.verifyOTP(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );

    // Save tokens to secure storage
    await _saveTokens(
      accessToken: tokens['accessToken']!,
      refreshToken: tokens['refreshToken']!,
    );

    return tokens;
  }

  @override
  Future<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dataSource.login(
      phoneNumber: phoneNumber,
      password: password,
    );

    final user = response['user'] as User;
    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;

    // Save tokens to secure storage
    await _saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return user;
  }

  @override
  Future<void> logout() async {
    try {
      // Try to logout on server
      await _dataSource.logout();
    } catch (_) {
      // Ignore server errors, still clear local tokens
    }

    // Always clear local tokens
    await _clearTokens();
  }

  @override
  Future<Map<String, String>> refreshToken({
    required String refreshToken,
  }) async {
    final tokens = await _dataSource.refreshToken(
      refreshToken: refreshToken,
    );

    // Save new tokens
    await _saveTokens(
      accessToken: tokens['accessToken']!,
      refreshToken: tokens['refreshToken']!,
    );

    return tokens;
  }

  @override
  Future<void> forgotPassword({
    required String phoneNumber,
  }) async {
    return _dataSource.forgotPassword(phoneNumber: phoneNumber);
  }

  @override
  Future<void> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    return _dataSource.resetPassword(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken == null) {
      return null;
    }

    // In a real implementation, decode JWT or fetch user from server
    // For now, return null to indicate token exists but user needs to be fetched
    return null;
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    return accessToken != null;
  }

  /// Save authentication tokens to secure storage.
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Clear all stored tokens.
  Future<void> _clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }
}
