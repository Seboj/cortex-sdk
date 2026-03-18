import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> sampleUser({
  String id = 'user-123',
  String email = 'alice@example.com',
}) =>
    {
      'id': id,
      'email': email,
      'name': 'Alice',
      'role': 'user',
      'status': 'active',
      'createdAt': '2024-01-01T00:00:00Z',
    };

void main() {
  group('UsersResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns users', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleUser(id: 'user-1', email: 'alice@example.com'),
            sampleUser(id: 'user-2', email: 'bob@example.com'),
          ],
        }),
      );

      final users = await client.users.list();
      expect(users, hasLength(2));
      expect(users.first.id, 'user-1');
      expect(users.last.email, 'bob@example.com');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final users = await client.users.list();
      expect(users, isEmpty);
    });

    test('pendingCount returns count', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'count': 5}),
      );

      final result = await client.users.pendingCount();
      expect(result.count, 5);
    });

    test('update sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleUser(), requests),
      );

      final user = await client.users.update(
        id: 'user-123',
        name: 'Updated Name',
        role: 'admin',
      );

      expect(user.id, 'user-123');
      expect(requests.first.method, 'PATCH');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'Updated Name');
      expect(body['role'], 'admin');
    });

    test('update validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.users.update(id: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('delete sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.users.delete('user-123');

      expect(requests.first.method, 'DELETE');
      expect(requests.first.url.path, contains('/admin/users/user-123'));
    });

    test('delete validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.users.delete(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('approve sends POST request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
          200,
          sampleUser()..['status'] = 'active',
          requests,
        ),
      );

      final user = await client.users.approve('user-123');

      expect(user.id, 'user-123');
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/admin/users/user-123/approve'),
      );
    });

    test('approve validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.users.approve(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('reject sends POST request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleUser(), requests),
      );

      final user = await client.users.reject('user-123');

      expect(user.id, 'user-123');
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/admin/users/user-123/reject'),
      );
    });

    test('resetPassword sends POST request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
          200,
          {'temporaryPassword': 'temp-pass-123'},
          requests,
        ),
      );

      final result = await client.users.resetPassword('user-123');

      expect(result['temporaryPassword'], 'temp-pass-123');
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/admin/users/user-123/reset-password'),
      );
    });

    test('resetPassword validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.users.resetPassword(''),
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
        () => client.users.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
