/// Embeddings resource.
library;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to the embeddings API.
class EmbeddingsResource {
  final CortexHttpClient _client;
  final String _baseUrl;
  final String? _defaultPool;

  /// Creates an [EmbeddingsResource].
  EmbeddingsResource({
    required CortexHttpClient client,
    required String baseUrl,
    String? defaultPool,
  })  : _client = client,
        _baseUrl = baseUrl,
        _defaultPool = defaultPool;

  /// Generates embeddings for the given input.
  ///
  /// [model] is the embedding model to use. If omitted, the pool's default model is used.
  /// [input] is a single string or list of strings to embed.
  /// [encodingFormat] optionally specifies the encoding format.
  /// [pool] overrides the client-level default pool for this request.
  Future<EmbeddingResponse> create({
    String? model,
    required dynamic input,
    String? encodingFormat,
    String? pool,
  }) async {
    if (model != null && model.isEmpty) {
      throw const CortexValidationException(
        message: 'Model must not be empty.',
        parameter: 'model',
      );
    }
    if (input is String && input.isEmpty) {
      throw const CortexValidationException(
        message: 'Input must not be empty.',
        parameter: 'input',
      );
    }
    if (input is List && input.isEmpty) {
      throw const CortexValidationException(
        message: 'Input list must not be empty.',
        parameter: 'input',
      );
    }

    final request = EmbeddingRequest(
      model: model,
      input: input,
      encodingFormat: encodingFormat,
    );

    // Resolve pool: per-request > client default > none
    final resolvedPool = pool ?? _defaultPool;
    final extraHeaders = <String, String>{};
    if (resolvedPool != null) {
      extraHeaders['x-cortex-pool'] = resolvedPool;
    }

    final json = await _client.post(
      '$_baseUrl/embeddings',
      body: request.toJson(),
      extraHeaders: extraHeaders.isNotEmpty ? extraHeaders : null,
    );
    return EmbeddingResponse.fromJson(json);
  }
}
