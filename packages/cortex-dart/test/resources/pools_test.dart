import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> samplePool({
  String id = 'pool-123',
  String name = 'Default Pool',
}) =>
    {
      'id': id,
      'name': name,
      'description': 'A test pool',
      'backends': ['backend-1', 'backend-2'],
      'createdAt': '2024-01-01T00:00:00Z',
    };

void main() {
  group('PoolsResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns pools', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            samplePool(id: 'pool-1', name: 'Pool A'),
            samplePool(id: 'pool-2', name: 'Pool B'),
          ],
        }),
      );

      final pools = await client.pools.list();
      expect(pools, hasLength(2));
      expect(pools.first.id, 'pool-1');
      expect(pools.last.name, 'Pool B');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final pools = await client.pools.list();
      expect(pools, isEmpty);
    });

    test('create sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, samplePool(), requests),
      );

      final pool = await client.pools.create(
        name: 'My Pool',
        description: 'A new pool',
      );

      expect(pool.id, 'pool-123');
      expect(pool.name, 'Default Pool');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'My Pool');
      expect(body['description'], 'A new pool');
    });

    test('create validates empty name', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.pools.create(name: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('update sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, samplePool(), requests),
      );

      final pool = await client.pools.update(
        id: 'pool-123',
        name: 'Updated Pool',
      );

      expect(pool.id, 'pool-123');
      expect(requests.first.method, 'PATCH');
      expect(requests.first.url.path, contains('/admin/pools/pool-123'));
    });

    test('update validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.pools.update(id: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('delete sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.pools.delete('pool-123');

      expect(requests.first.method, 'DELETE');
      expect(requests.first.url.path, contains('/admin/pools/pool-123'));
    });

    test('delete validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.pools.delete(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('addBackend sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {'ok': true}, requests),
      );

      await client.pools.addBackend(
        poolId: 'pool-123',
        backendId: 'backend-456',
      );

      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/admin/pools/pool-123/backends'),
      );
      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['backendId'], 'backend-456');
    });

    test('addBackend validates empty poolId', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.pools.addBackend(poolId: '', backendId: 'b-1'),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('removeBackend sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.pools.removeBackend(
        poolId: 'pool-123',
        backendId: 'backend-456',
      );

      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.path,
        contains('/admin/pools/pool-123/backends/backend-456'),
      );
    });

    test('handles 401 errors', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(401, 'Unauthorized'),
      );

      expect(
        () => client.pools.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
