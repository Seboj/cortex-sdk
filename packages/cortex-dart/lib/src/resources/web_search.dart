/// Web search resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to the web search API.
class WebSearchResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [WebSearchResource].
  WebSearchResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Performs a web search.
  ///
  /// [query] is the search query string.
  /// [limit] optionally limits the number of results.
  Future<WebSearchResponse> search({
    required String query,
    int? limit,
  }) async {
    if (query.isEmpty) {
      throw const CortexValidationException(
        message: 'Query must not be empty.',
        parameter: 'query',
      );
    }

    final body = <String, dynamic>{'query': query};
    if (limit != null) body['limit'] = limit;

    final json = await _client.post(
      '$_baseUrl/api/web/search',
      body: body,
    );
    return WebSearchResponse.fromJson(json);
  }
}
