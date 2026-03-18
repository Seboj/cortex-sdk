/// Usage limits management resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to usage limit management endpoints.
class UsageLimitsResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [UsageLimitsResource].
  UsageLimitsResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all usage limits.
  Future<List<UsageLimit>> list() async {
    final json = await _client.get('$_baseUrl/admin/usage-limits');
    final data = json['data'] as List<dynamic>? ??
        json['limits'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => UsageLimit.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <UsageLimit>[];
  }

  /// Sets usage limits for a user.
  ///
  /// [userId] is the user identifier.
  /// [requestsPerMinute] is the rate limit (optional).
  /// [tokensPerRequest] is the per-request token limit (optional).
  /// [monthlyTokenBudget] is the monthly budget (optional).
  Future<UsageLimit> setUserLimits({
    required String userId,
    int? requestsPerMinute,
    int? tokensPerRequest,
    int? monthlyTokenBudget,
  }) async {
    if (userId.isEmpty) {
      throw const CortexValidationException(
        message: 'User ID must not be empty.',
        parameter: 'userId',
      );
    }

    final body = <String, dynamic>{};
    if (requestsPerMinute != null) {
      body['requestsPerMinute'] = requestsPerMinute;
    }
    if (tokensPerRequest != null) {
      body['tokensPerRequest'] = tokensPerRequest;
    }
    if (monthlyTokenBudget != null) {
      body['monthlyTokenBudget'] = monthlyTokenBudget;
    }

    final json = await _client.put(
      '$_baseUrl/admin/usage-limits/user/$userId',
      body: body,
    );
    return UsageLimit.fromJson(json);
  }

  /// Removes usage limits for a user.
  Future<void> removeUserLimits(String userId) async {
    if (userId.isEmpty) {
      throw const CortexValidationException(
        message: 'User ID must not be empty.',
        parameter: 'userId',
      );
    }
    await _client.delete('$_baseUrl/admin/usage-limits/user/$userId');
  }

  /// Removes usage limits for a team.
  Future<void> removeTeamLimits(String teamId) async {
    if (teamId.isEmpty) {
      throw const CortexValidationException(
        message: 'Team ID must not be empty.',
        parameter: 'teamId',
      );
    }
    await _client.delete('$_baseUrl/admin/usage-limits/team/$teamId');
  }
}
