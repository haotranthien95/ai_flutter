import 'package:dio/dio.dart';

import '../../app/config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// API client using Dio for HTTP requests.
///
/// Centralized HTTP client with interceptors for authentication,
/// logging, and error handling. All network requests should use this client.
class ApiClient {
  /// Creates an API client with configured interceptors.
  ///
  /// The client is configured with:
  /// - Base URL from [AppConfig]
  /// - Timeout settings
  /// - JSON content type
  /// - Auth, logging, and error interceptors
  ApiClient({
    Dio? dio,
    AuthInterceptor? authInterceptor,
    ErrorInterceptor? errorInterceptor,
    LoggingInterceptor? loggingInterceptor,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, dynamic>{
        'Accept': 'application/json',
      },
    );

    // Add interceptors in order: Auth -> Logging -> Error
    _dio.interceptors.addAll([
      authInterceptor ?? AuthInterceptor(),
      if (AppConfig.enableDebugLogging)
        loggingInterceptor ?? LoggingInterceptor(),
      errorInterceptor ?? ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  /// Get the underlying Dio instance.
  ///
  /// Use this for advanced operations that require direct Dio access.
  Dio get dio => _dio;

  /// Perform a GET request.
  ///
  /// [path] is the endpoint path (e.g., '/products').
  /// [queryParameters] are optional query parameters.
  /// [options] allows request-specific configuration.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform a POST request.
  ///
  /// [path] is the endpoint path (e.g., '/auth/login').
  /// [data] is the request body (will be JSON-encoded).
  /// [options] allows request-specific configuration.
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform a PUT request.
  ///
  /// [path] is the endpoint path.
  /// [data] is the request body (will be JSON-encoded).
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform a PATCH request.
  ///
  /// [path] is the endpoint path.
  /// [data] is the request body (will be JSON-encoded).
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform a DELETE request.
  ///
  /// [path] is the endpoint path.
  /// [data] is optional request body.
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload files using multipart/form-data.
  ///
  /// Useful for image uploads. [FormData] should contain file fields.
  Future<Response<T>> upload<T>(
    String path, {
    required FormData formData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post<T>(
      path,
      data: formData,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// Download a file.
  ///
  /// [path] is the endpoint path.
  /// [savePath] is the local file path to save the downloaded file.
  Future<Response<dynamic>> download(
    String path,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    return _dio.download(
      path,
      savePath,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
