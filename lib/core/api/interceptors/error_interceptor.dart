import 'package:dio/dio.dart';

import '../api_error.dart';

/// Interceptor for mapping HTTP errors to custom exception types.
///
/// Converts Dio errors into domain-specific exceptions that can be
/// handled consistently throughout the app.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Map Dio errors to custom API exceptions
    final AppException exception = _mapDioErrorToAppException(err);

    // Reject with custom exception instead of DioException
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        message: exception.message,
      ),
    );
  }

  /// Map DioException to domain-specific AppException.
  AppException _mapDioErrorToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Kết nối bị gián đoạn. Vui lòng kiểm tra mạng.',
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(err);

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Yêu cầu đã bị hủy.',
          statusCode: null,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.',
          statusCode: null,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Lỗi bảo mật kết nối.',
          statusCode: null,
        );

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          message: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
          statusCode: null,
        );
    }
  }

  /// Handle bad response (4xx, 5xx) errors.
  AppException _handleBadResponse(DioException err) {
    final int? statusCode = err.response?.statusCode;
    final dynamic responseData = err.response?.data;

    // Try to extract error message from response
    String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ??
          responseData['error'] as String? ??
          message;
    }

    if (statusCode == null) {
      return NetworkException(message: message, statusCode: null);
    }

    // Map status codes to specific exceptions
    if (statusCode >= 400 && statusCode < 500) {
      // Client errors
      switch (statusCode) {
        case 400:
          return ValidationException(
            message: message,
            statusCode: statusCode,
            errors: _extractValidationErrors(responseData),
          );
        case 401:
          return UnauthorizedException(
            message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            statusCode: statusCode,
          );
        case 403:
          return UnauthorizedException(
            message: 'Bạn không có quyền thực hiện thao tác này.',
            statusCode: statusCode,
          );
        case 404:
          return ServerException(
            message: 'Không tìm thấy dữ liệu yêu cầu.',
            statusCode: statusCode,
          );
        case 409:
          return ValidationException(
            message: message,
            statusCode: statusCode,
          );
        case 422:
          return ValidationException(
            message: message,
            statusCode: statusCode,
            errors: _extractValidationErrors(responseData),
          );
        default:
          return ServerException(
            message: message,
            statusCode: statusCode,
          );
      }
    } else if (statusCode >= 500) {
      // Server errors
      return ServerException(
        message: 'Lỗi máy chủ. Vui lòng thử lại sau.',
        statusCode: statusCode,
      );
    }

    return ServerException(message: message, statusCode: statusCode);
  }

  /// Extract validation errors from response data.
  Map<String, List<String>>? _extractValidationErrors(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final dynamic errors = responseData['errors'];
    if (errors is! Map<String, dynamic>) {
      return null;
    }

    // Convert errors map to Map<String, List<String>>
    final Map<String, List<String>> validationErrors = <String, List<String>>{};

    errors.forEach((String key, dynamic value) {
      if (value is List) {
        validationErrors[key] =
            value.map((dynamic e) => e.toString()).toList();
      } else if (value is String) {
        validationErrors[key] = <String>[value];
      }
    });

    return validationErrors.isEmpty ? null : validationErrors;
  }
}
