/// Usage statistics and limits resource.
library;

import '../http_client.dart';
import '../types.dart';

/// Provides access to usage statistics and rate limit endpoints.
class UsageResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [UsageResource].
  UsageResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Gets usage statistics.
  ///
  /// [startDate] and [endDate] optionally filter by date range.
  Future<UsageStats> getStats({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final json = await _client.get(
      '$_baseUrl/api/usage',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return UsageStats.fromJson(json);
  }

  /// Gets rate and usage limits.
  Future<UsageLimits> getLimits() async {
    final json = await _client.get('$_baseUrl/api/usage/limits');
    return UsageLimits.fromJson(json);
  }
}
