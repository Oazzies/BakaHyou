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
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// API response exceptions (4xx, 5xx)
class ApiException extends AppException {
  final int statusCode;
  final String? responseBody;

  ApiException({
    required super.message,
    required this.statusCode,
    this.responseBody,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// JSON parsing exceptions
class ParseException extends AppException {
  ParseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Database exceptions
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication cancelled by user
class AuthCancelledException extends AppException {
  AuthCancelledException({
    super.message = 'Login cancelled',
    super.code = 'CANCELLED',
  });
}

/// Generic application exception
class AppError extends AppException {
  AppError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
