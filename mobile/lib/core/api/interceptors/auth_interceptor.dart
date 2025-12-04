import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';

/// Interceptor for handling authentication tokens.
///
/// Automatically injects JWT access tokens into request headers
/// and handles 401 Unauthorized responses by attempting token refresh.
class AuthInterceptor extends Interceptor {
  /// Creates an auth interceptor.
  ///
  /// [secureStorage] is optional for testing. If not provided,
  /// creates a new [SecureStorage] instance.
  AuthInterceptor({SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  final SecureStorage _secureStorage;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login/register endpoints
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    try {
      // Get access token from secure storage
      final String? accessToken = await _secureStorage.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        // Inject token into Authorization header
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      return handler.next(options);
    } catch (e) {
      // If token retrieval fails, continue without auth header
      return handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - token might be expired
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        // Attempt to refresh the token
        final bool refreshed = await _refreshToken(err.requestOptions);

        if (refreshed) {
          // Retry the original request with new token
          final Response<dynamic> response = await _retry(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (refreshError) {
        // Token refresh failed - clear tokens and reject
        await _secureStorage.deleteAllTokens();
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }

  /// Check if the endpoint should skip authentication.
  bool _shouldSkipAuth(String path) {
    const List<String> publicPaths = <String>[
      '/auth/login',
      '/auth/register',
      '/auth/verify-otp',
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/products', // Public product browsing
      '/categories',
    ];

    return publicPaths.any((String publicPath) => path.contains(publicPath));
  }

  /// Attempt to refresh the access token using the refresh token.
  Future<bool> _refreshToken(RequestOptions requestOptions) async {
    try {
      final String? refreshToken = await _secureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Create a new Dio instance to avoid interceptor recursion
      final Dio dio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));

      final Response<Map<String, dynamic>> response =
          await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final String? newAccessToken = response.data!['accessToken'] as String?;
        final String? newRefreshToken =
            response.data!['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.saveAccessToken(newAccessToken);
        }

        if (newRefreshToken != null) {
          await _secureStorage.saveRefreshToken(newRefreshToken);
        }

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Retry the failed request with the new access token.
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final String? newAccessToken = await _secureStorage.getAccessToken();

    if (newAccessToken != null) {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
    }

    final Dio dio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }
}
