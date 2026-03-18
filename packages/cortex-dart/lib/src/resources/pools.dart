/// Pools management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to pool management endpoints.
class PoolsResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [PoolsResource].
  PoolsResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all pools.
  Future<List<Pool>> list() async {
    final json = await _client.get('$_baseUrl/admin/pools');
    final data =
        json['data'] as List<dynamic>? ?? json['pools'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => Pool.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Pool>[];
  }

  /// Creates a new pool.
  ///
  /// [name] is the pool name.
  /// [description] is an optional description.
  Future<Pool> create({
    required String name,
    String? description,
  }) async {
    if (name.isEmpty) {
      throw const CortexValidationException(
        message: 'Name must not be empty.',
        parameter: 'name',
      );
    }

    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;

    final json = await _client.post('$_baseUrl/admin/pools', body: body);
    return Pool.fromJson(json);
  }

  /// Updates a pool.
  ///
  /// [id] is the pool identifier.
  /// [name] is the new name (optional).
  /// [description] is the new description (optional).
  Future<Pool> update({
    required String id,
    String? name,
    String? description,
  }) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final json =
        await _client.patch('$_baseUrl/admin/pools/$id', body: body);
    return Pool.fromJson(json);
  }

  /// Deletes a pool.
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/admin/pools/$id');
  }

  /// Adds a backend to a pool.
  ///
  /// [poolId] is the pool identifier.
  /// [backendId] is the backend identifier to add.
  Future<Map<String, dynamic>> addBackend({
    required String poolId,
    required String backendId,
  }) async {
    if (poolId.isEmpty) {
      throw const CortexValidationException(
        message: 'Pool ID must not be empty.',
        parameter: 'poolId',
      );
    }
    if (backendId.isEmpty) {
      throw const CortexValidationException(
        message: 'Backend ID must not be empty.',
        parameter: 'backendId',
      );
    }

    return _client.post(
      '$_baseUrl/admin/pools/$poolId/backends',
      body: {'backendId': backendId},
    );
  }

  /// Removes a backend from a pool.
  Future<void> removeBackend({
    required String poolId,
    required String backendId,
  }) async {
    if (poolId.isEmpty) {
      throw const CortexValidationException(
        message: 'Pool ID must not be empty.',
        parameter: 'poolId',
      );
    }
    if (backendId.isEmpty) {
      throw const CortexValidationException(
        message: 'Backend ID must not be empty.',
        parameter: 'backendId',
      );
    }
    await _client.delete(
      '$_baseUrl/admin/pools/$poolId/backends/$backendId',
    );
  }
}
