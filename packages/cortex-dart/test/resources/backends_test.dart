import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> sampleBackend({
  String id = 'backend-123',
  String name = 'OpenAI Backend',
}) =>
    {
      'id': id,
      'name': name,
      'url': 'https://api.openai.com',
      'status': 'active',
      'provider': 'openai',
      'models': [
        {'id': 'gpt-4', 'displayName': 'GPT-4'},
      ],
      'createdAt': '2024-01-01T00:00:00Z',
    };

void main() {
  group('BackendsResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns backends', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleBackend(id: 'b-1', name: 'Backend A'),
            sampleBackend(id: 'b-2', name: 'Backend B'),
          ],
        }),
      );

      final backends = await client.backends.list();
      expect(backends, hasLength(2));
      expect(backends.first.id, 'b-1');
      expect(backends.last.name, 'Backend B');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final backends = await client.backends.list();
      expect(backends, isEmpty);
    });

    test('create sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleBackend(), requests),
      );

      final backend = await client.backends.create(
        name: 'New Backend',
        url: 'https://api.example.com',
        provider: 'custom',
      );

      expect(backend.id, 'backend-123');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'New Backend');
      expect(body['url'], 'https://api.example.com');
      expect(body['provider'], 'custom');
    });

    test('create validates empty name', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.backends.create(name: '', url: 'https://example.com'),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create validates empty url', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.backends.create(name: 'Test', url: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('update sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleBackend(), requests),
      );

      final backend = await client.backends.update(
        id: 'backend-123',
        name: 'Updated Backend',
      );

      expect(backend.id, 'backend-123');
      expect(requests.first.method, 'PATCH');
    });

    test('update validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.backends.update(id: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('delete sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.backends.delete('backend-123');

      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.path,
        contains('/admin/backends/backend-123'),
      );
    });

    test('discover sends POST request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleBackend(), requests),
      );

      final backend = await client.backends.discover('backend-123');

      expect(backend.id, 'backend-123');
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/admin/backends/backend-123/discover'),
      );
    });

    test('discover validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.backends.discover(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('updateModel sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'id': 'gpt-4',
          'displayName': 'GPT-4 Turbo',
        }, requests),
      );

      final model = await client.backends.updateModel(
        backendId: 'backend-123',
        modelId: 'gpt-4',
        displayName: 'GPT-4 Turbo',
      );

      expect(model.id, 'gpt-4');
      expect(model.displayName, 'GPT-4 Turbo');
      expect(requests.first.method, 'PATCH');
      expect(
        requests.first.url.path,
        contains('/admin/backends/backend-123/models/gpt-4'),
      );
    });

    test('updateModel validates empty backendId', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.backends.updateModel(
          backendId: '',
          modelId: 'gpt-4',
          displayName: 'GPT-4',
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('updateModel validates empty displayName', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.backends.updateModel(
          backendId: 'b-1',
          modelId: 'gpt-4',
          displayName: '',
        ),
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
        () => client.backends.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
