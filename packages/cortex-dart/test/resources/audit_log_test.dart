import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> sampleAuditEntry({
  String id = 'audit-123',
  String action = 'user.login',
}) =>
    {
      'id': id,
      'action': action,
      'userId': 'user-1',
      'resourceType': 'user',
      'resourceId': 'user-1',
      'details': {'ip': '127.0.0.1'},
      'createdAt': '2024-01-01T00:00:00Z',
    };

void main() {
  group('AuditLogResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns audit log entries', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleAuditEntry(id: 'a-1', action: 'user.login'),
            sampleAuditEntry(id: 'a-2', action: 'key.create'),
          ],
        }),
      );

      final entries = await client.auditLog.list();
      expect(entries, hasLength(2));
      expect(entries.first.id, 'a-1');
      expect(entries.first.action, 'user.login');
      expect(entries.last.action, 'key.create');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final entries = await client.auditLog.list();
      expect(entries, isEmpty);
    });

    test('list sends limit query parameter', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'data': [sampleAuditEntry()],
        }, requests),
      );

      await client.auditLog.list(limit: 10);

      expect(requests.first.url.queryParameters['limit'], '10');
    });

    test('list works without limit', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {
          'data': [sampleAuditEntry()],
        }, requests),
      );

      await client.auditLog.list();

      expect(requests.first.url.queryParameters.containsKey('limit'), false);
    });

    test('parses entry details', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [sampleAuditEntry()],
        }),
      );

      final entries = await client.auditLog.list();
      expect(entries.first.details, isNotNull);
      expect(entries.first.details!['ip'], '127.0.0.1');
      expect(entries.first.userId, 'user-1');
      expect(entries.first.resourceType, 'user');
    });

    test('handles 401 errors', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(401, 'Unauthorized'),
      );

      expect(
        () => client.auditLog.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
