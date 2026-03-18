/// Performance metrics resource.
library;

import '../http_client.dart';
import '../types.dart';

/// Provides access to performance metrics.
class PerformanceResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [PerformanceResource].
  PerformanceResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Gets performance metrics.
  ///
  /// [startDate] and [endDate] optionally filter by date range.
  Future<PerformanceMetrics> getMetrics({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final json = await _client.get(
      '$_baseUrl/api/performance',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return PerformanceMetrics.fromJson(json);
  }
}
