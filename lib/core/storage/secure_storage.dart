import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/config.dart';

/// Wrapper for FlutterSecureStorage to securely store sensitive data.
///
/// Used for storing JWT tokens, API keys, and other sensitive information.
/// Data is encrypted on device using platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
class SecureStorage {
  /// Creates a secure storage instance.
  ///
  /// [storage] is optional for testing. If not provided,
  /// creates a new [FlutterSecureStorage] instance.
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  /// Save the access token (JWT).
  ///
  /// Returns true if successful.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(
        key: AppConfig.secureStorageAccessTokenKey, value: token);
  }

  /// Get the access token.
  ///
  /// Returns null if no token is stored.
  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConfig.secureStorageAccessTokenKey);
  }

  /// Delete the access token.
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: AppConfig.secureStorageAccessTokenKey);
  }

  /// Save the refresh token.
  ///
  /// Returns true if successful.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
        key: AppConfig.secureStorageRefreshTokenKey, value: token);
  }

  /// Get the refresh token.
  ///
  /// Returns null if no token is stored.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConfig.secureStorageRefreshTokenKey);
  }

  /// Delete the refresh token.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConfig.secureStorageRefreshTokenKey);
  }

  /// Save the user ID.
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: AppConfig.sharedPrefsUserIdKey, value: userId);
  }

  /// Get the user ID.
  ///
  /// Returns null if no user ID is stored.
  Future<String?> getUserId() async {
    return _storage.read(key: AppConfig.sharedPrefsUserIdKey);
  }

  /// Delete the user ID.
  Future<void> deleteUserId() async {
    await _storage.delete(key: AppConfig.sharedPrefsUserIdKey);
  }

  /// Delete all tokens (access token, refresh token, user ID).
  ///
  /// Useful for logout functionality.
  Future<void> deleteAllTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
      deleteUserId(),
    ]);
  }

  /// Write a generic key-value pair.
  ///
  /// For custom secure storage needs beyond tokens.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value by key.
  ///
  /// Returns null if the key doesn't exist.
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  /// Delete a value by key.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Check if a key exists.
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: key);
  }

  /// Delete all data from secure storage.
  ///
  /// Use with caution - this removes ALL secure data.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Get all stored keys.
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }
}
