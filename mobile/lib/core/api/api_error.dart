/// Base class for all API-related exceptions.
///
/// All custom exceptions thrown by the API client should extend this class.
abstract class AppException implements Exception {
  /// Creates an app exception.
  const AppException({
    required this.message,
    this.statusCode,
  });

  /// Human-readable error message (Vietnamese).
  final String message;

  /// HTTP status code if applicable.
  final int? statusCode;

  @override
  String toString() {
    if (statusCode != null) {
      return '$runtimeType(statusCode: $statusCode, message: $message)';
    }
    return '$runtimeType(message: $message)';
  }
}

/// Network-related exceptions (timeouts, connection errors).
class NetworkException extends AppException {
  /// Creates a network exception.
  const NetworkException({
    required super.message,
    super.statusCode,
  });
}

/// Server-side errors (5xx, 404, etc.).
class ServerException extends AppException {
  /// Creates a server exception.
  const ServerException({
    required super.message,
    super.statusCode,
  });
}

/// Authentication/authorization errors (401, 403).
class UnauthorizedException extends AppException {
  /// Creates an unauthorized exception.
  const UnauthorizedException({
    required super.message,
    super.statusCode,
  });
}

/// Validation errors (400, 422) with field-specific error messages.
class ValidationException extends AppException {
  /// Creates a validation exception.
  const ValidationException({
    required super.message,
    super.statusCode,
    this.errors,
  });

  /// Field-specific validation errors.
  ///
  /// Maps field names to lists of error messages.
  /// Example: {'email': ['Email không hợp lệ'], 'password': ['Mật khẩu quá ngắn']}
  final Map<String, List<String>>? errors;

  /// Get error message for a specific field.
  String? getFieldError(String field) {
    final List<String>? fieldErrors = errors?[field];
    return fieldErrors != null && fieldErrors.isNotEmpty
        ? fieldErrors.first
        : null;
  }

  /// Check if a specific field has errors.
  bool hasFieldError(String field) {
    return errors?.containsKey(field) ?? false;
  }

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return '$runtimeType(statusCode: $statusCode, message: $message, errors: $errors)';
    }
    return super.toString();
  }
}
