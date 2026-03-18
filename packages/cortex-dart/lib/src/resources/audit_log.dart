/// Audit log resource.
library;

import '../http_client.dart';
import '../types.dart';

/// Provides access to the audit log endpoint.
class AuditLogResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates an [AuditLogResource].
  AuditLogResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Gets audit log entries.
  ///
  /// [limit] optionally limits the number of entries returned.
  Future<List<AuditLogEntry>> list({int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final json = await _client.get(
      '$_baseUrl/admin/audit-log',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = json['data'] as List<dynamic>? ??
        json['entries'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <AuditLogEntry>[];
  }
}
