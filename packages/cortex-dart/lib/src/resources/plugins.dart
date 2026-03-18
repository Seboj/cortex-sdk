/// Plugins resource.
library;

import '../http_client.dart';
import '../types.dart';

/// Provides access to the plugins API.
class PluginsResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [PluginsResource].
  PluginsResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all available plugins.
  Future<List<Plugin>> list() async {
    final json = await _client.get('$_baseUrl/api/plugins');
    final data = json['data'] as List<dynamic>? ??
        json['plugins'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => Plugin.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Plugin>[];
  }
}
