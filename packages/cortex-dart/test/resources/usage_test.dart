import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('UsageResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('getStats returns usage statistics', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, sampleUsageStats()),
      );

      final stats = await client.usage.getStats();
      expect(stats.totalRequests, 1000);
      expect(stats.totalTokens, 50000);
      expect(stats.promptTokens, 30000);
      expect(stats.completionTokens, 20000);
    });

    test('getStats passes date parameters', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleUsageStats(), requests),
      );

      await client.usage.getStats(
        startDate: '2024-01-01',
        endDate: '2024-01-31',
      );

      final uri = requests.first.url;
      expect(uri.queryParameters['start_date'], '2024-01-01');
      expect(uri.queryParameters['end_date'], '2024-01-31');
    });

    test('getLimits returns usage limits', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'requestsPerMinute': 60,
          'tokensPerRequest': 4096,
          'monthlyTokenBudget': 1000000,
          'tokensUsedThisMonth': 250000,
        }),
      );

      final limits = await client.usage.getLimits();
      expect(limits.requestsPerMinute, 60);
      expect(limits.tokensPerRequest, 4096);
      expect(limits.monthlyTokenBudget, 1000000);
      expect(limits.tokensUsedThisMonth, 250000);
    });
  });

  group('PerformanceResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('getMetrics returns performance metrics', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'avgLatencyMs': 150.5,
          'p95LatencyMs': 300.0,
          'p99LatencyMs': 500.0,
          'successRate': 0.995,
          'totalRequests': 10000,
          'errorRate': 0.005,
        }),
      );

      final metrics = await client.performance.getMetrics();
      expect(metrics.avgLatencyMs, 150.5);
      expect(metrics.p95LatencyMs, 300.0);
      expect(metrics.successRate, 0.995);
      expect(metrics.errorRate, 0.005);
    });
  });
}
