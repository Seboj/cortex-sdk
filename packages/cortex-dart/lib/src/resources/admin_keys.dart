/// Admin API keys management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to admin API key management endpoints.
class AdminKeysResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates an [AdminKeysResource].
  AdminKeysResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all admin API keys.
  Future<List<AdminApiKey>> list() async {
    final json = await _client.get('$_baseUrl/admin/api-keys');
    final data =
        json['data'] as List<dynamic>? ?? json['keys'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => AdminApiKey.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <AdminApiKey>[];
  }

  /// Creates a new admin API key.
  ///
  /// [name] is the display name for the key.
  Future<AdminApiKey> create({
    required String name,
  }) async {
    if (name.isEmpty) {
      throw const CortexValidationException(
        message: 'Name must not be empty.',
        parameter: 'name',
      );
    }

    final json = await _client.post(
      '$_baseUrl/admin/api-keys',
      body: {'name': name},
    );
    return AdminApiKey.fromJson(json);
  }

  /// Updates an admin API key.
  ///
  /// [id] is the key identifier.
  /// [name] is the new name (optional).
  /// [active] is the new active status (optional).
  Future<AdminApiKey> update({
    required String id,
    String? name,
    bool? active,
  }) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (active != null) body['active'] = active;

    final json =
        await _client.patch('$_baseUrl/admin/api-keys/$id', body: body);
    return AdminApiKey.fromJson(json);
  }

  /// Revokes (deletes) an admin API key.
  Future<void> revoke(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/admin/api-keys/$id');
  }

  /// Regenerates an admin API key.
  Future<AdminApiKey> regenerate(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    final json =
        await _client.post('$_baseUrl/admin/api-keys/$id/regenerate');
    return AdminApiKey.fromJson(json);
  }
}
