import 'dart:convert';
import 'dart:typed_data';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('x-cortex-pool header', () {
    group('ChatCompletionsResource', () {
      test('sends x-cortex-pool header when pool is specified per-request',
          () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient:
              recordingMockClient(200, sampleChatCompletion(), requests),
        );

        await client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          pool: 'cortexvlm',
        );

        expect(requests.first.headers['x-cortex-pool'], 'cortexvlm');
        client.close();
      });

      test('sends x-cortex-pool header from client defaultPool', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          defaultPool: 'cortex-stt',
          httpClient:
              recordingMockClient(200, sampleChatCompletion(), requests),
        );

        await client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
        );

        expect(requests.first.headers['x-cortex-pool'], 'cortex-stt');
        client.close();
      });

      test('per-request pool overrides client defaultPool', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          defaultPool: 'default',
          httpClient:
              recordingMockClient(200, sampleChatCompletion(), requests),
        );

        await client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          pool: 'cortexvlm',
        );

        expect(requests.first.headers['x-cortex-pool'], 'cortexvlm');
        client.close();
      });

      test('no x-cortex-pool header when neither pool nor defaultPool set',
          () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient:
              recordingMockClient(200, sampleChatCompletion(), requests),
        );

        await client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
        );

        expect(requests.first.headers['x-cortex-pool'], isNull);
        client.close();
      });
    });

    group('model is optional', () {
      test('chat.completions.create works without model', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          defaultPool: 'cortexvlm',
          httpClient:
              recordingMockClient(200, sampleChatCompletion(), requests),
        );

        await client.chat.completions.create(
          messages: [const ChatMessage.user('Hello')],
        );

        final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
        expect(body.containsKey('model'), isFalse);
        expect(requests.first.headers['x-cortex-pool'], 'cortexvlm');
        client.close();
      });

      test('completions.create works without model', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient: recordingMockClient(200, {
            'id': 'cmpl-123',
            'object': 'text_completion',
            'created': 1677652288,
            'model': 'gpt-4',
            'choices': [
              {'index': 0, 'text': 'World', 'finish_reason': 'stop'}
            ],
          }, requests),
        );

        await client.completions.create(
          prompt: 'Hello',
          pool: 'default',
        );

        final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
        expect(body.containsKey('model'), isFalse);
        expect(requests.first.headers['x-cortex-pool'], 'default');
        client.close();
      });

      test('embeddings.create works without model', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient: recordingMockClient(200, {
            'object': 'list',
            'data': [
              {'object': 'embedding', 'embedding': [0.1, 0.2], 'index': 0}
            ],
            'model': 'text-embedding-ada-002',
          }, requests),
        );

        await client.embeddings.create(
          input: 'Hello',
          pool: 'default',
        );

        final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
        expect(body.containsKey('model'), isFalse);
        expect(requests.first.headers['x-cortex-pool'], 'default');
        client.close();
      });
    });

    group('CompletionsResource pool header', () {
      test('sends x-cortex-pool when pool specified', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient: recordingMockClient(200, {
            'id': 'cmpl-123',
            'object': 'text_completion',
            'created': 1677652288,
            'model': 'gpt-4',
            'choices': [
              {'index': 0, 'text': 'World', 'finish_reason': 'stop'}
            ],
          }, requests),
        );

        await client.completions.create(
          model: 'gpt-4',
          prompt: 'Hello',
          pool: 'cortex-stt',
        );

        expect(requests.first.headers['x-cortex-pool'], 'cortex-stt');
        client.close();
      });
    });

    group('EmbeddingsResource pool header', () {
      test('sends x-cortex-pool when pool specified', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient: recordingMockClient(200, {
            'object': 'list',
            'data': [
              {'object': 'embedding', 'embedding': [0.1, 0.2], 'index': 0}
            ],
            'model': 'text-embedding-ada-002',
          }, requests),
        );

        await client.embeddings.create(
          model: 'text-embedding-ada-002',
          input: 'Hello',
          pool: 'cortexvlm',
        );

        expect(requests.first.headers['x-cortex-pool'], 'cortexvlm');
        client.close();
      });
    });

    group('AudioResource pool header', () {
      test('sends x-cortex-pool when pool specified', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          httpClient: recordingMockClient(200, {
            'text': 'Hello world!',
          }, requests),
        );

        await client.audio.transcribe(
          file: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.mp3',
          model: 'whisper-1',
          pool: 'cortex-stt-diarize',
        );

        expect(
            requests.first.headers['x-cortex-pool'], 'cortex-stt-diarize');
        client.close();
      });

      test('audio.transcribe works without model', () async {
        final requests = <http.Request>[];
        final client = CortexClient(
          apiKey: 'sk-cortex-test-key-1234',
          defaultPool: 'cortex-stt',
          httpClient: recordingMockClient(200, {
            'text': 'Hello world!',
          }, requests),
        );

        await client.audio.transcribe(
          file: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.mp3',
        );

        final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
        expect(body.containsKey('model'), isFalse);
        expect(requests.first.headers['x-cortex-pool'], 'cortex-stt');
        client.close();
      });
    });
  });
}
