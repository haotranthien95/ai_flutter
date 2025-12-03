/// Application configuration for environment-specific settings.
///
/// This file contains all configurable values such as API URLs,
/// timeouts, and feature flags that may vary between development,
/// staging, and production environments.
library;

/// Application configuration class.
///
/// Provides centralized access to environment-specific settings.
/// Use environment variables or build configurations to set different
/// values for dev/staging/prod.
class AppConfig {
  /// Private constructor to prevent instantiation.
  AppConfig._();

  /// Environment type.
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// API timeout durations
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  /// WebSocket Configuration
  static const String websocketBaseUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://localhost:3000',
  );

  /// Storage Configuration
  static const String secureStorageAccessTokenKey = 'access_token';
  static const String secureStorageRefreshTokenKey = 'refresh_token';
  static const String sharedPrefsUserIdKey = 'user_id';
  static const String sharedPrefsThemeModeKey = 'theme_mode';
  static const String sharedPrefsLanguageKey = 'language';

  /// Cache Configuration
  static const int imageCacheMaxAgeInDays = 7;
  static const int imageCacheMaxObjects = 200;

  /// Pagination Configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Feature Flags
  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: false,
  );
  static const bool enableChat = bool.fromEnvironment(
    'ENABLE_CHAT',
    defaultValue: false,
  );
  static const bool enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: true,
  );

  /// Firebase Configuration (optional, for push notifications)
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  /// Image Upload Configuration
  static const int maxImageSizeInMB = 5;
  static const int maxImagesPerUpload = 5;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// OTP Configuration
  static const Duration otpExpiryDuration = Duration(minutes: 5);
  static const Duration otpResendCooldown = Duration(seconds: 60);

  /// Order Configuration
  static const Duration orderCancellationWindow = Duration(minutes: 15);

  /// Search Configuration
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);
  static const int minSearchQueryLength = 2;

  /// Currency Configuration
  static const String currencyCode = 'VND';
  static const String currencySymbol = '₫';
  static const String currencyLocale = 'vi_VN';

  /// Helper methods

  /// Check if running in development mode.
  static bool get isDevelopment => environment == 'development';

  /// Check if running in staging mode.
  static bool get isStaging => environment == 'staging';

  /// Check if running in production mode.
  static bool get isProduction => environment == 'production';

  /// Get full API URL by appending path to base URL.
  static String getApiUrl(String path) {
    if (path.startsWith('/')) {
      return '$apiBaseUrl$path';
    }
    return '$apiBaseUrl/$path';
  }

  /// Get WebSocket URL by appending path.
  static String getWebSocketUrl(String path) {
    if (path.startsWith('/')) {
      return '$websocketBaseUrl$path';
    }
    return '$websocketBaseUrl/$path';
  }
}
