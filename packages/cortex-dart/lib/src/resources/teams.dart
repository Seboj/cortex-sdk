/// Teams management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to team management endpoints.
class TeamsResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [TeamsResource].
  TeamsResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all teams.
  Future<List<Team>> list() async {
    final json = await _client.get('$_baseUrl/api/teams');
    final data =
        json['data'] as List<dynamic>? ?? json['teams'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Team>[];
  }

  /// Creates a new team.
  ///
  /// [name] is the team name.
  /// [description] is an optional description.
  Future<Team> create({
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

    final json = await _client.post('$_baseUrl/api/teams', body: body);
    return Team.fromJson(json);
  }

  /// Gets team details by ID.
  Future<Team> get(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    final json = await _client.get('$_baseUrl/api/teams/$id');
    return Team.fromJson(json);
  }

  /// Deletes a team.
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/api/teams/$id');
  }

  /// Adds a member to a team.
  ///
  /// [teamId] is the team identifier.
  /// [email] is the member's email address.
  /// [role] is the role to assign (e.g., "member", "admin").
  Future<TeamMember> addMember({
    required String teamId,
    required String email,
    required String role,
  }) async {
    if (teamId.isEmpty) {
      throw const CortexValidationException(
        message: 'Team ID must not be empty.',
        parameter: 'teamId',
      );
    }
    if (email.isEmpty) {
      throw const CortexValidationException(
        message: 'Email must not be empty.',
        parameter: 'email',
      );
    }
    if (role.isEmpty) {
      throw const CortexValidationException(
        message: 'Role must not be empty.',
        parameter: 'role',
      );
    }

    final json = await _client.post(
      '$_baseUrl/api/teams/$teamId/members',
      body: {'email': email, 'role': role},
    );
    return TeamMember.fromJson(json);
  }

  /// Updates a team member's role.
  ///
  /// [teamId] is the team identifier.
  /// [memberId] is the member identifier.
  /// [role] is the new role.
  Future<TeamMember> updateMemberRole({
    required String teamId,
    required String memberId,
    required String role,
  }) async {
    if (teamId.isEmpty) {
      throw const CortexValidationException(
        message: 'Team ID must not be empty.',
        parameter: 'teamId',
      );
    }
    if (memberId.isEmpty) {
      throw const CortexValidationException(
        message: 'Member ID must not be empty.',
        parameter: 'memberId',
      );
    }
    if (role.isEmpty) {
      throw const CortexValidationException(
        message: 'Role must not be empty.',
        parameter: 'role',
      );
    }

    final json = await _client.patch(
      '$_baseUrl/api/teams/$teamId/members/$memberId',
      body: {'role': role},
    );
    return TeamMember.fromJson(json);
  }

  /// Removes a member from a team.
  Future<void> removeMember({
    required String teamId,
    required String memberId,
  }) async {
    if (teamId.isEmpty) {
      throw const CortexValidationException(
        message: 'Team ID must not be empty.',
        parameter: 'teamId',
      );
    }
    if (memberId.isEmpty) {
      throw const CortexValidationException(
        message: 'Member ID must not be empty.',
        parameter: 'memberId',
      );
    }
    await _client.delete(
      '$_baseUrl/api/teams/$teamId/members/$memberId',
    );
  }
}
