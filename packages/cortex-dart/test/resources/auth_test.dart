import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> sampleAuthToken() => {
      'token': 'jwt-token-abc123',
      'user': {
        'id': 'user-123',
        'email': 'alice@example.com',
        'name': 'Alice',
        'role': 'admin',
      },
    };

Map<String, dynamic> sampleAuthUser() => {
      'id': 'user-123',
      'email': 'alice@example.com',
      'name': 'Alice',
      'role': 'admin',
    };

void main() {
  group('AuthResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('login sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleAuthToken(), requests),
      );

      final result = await client.auth.login(
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(result.token, 'jwt-token-abc123');
      expect(result.user?.email, 'alice@example.com');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['email'], 'alice@example.com');
      expect(body['password'], 'password123');
    });

    test('login validates empty email', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.auth.login(email: '', password: 'pass'),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('login validates empty password', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.auth.login(email: 'a@b.com', password: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('signup sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleAuthToken(), requests),
      );

      final result = await client.auth.signup(
        email: 'alice@example.com',
        password: 'password123',
        name: 'Alice',
      );

      expect(result.token, 'jwt-token-abc123');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['email'], 'alice@example.com');
      expect(body['password'], 'password123');
      expect(body['name'], 'Alice');
    });

    test('signup validates empty email', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.auth.signup(email: '', password: 'pass'),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('signup validates empty password', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.auth.signup(email: 'a@b.com', password: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('me returns current user', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, sampleAuthUser()),
      );

      final user = await client.auth.me();
      expect(user.id, 'user-123');
      expect(user.email, 'alice@example.com');
      expect(user.name, 'Alice');
      expect(user.role, 'admin');
    });

    test('updateProfile sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleAuthUser(), requests),
      );

      final user = await client.auth.updateProfile(name: 'Alice Updated');

      expect(user.id, 'user-123');
      expect(requests.first.method, 'PATCH');
      expect(requests.first.url.path, contains('/auth/me'));

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['name'], 'Alice Updated');
    });

    test('changePassword sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {'ok': true}, requests),
      );

      await client.auth.changePassword(
        currentPassword: 'old-pass',
        newPassword: 'new-pass',
      );

      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        contains('/auth/change-password'),
      );

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['currentPassword'], 'old-pass');
      expect(body['newPassword'], 'new-pass');
    });

    test('changePassword validates empty currentPassword', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.auth.changePassword(
          currentPassword: '',
          newPassword: 'new',
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('changePassword validates empty newPassword', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.auth.changePassword(
          currentPassword: 'old',
          newPassword: '',
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
        () => client.auth.me(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
