import 'dart:convert';
import 'dart:typed_data';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('AudioResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('transcribe sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'text': 'Hello, this is a transcription.',
        }, requests),
      );

      final fileBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

      final result = await client.audio.transcribe(
        file: fileBytes,
        fileName: 'audio.mp3',
        model: 'whisper-1',
        language: 'en',
      );

      expect(result.text, 'Hello, this is a transcription.');
      expect(requests.first.method, 'POST');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['fileName'], 'audio.mp3');
      expect(body['model'], 'whisper-1');
      expect(body['language'], 'en');
      expect(body['file'], base64Encode(fileBytes));
    });

    test('transcribe validates empty fileName', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.audio.transcribe(
          file: Uint8List(0),
          fileName: '',
          model: 'whisper-1',
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('transcribe validates empty model', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.audio.transcribe(
          file: Uint8List(0),
          fileName: 'audio.mp3',
          model: '',
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('transcribe without language omits field', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'text': 'Transcription result.',
        }, requests),
      );

      await client.audio.transcribe(
        file: Uint8List.fromList([0x00]),
        fileName: 'audio.wav',
        model: 'whisper-1',
      );

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body.containsKey('language'), false);
    });

    test('handles 401 errors', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(401, 'Unauthorized'),
      );

      expect(
        () => client.audio.transcribe(
          file: Uint8List(1),
          fileName: 'audio.mp3',
          model: 'whisper-1',
        ),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
