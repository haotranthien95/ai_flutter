import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor for logging HTTP requests and responses.
///
/// Only logs in debug mode when [AppConfig.enableDebugLogging] is true.
/// Logs request details (method, URL, headers, body) and response details
/// (status code, headers, body) to help with debugging.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🚀 REQUEST [${options.method}] ${options.uri}');
      debugPrint('Headers: ${options.headers}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('Query Parameters: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('Body: ${_formatData(options.data)}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint(
        '✅ RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
      );
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body: ${_formatData(response.data)}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint(
          '❌ ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}');
      debugPrint('Error Type: ${err.type}');
      debugPrint('Error Message: ${err.message}');
      if (err.response != null) {
        debugPrint('Response: ${_formatData(err.response!.data)}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    return handler.next(err);
  }

  /// Format data for logging, truncating if too long.
  String _formatData(dynamic data) {
    if (data == null) {
      return 'null';
    }

    String formatted = data.toString();

    // Truncate very long responses (e.g., large lists)
    const int maxLength = 500;
    if (formatted.length > maxLength) {
      formatted = '${formatted.substring(0, maxLength)}... (truncated)';
    }

    return formatted;
  }
}
