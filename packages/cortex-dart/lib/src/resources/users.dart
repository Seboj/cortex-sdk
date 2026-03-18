/// Users management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to user management endpoints.
class UsersResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [UsersResource].
  UsersResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all users.
  Future<List<CortexUser>> list() async {
    final json = await _client.get('$_baseUrl/admin/users');
    final data =
        json['data'] as List<dynamic>? ?? json['users'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => CortexUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <CortexUser>[];
  }

  /// Gets the count of users pending approval.
  Future<PendingCount> pendingCount() async {
    final json = await _client.get('$_baseUrl/admin/users/pending-count');
    return PendingCount.fromJson(json);
  }

  /// Updates a user.
  ///
  /// [id] is the user identifier.
  /// [name] is the new name (optional).
  /// [role] is the new role (optional).
  Future<CortexUser> update({
    required String id,
    String? name,
    String? role,
  }) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (role != null) body['role'] = role;

    final json =
        await _client.patch('$_baseUrl/admin/users/$id', body: body);
    return CortexUser.fromJson(json);
  }

  /// Deletes a user.
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/admin/users/$id');
  }

  /// Approves a pending user.
  Future<CortexUser> approve(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    final json =
        await _client.post('$_baseUrl/admin/users/$id/approve');
    return CortexUser.fromJson(json);
  }

  /// Rejects a pending user.
  Future<CortexUser> reject(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    final json =
        await _client.post('$_baseUrl/admin/users/$id/reject');
    return CortexUser.fromJson(json);
  }

  /// Resets a user's password.
  Future<Map<String, dynamic>> resetPassword(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    return _client.post('$_baseUrl/admin/users/$id/reset-password');
  }
}
