/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$runtimeType: $message');
    if (code != null) buffer.write(' (Code: $code)');
    if (originalError != null) buffer.write('\nOriginal: $originalError');
    return buffer.toString();
  }
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// API response exceptions (4xx, 5xx)
class ApiException extends AppException {
  final int statusCode;
  final String? responseBody;

  ApiException({
    required String message,
    required this.statusCode,
    this.responseBody,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// JSON parsing exceptions
class ParseException extends AppException {
  ParseException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Database exceptions
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Generic application exception
class AppError extends AppException {
  AppError({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}
