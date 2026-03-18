import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> sampleAdminKey({
  String id = 'admin-key-123',
  String name = 'Admin Key',
}) =>
    {
      'id': id,
      'name': name,
      'key': 'sk-admin-abc123def456',
      'active': true,
      'createdAt': '2024-01-01T00:00:00Z',
    };

void main() {
  group('AdminKeysResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns admin API keys', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleAdminKey(id: 'ak-1', name: 'Key 1'),
            sampleAdminKey(id: 'ak-2', name: 'Key 2'),
          ],
        }),
      );

      final keys = await client.adminKeys.list();
      expect(keys, hasLength(2));
      expect(keys.first.id, 'ak-1');
      expect(keys.last.name, 'Key 2');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final keys = await client.adminKeys.list();
      expect(keys, isEmpty);
    });

    test('create sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleAdminKey(), requests),
      );

      final key = await client.adminKeys.create(name: 'My Admin Key');

      expect(key.id, 'admin-key-123');
      expect(key.key, 'sk-admin-abc123def456');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'My Admin Key');
    });

    test('create validates empty name', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.adminKeys.create(name: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('update sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleAdminKey(), requests),
      );

      final key = await client.adminKeys.update(
        id: 'admin-key-123',
        name: 'Updated Key',
        active: false,
      );

      expect(key.id, 'admin-key-123');
      expect(requests.first.method, 'PATCH');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'Updated Key');
      expect(body['active'], false);
    });

    test('update validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.adminKeys.update(id: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('revoke sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.adminKeys.revoke('admin-key-123');

      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.path,
        contains('/admin/api-keys/admin-key-123'),
      );
    });

    test('revoke validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.adminKeys.revoke(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('regenerate sends POST request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleAdminKey(), requests),
      );

      final key = await client.adminKeys.regenerate('admin-key-123');

      expect(key.id, 'admin-key-123');
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/admin/api-keys/admin-key-123/regenerate'),
      );
    });

    test('regenerate validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.adminKeys.regenerate(''),
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
        () => client.adminKeys.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
