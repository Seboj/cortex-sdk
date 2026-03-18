/// Text completions resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to the text completions API.
class CompletionsResource {
  final CortexHttpClient _client;
  final String _baseUrl;
  final String? _defaultPool;

  /// Creates a [CompletionsResource].
  CompletionsResource({
    required CortexHttpClient client,
    required String baseUrl,
    String? defaultPool,
  })  : _client = client,
        _baseUrl = baseUrl,
        _defaultPool = defaultPool;

  /// Creates a text completion.
  ///
  /// [model] is the model identifier. If omitted, the pool's default model is used.
  /// [prompt] is the text to complete.
  /// [pool] overrides the client-level default pool for this request.
  Future<Completion> create({
    String? model,
    required String prompt,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? n,
    List<String>? stop,
    double? presencePenalty,
    double? frequencyPenalty,
    String? user,
    String? pool,
  }) async {
    if (model != null && model.isEmpty) {
      throw const CortexValidationException(
        message: 'Model must not be empty.',
        parameter: 'model',
      );
    }
    if (prompt.isEmpty) {
      throw const CortexValidationException(
        message: 'Prompt must not be empty.',
        parameter: 'prompt',
      );
    }

    final request = CompletionRequest(
      model: model,
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      n: n,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      user: user,
    );

    // Resolve pool: per-request > client default > none
    final resolvedPool = pool ?? _defaultPool;
    final extraHeaders = <String, String>{};
    if (resolvedPool != null) {
      extraHeaders['x-cortex-pool'] = resolvedPool;
    }

    final json = await _client.post(
      '$_baseUrl/completions',
      body: request.toJson(),
      extraHeaders: extraHeaders.isNotEmpty ? extraHeaders : null,
    );
    return Completion.fromJson(json);
  }
}
