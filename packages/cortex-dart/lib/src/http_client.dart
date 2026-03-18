/// Internal HTTP wrapper with retry logic and error handling.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'errors.dart';
import 'types.dart';

/// Internal HTTP client that handles authentication, retries, and error mapping.
class CortexHttpClient {
  final CortexConfig _config;
  final http.Client _httpClient;
  final Random _random = Random();

  /// Creates a [CortexHttpClient].
  CortexHttpClient({
    required CortexConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  /// Sends a GET request and returns the decoded JSON body.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParameters,
    Duration? timeout,
  }) async {
    final uri = _buildUri(url, queryParameters);
    _validateUrl(uri);
    return _withRetry(() async {
      final response = await _httpClient
          .get(uri, headers: _headers())
          .timeout(timeout ?? _config.timeout);
      return _handleResponse(response);
    });
  }

  /// Sends a GET request and returns the decoded JSON body as a list.
  Future<List<dynamic>> getList(
    String url, {
    Map<String, String>? queryParameters,
    Duration? timeout,
  }) async {
    final uri = _buildUri(url, queryParameters);
    _validateUrl(uri);
    return _withRetry(() async {
      final response = await _httpClient
          .get(uri, headers: _headers())
          .timeout(timeout ?? _config.timeout);
      return _handleListResponse(response);
    });
  }

  /// Sends a POST request and returns the decoded JSON body.
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Duration? timeout,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse(url);
    _validateUrl(uri);
    return _withRetry(() async {
      final headers = _headers(contentType: 'application/json');
      if (extraHeaders != null) headers.addAll(extraHeaders);
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _config.timeout);
      return _handleResponse(response);
    });
  }

  /// Sends a PATCH request and returns the decoded JSON body.
  Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(url);
    _validateUrl(uri);
    return _withRetry(() async {
      final response = await _httpClient
          .patch(
            uri,
            headers: _headers(contentType: 'application/json'),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _config.timeout);
      return _handleResponse(response);
    });
  }

  /// Sends a PUT request and returns the decoded JSON body.
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(url);
    _validateUrl(uri);
    return _withRetry(() async {
      final response = await _httpClient
          .put(
            uri,
            headers: _headers(contentType: 'application/json'),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _config.timeout);
      return _handleResponse(response);
    });
  }

  /// Sends a DELETE request and returns the decoded JSON body.
  Future<Map<String, dynamic>> delete(
    String url, {
    Duration? timeout,
  }) async {
    final uri = Uri.parse(url);
    _validateUrl(uri);
    return _withRetry(() async {
      final response = await _httpClient
          .delete(uri, headers: _headers())
          .timeout(timeout ?? _config.timeout);
      return _handleResponse(response);
    });
  }

  /// Sends a POST request and returns the raw streamed response.
  Future<http.StreamedResponse> postStream(
    String url, {
    Map<String, dynamic>? body,
    Duration? timeout,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse(url);
    _validateUrl(uri);

    final request = http.Request('POST', uri);
    request.headers.addAll(_headers(contentType: 'application/json'));
    if (extraHeaders != null) request.headers.addAll(extraHeaders);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response = await _httpClient
        .send(request)
        .timeout(timeout ?? _config.streamingTimeout);

    if (response.statusCode >= 400) {
      final responseBody = await response.stream.bytesToString();
      throw exceptionFromStatusCode(response.statusCode, responseBody);
    }

    return response;
  }

  /// Sends a GET request and returns the raw streamed response (for SSE).
  Future<http.StreamedResponse> getStream(
    String url, {
    Map<String, String>? queryParameters,
    Duration? timeout,
  }) async {
    final uri = _buildUri(url, queryParameters);
    _validateUrl(uri);

    final request = http.Request('GET', uri);
    request.headers.addAll(_headers());

    final response = await _httpClient
        .send(request)
        .timeout(timeout ?? _config.streamingTimeout);

    if (response.statusCode >= 400) {
      final responseBody = await response.stream.bytesToString();
      throw exceptionFromStatusCode(response.statusCode, responseBody);
    }

    return response;
  }

  /// Closes the underlying HTTP client.
  void close() {
    _httpClient.close();
  }

  // ---- Private helpers ----

  Map<String, String> _headers({String? contentType}) {
    final headers = <String, String>{
      'Authorization': 'Bearer ${_config.apiKey}',
      'User-Agent': userAgent,
      'Accept': 'application/json',
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    return headers;
  }

  Uri _buildUri(String url, Map<String, String>? queryParameters) {
    final uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      });
    }
    return uri;
  }

  void _validateUrl(Uri uri) {
    // Enforce HTTPS in production (allow http for localhost/testing).
    if (uri.scheme != 'https' &&
        uri.host != 'localhost' &&
        uri.host != '127.0.0.1') {
      throw const CortexValidationException(
        message: 'HTTPS is required for all API requests.',
        parameter: 'url',
      );
    }

    // Header injection prevention: check for newlines in the URL.
    final urlString = uri.toString();
    if (urlString.contains('\n') || urlString.contains('\r')) {
      throw const CortexValidationException(
        message: 'URL contains invalid characters (potential header injection).',
        parameter: 'url',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      _throwForStatus(response);
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Wrap non-map responses.
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      return <String, dynamic>{'data': response.body};
    }
  }

  List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 400) {
      _throwForStatus(response);
    }
    if (response.body.isEmpty) return <dynamic>[];
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) return decoded;
      return <dynamic>[decoded];
    } on FormatException {
      return <dynamic>[];
    }
  }

  Never _throwForStatus(http.Response response) {
    Duration? retryAfter;
    final retryAfterHeader = response.headers['retry-after'];
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader);
      if (seconds != null) {
        retryAfter = Duration(seconds: seconds);
      }
    }
    throw exceptionFromStatusCode(
      response.statusCode,
      response.body,
      retryAfter: retryAfter,
    );
  }

  /// Executes [fn] with retry logic for transient errors.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    var attempt = 0;
    while (true) {
      try {
        return await fn();
      } on CortexException catch (e) {
        attempt++;
        if (!_shouldRetry(e, attempt)) rethrow;
        final delay = _calculateDelay(attempt, e);
        await Future<void>.delayed(delay);
      } on TimeoutException {
        attempt++;
        if (attempt > _config.maxRetries) {
          throw const CortexTimeoutException();
        }
        final delay = _calculateDelay(attempt, null);
        await Future<void>.delayed(delay);
      }
    }
  }

  bool _shouldRetry(CortexException e, int attempt) {
    if (attempt > _config.maxRetries) return false;
    if (e.statusCode == null) return false;
    return retryableStatusCodes.contains(e.statusCode);
  }

  Duration _calculateDelay(int attempt, CortexException? exception) {
    // Respect Retry-After header for rate limit errors.
    if (exception is CortexRateLimitException &&
        exception.retryAfter != null) {
      return exception.retryAfter!;
    }

    // Exponential backoff with jitter.
    final baseMs = _config.retryBaseDelay.inMilliseconds;
    final maxMs = _config.retryMaxDelay.inMilliseconds;
    final exponentialMs = baseMs * pow(2, attempt - 1).toInt();
    final cappedMs = min(exponentialMs, maxMs);
    // Add jitter: random between 0 and cappedMs.
    final jitterMs = _random.nextInt(cappedMs + 1);
    return Duration(milliseconds: (cappedMs + jitterMs) ~/ 2);
  }
}
