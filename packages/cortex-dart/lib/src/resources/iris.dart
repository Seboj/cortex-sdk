/// Iris data extraction resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to Iris structured data extraction endpoints.
class IrisResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates an [IrisResource].
  IrisResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Extracts structured data from documents.
  ///
  /// [data] contains the extraction request parameters (document content,
  /// schema ID, etc.).
  Future<IrisJob> extract(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      throw const CortexValidationException(
        message: 'Data must not be empty.',
        parameter: 'data',
      );
    }

    final json = await _client.post(
      '$_baseUrl/api/iris/extract',
      body: data,
    );
    return IrisJob.fromJson(json);
  }

  /// Lists extraction jobs.
  ///
  /// [limit] optionally limits the number of jobs returned.
  Future<List<IrisJob>> listJobs({int? limit}) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();

    final json = await _client.get(
      '$_baseUrl/api/iris/jobs',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data =
        json['data'] as List<dynamic>? ?? json['jobs'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => IrisJob.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <IrisJob>[];
  }

  /// Lists extraction schemas.
  Future<List<IrisSchema>> listSchemas() async {
    final json = await _client.get('$_baseUrl/api/iris/schemas');
    final data = json['data'] as List<dynamic>? ??
        json['schemas'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => IrisSchema.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <IrisSchema>[];
  }
}
