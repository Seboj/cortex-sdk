/// Typed exception classes for the Cortex SDK.
library;

/// Base exception for all Cortex SDK errors.
class CortexException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional error code from the API.
  final String? code;

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// Creates a [CortexException].
  const CortexException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => 'CortexException($message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CortexException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(message, code, statusCode);
}

/// Thrown when the API returns an authentication error (401).
class CortexAuthenticationException extends CortexException {
  /// Creates a [CortexAuthenticationException].
  const CortexAuthenticationException({
    String message = 'Authentication failed. Check your API key.',
    String? code,
  }) : super(message: message, code: code, statusCode: 401);

  @override
  String toString() => 'CortexAuthenticationException($message)';
}

/// Thrown when the API returns a forbidden error (403).
class CortexForbiddenException extends CortexException {
  /// Creates a [CortexForbiddenException].
  const CortexForbiddenException({
    String message = 'Access denied. Insufficient permissions.',
    String? code,
  }) : super(message: message, code: code, statusCode: 403);

  @override
  String toString() => 'CortexForbiddenException($message)';
}

/// Thrown when the API returns a not found error (404).
class CortexNotFoundException extends CortexException {
  /// Creates a [CortexNotFoundException].
  const CortexNotFoundException({
    String message = 'Resource not found.',
    String? code,
  }) : super(message: message, code: code, statusCode: 404);

  @override
  String toString() => 'CortexNotFoundException($message)';
}

/// Thrown when the API returns a rate limit error (429).
class CortexRateLimitException extends CortexException {
  /// The number of seconds to wait before retrying, if provided.
  final Duration? retryAfter;

  /// Creates a [CortexRateLimitException].
  const CortexRateLimitException({
    String message = 'Rate limit exceeded.',
    String? code,
    this.retryAfter,
  }) : super(message: message, code: code, statusCode: 429);

  @override
  String toString() => 'CortexRateLimitException($message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CortexRateLimitException &&
          super == other &&
          retryAfter == other.retryAfter;

  @override
  int get hashCode => Object.hash(super.hashCode, retryAfter);
}

/// Thrown when the API returns a server error (5xx).
class CortexServerException extends CortexException {
  /// Creates a [CortexServerException].
  const CortexServerException({
    String message = 'Server error.',
    String? code,
    int? statusCode,
  }) : super(message: message, code: code, statusCode: statusCode ?? 500);

  @override
  String toString() => 'CortexServerException($message)';
}

/// Thrown when input validation fails before making a request.
class CortexValidationException extends CortexException {
  /// The parameter that failed validation.
  final String parameter;

  /// Creates a [CortexValidationException].
  const CortexValidationException({
    required String message,
    required this.parameter,
  }) : super(message: message);

  @override
  String toString() => 'CortexValidationException($parameter: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CortexValidationException &&
          super == other &&
          parameter == other.parameter;

  @override
  int get hashCode => Object.hash(super.hashCode, parameter);
}

/// Thrown when a request times out.
class CortexTimeoutException extends CortexException {
  /// Creates a [CortexTimeoutException].
  const CortexTimeoutException({
    String message = 'Request timed out.',
  }) : super(message: message);

  @override
  String toString() => 'CortexTimeoutException($message)';
}

/// Thrown when a network/connection error occurs.
class CortexConnectionException extends CortexException {
  /// Creates a [CortexConnectionException].
  const CortexConnectionException({
    String message = 'Connection failed.',
  }) : super(message: message);

  @override
  String toString() => 'CortexConnectionException($message)';
}

/// Thrown when SSE stream parsing fails.
class CortexStreamException extends CortexException {
  /// Creates a [CortexStreamException].
  const CortexStreamException({
    String message = 'Stream parsing error.',
  }) : super(message: message);

  @override
  String toString() => 'CortexStreamException($message)';
}

/// Maps an HTTP status code and optional body to a typed exception.
CortexException exceptionFromStatusCode(
  int statusCode,
  String body, {
  Duration? retryAfter,
}) {
  final message = body.isNotEmpty ? body : 'HTTP $statusCode';

  switch (statusCode) {
    case 401:
      return CortexAuthenticationException(message: message);
    case 403:
      return CortexForbiddenException(message: message);
    case 404:
      return CortexNotFoundException(message: message);
    case 429:
      return CortexRateLimitException(
        message: message,
        retryAfter: retryAfter,
      );
    default:
      if (statusCode >= 500) {
        return CortexServerException(
          message: message,
          statusCode: statusCode,
        );
      }
      return CortexException(
        message: message,
        statusCode: statusCode,
      );
  }
}
