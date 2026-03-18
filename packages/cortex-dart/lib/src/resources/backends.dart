/// Backends management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to backend management endpoints.
class BackendsResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [BackendsResource].
  BackendsResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all backends.
  Future<List<Backend>> list() async {
    final json = await _client.get('$_baseUrl/admin/backends');
    final data = json['data'] as List<dynamic>? ??
        json['backends'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => Backend.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Backend>[];
  }

  /// Registers a new backend.
  ///
  /// [name] is the backend name.
  /// [url] is the backend URL.
  /// [provider] is the optional provider type.
  Future<Backend> create({
    required String name,
    required String url,
    String? provider,
  }) async {
    if (name.isEmpty) {
      throw const CortexValidationException(
        message: 'Name must not be empty.',
        parameter: 'name',
      );
    }
    if (url.isEmpty) {
      throw const CortexValidationException(
        message: 'URL must not be empty.',
        parameter: 'url',
      );
    }

    final body = <String, dynamic>{'name': name, 'url': url};
    if (provider != null) body['provider'] = provider;

    final json = await _client.post('$_baseUrl/admin/backends', body: body);
    return Backend.fromJson(json);
  }

  /// Updates a backend.
  ///
  /// [id] is the backend identifier.
  /// [name] is the new name (optional).
  /// [url] is the new URL (optional).
  Future<Backend> update({
    required String id,
    String? name,
    String? url,
  }) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (url != null) body['url'] = url;

    final json =
        await _client.patch('$_baseUrl/admin/backends/$id', body: body);
    return Backend.fromJson(json);
  }

  /// Removes a backend.
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/admin/backends/$id');
  }

  /// Discovers models available on a backend.
  Future<Backend> discover(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    final json =
        await _client.post('$_baseUrl/admin/backends/$id/discover');
    return Backend.fromJson(json);
  }

  /// Updates a model's display name on a backend.
  ///
  /// [backendId] is the backend identifier.
  /// [modelId] is the model identifier.
  /// [displayName] is the new display name.
  Future<BackendModel> updateModel({
    required String backendId,
    required String modelId,
    required String displayName,
  }) async {
    if (backendId.isEmpty) {
      throw const CortexValidationException(
        message: 'Backend ID must not be empty.',
        parameter: 'backendId',
      );
    }
    if (modelId.isEmpty) {
      throw const CortexValidationException(
        message: 'Model ID must not be empty.',
        parameter: 'modelId',
      );
    }
    if (displayName.isEmpty) {
      throw const CortexValidationException(
        message: 'Display name must not be empty.',
        parameter: 'displayName',
      );
    }

    final json = await _client.patch(
      '$_baseUrl/admin/backends/$backendId/models/$modelId',
      body: {'displayName': displayName},
    );
    return BackendModel.fromJson(json);
  }
}
