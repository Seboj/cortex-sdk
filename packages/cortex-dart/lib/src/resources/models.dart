/// Models resource for listing available LLM models.
library;

import '../http_client.dart';
import '../types.dart';

/// Provides access to the models API.
class ModelsResource {
  final CortexHttpClient _client;
  final String _gatewayBaseUrl;
  final String _adminBaseUrl;

  /// Creates a [ModelsResource].
  ModelsResource({
    required CortexHttpClient client,
    required String gatewayBaseUrl,
    required String adminBaseUrl,
  })  : _client = client,
        _gatewayBaseUrl = gatewayBaseUrl,
        _adminBaseUrl = adminBaseUrl;

  /// Lists available models from the LLM Gateway.
  ///
  /// Returns a [ModelList] containing all models available for use.
  Future<ModelList> list() async {
    final json = await _client.get('$_gatewayBaseUrl/models');
    return ModelList.fromJson(json);
  }

  /// Lists models configuration from the admin API.
  ///
  /// Returns the raw configuration data.
  Future<Map<String, dynamic>> configuration() async {
    return _client.get('$_adminBaseUrl/api/models');
  }
}
