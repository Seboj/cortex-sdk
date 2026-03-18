/// Audio resource.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../errors.dart';
import '../http_client.dart';
import '../types.dart';

/// Provides access to audio endpoints.
class AudioResource {
  final CortexHttpClient _client;
  final String _baseUrl;
  final String? _defaultPool;

  /// Creates an [AudioResource].
  AudioResource({
    required CortexHttpClient client,
    required String baseUrl,
    String? defaultPool,
  })  : _client = client,
        _baseUrl = baseUrl,
        _defaultPool = defaultPool;

  /// Transcribes an audio file.
  ///
  /// [file] is the audio file bytes.
  /// [fileName] is the file name (e.g., "audio.mp3").
  /// [model] is the transcription model to use. If omitted, the pool's default model is used.
  /// [language] is an optional language hint.
  /// [pool] overrides the client-level default pool for this request.
  Future<AudioTranscription> transcribe({
    required Uint8List file,
    required String fileName,
    String? model,
    String? language,
    String? pool,
  }) async {
    if (fileName.isEmpty) {
      throw const CortexValidationException(
        message: 'File name must not be empty.',
        parameter: 'fileName',
      );
    }
    if (model != null && model.isEmpty) {
      throw const CortexValidationException(
        message: 'Model must not be empty.',
        parameter: 'model',
      );
    }

    // Resolve pool: per-request > client default > none
    final resolvedPool = pool ?? _defaultPool;
    final extraHeaders = <String, String>{};
    if (resolvedPool != null) {
      extraHeaders['x-cortex-pool'] = resolvedPool;
    }

    // For multipart form data, we use the HTTP client's post method
    // with a JSON body that includes the base64-encoded file.
    final json = await _client.post(
      '$_baseUrl/v1/audio/transcriptions',
      body: {
        'file': base64Encode(file),
        'fileName': fileName,
        if (model != null) 'model': model,
        if (language != null) 'language': language,
      },
      extraHeaders: extraHeaders.isNotEmpty ? extraHeaders : null,
    );
    return AudioTranscription.fromJson(json);
  }
}
