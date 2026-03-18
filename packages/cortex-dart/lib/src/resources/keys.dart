/// API keys management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to the API keys management endpoints.
class KeysResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [KeysResource].
  KeysResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all API keys.
  Future<List<ApiKey>> list() async {
    final json = await _client.get('$_baseUrl/api/keys');
    final data = json['data'] as List<dynamic>? ?? json['keys'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => ApiKey.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // If the response is directly a list wrapper.
    return <ApiKey>[];
  }

  /// Creates a new API key.
  ///
  /// [name] is the display name for the key.
  /// [scopes] optionally restricts the key's permissions.
  Future<ApiKey> create({
    required String name,
    List<String>? scopes,
  }) async {
    if (name.isEmpty) {
      throw const CortexValidationException(
        message: 'Name must not be empty.',
        parameter: 'name',
      );
    }

    final body = <String, dynamic>{'name': name};
    if (scopes != null) body['scopes'] = scopes;

    final json = await _client.post('$_baseUrl/api/keys', body: body);
    return ApiKey.fromJson(json);
  }

  /// Revokes (deletes) an API key.
  ///
  /// [id] is the key identifier to revoke.
  Future<void> revoke(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/api/keys/$id');
  }
}
