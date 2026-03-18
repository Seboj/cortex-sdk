import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('KeysResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns API keys', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleApiKey(id: 'key-1', name: 'Key 1'),
            sampleApiKey(id: 'key-2', name: 'Key 2'),
          ],
        }),
      );

      final keys = await client.keys.list();
      expect(keys, hasLength(2));
      expect(keys.first.id, 'key-1');
      expect(keys.last.name, 'Key 2');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final keys = await client.keys.list();
      expect(keys, isEmpty);
    });

    test('create sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleApiKey(), requests),
      );

      final key = await client.keys.create(
        name: 'My New Key',
        scopes: ['chat', 'embeddings'],
      );

      expect(key.id, 'key-123');
      expect(key.key, 'sk-cortex-abc123def456');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'My New Key');
      expect(body['scopes'], ['chat', 'embeddings']);
    });

    test('create validates empty name', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.keys.create(name: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('revoke sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.keys.revoke('key-123');

      expect(requests.first.method, 'DELETE');
      expect(requests.first.url.path, contains('/api/keys/key-123'));
    });

    test('revoke validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.keys.revoke(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('handles 401 errors', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(401, 'Unauthorized'),
      );

      expect(
        () => client.keys.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
