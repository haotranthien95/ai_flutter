import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/storage/database/database_helper.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';

/// Global providers for dependency injection.
///
/// These providers are available throughout the app via ProviderScope.

/// Dio provider (HTTP client).
final dioProvider = Provider<Dio>((ref) => Dio());

/// API client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Local storage provider (SharedPreferences).
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

/// Secure storage provider (FlutterSecureStorage).
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Database helper provider (SQLite).
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});
