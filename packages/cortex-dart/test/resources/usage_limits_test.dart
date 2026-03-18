import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

Map<String, dynamic> sampleUsageLimit({
  String id = 'limit-123',
  String? userId = 'user-1',
}) =>
    {
      'id': id,
      'userId': userId,
      'requestsPerMinute': 60,
      'tokensPerRequest': 4096,
      'monthlyTokenBudget': 1000000,
    };

void main() {
  group('UsageLimitsResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns usage limits', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleUsageLimit(id: 'limit-1'),
            sampleUsageLimit(id: 'limit-2'),
          ],
        }),
      );

      final limits = await client.usageLimits.list();
      expect(limits, hasLength(2));
      expect(limits.first.id, 'limit-1');
    });

    test('list handles empty response', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {'data': <dynamic>[]}),
      );

      final limits = await client.usageLimits.list();
      expect(limits, isEmpty);
    });

    test('setUserLimits sends PUT request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleUsageLimit(), requests),
      );

      final limit = await client.usageLimits.setUserLimits(
        userId: 'user-1',
        requestsPerMinute: 60,
        tokensPerRequest: 4096,
        monthlyTokenBudget: 1000000,
      );

      expect(limit.requestsPerMinute, 60);
      expect(requests.first.method, 'PUT');
      expect(
        requests.first.url.path,
        contains('/admin/usage-limits/user/user-1'),
      );

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['requestsPerMinute'], 60);
      expect(body['tokensPerRequest'], 4096);
      expect(body['monthlyTokenBudget'], 1000000);
    });

    test('setUserLimits validates empty userId', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.usageLimits.setUserLimits(userId: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('removeUserLimits sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.usageLimits.removeUserLimits('user-1');

      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.path,
        contains('/admin/usage-limits/user/user-1'),
      );
    });

    test('removeUserLimits validates empty userId', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.usageLimits.removeUserLimits(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('removeTeamLimits sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.usageLimits.removeTeamLimits('team-1');

      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.path,
        contains('/admin/usage-limits/team/team-1'),
      );
    });

    test('removeTeamLimits validates empty teamId', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.usageLimits.removeTeamLimits(''),
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
        () => client.usageLimits.list(),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });
  });
}
