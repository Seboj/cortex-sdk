import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('CortexClient', () {
    test('creates client with required apiKey', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );
      expect(client, isNotNull);
      client.close();
    });

    test('throws on empty apiKey', () {
      expect(
        () => CortexClient(apiKey: ''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('throws on apiKey with newlines (header injection prevention)', () {
      expect(
        () => CortexClient(apiKey: 'sk-cortex\ninjected-header: bad'),
        throwsA(isA<CortexValidationException>()),
      );
      expect(
        () => CortexClient(apiKey: 'sk-cortex\rinjected'),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('uses default base URLs', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test',
        httpClient: mockClient(200, {}),
      );
      expect(
        client.config.gatewayBaseUrl,
        'https://cortexapi.nfinitmonkeys.com/v1',
      );
      expect(
        client.config.adminBaseUrl,
        'https://admin.nfinitmonkeys.com',
      );
      client.close();
    });

    test('accepts custom base URLs', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test',
        gatewayBaseUrl: 'https://custom-gateway.example.com/v1',
        adminBaseUrl: 'https://custom-admin.example.com',
        httpClient: mockClient(200, {}),
      );
      expect(
        client.config.gatewayBaseUrl,
        'https://custom-gateway.example.com/v1',
      );
      expect(
        client.config.adminBaseUrl,
        'https://custom-admin.example.com',
      );
      client.close();
    });

    test('normalizes trailing slashes in URLs', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test',
        gatewayBaseUrl: 'https://example.com/v1/',
        adminBaseUrl: 'https://admin.example.com/',
        httpClient: mockClient(200, {}),
      );
      expect(client.config.gatewayBaseUrl, 'https://example.com/v1');
      expect(client.config.adminBaseUrl, 'https://admin.example.com');
      client.close();
    });

    test('creates from CortexConfig', () {
      final config = CortexConfig(
        apiKey: 'sk-cortex-test',
        timeout: const Duration(seconds: 60),
      );
      final client = CortexClient.fromConfig(
        config,
        httpClient: mockClient(200, {}),
      );
      expect(client.config.apiKey, 'sk-cortex-test');
      client.close();
    });

    test('all resource accessors are available', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test',
        httpClient: mockClient(200, {}),
      );
      expect(client.chat, isNotNull);
      expect(client.chat.completions, isNotNull);
      expect(client.completions, isNotNull);
      expect(client.embeddings, isNotNull);
      expect(client.models, isNotNull);
      expect(client.keys, isNotNull);
      expect(client.teams, isNotNull);
      expect(client.usage, isNotNull);
      expect(client.performance, isNotNull);
      expect(client.conversations, isNotNull);
      expect(client.iris, isNotNull);
      expect(client.plugins, isNotNull);
      expect(client.pdf, isNotNull);
      expect(client.webSearch, isNotNull);
      client.close();
    });

    test('toString does not expose full API key', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test-key-very-long-secret',
        httpClient: mockClient(200, {}),
      );
      final str = client.toString();
      expect(str, isNot(contains('sk-cortex-test-key-very-long-secret')));
      expect(str, contains('sk-c'));
      expect(str, contains('cret'));
      client.close();
    });

    test('config masks API key', () {
      final config = CortexConfig(apiKey: 'sk-cortex-test-key-12345678');
      expect(config.maskedApiKey, 'sk-c...5678');
      expect(config.toString(), isNot(contains('sk-cortex-test-key-12345678')));
    });

    test('config masks short API key', () {
      final config = CortexConfig(apiKey: 'short');
      expect(config.maskedApiKey, '***');
    });

    test('custom timeout values', () {
      final client = CortexClient(
        apiKey: 'sk-cortex-test',
        timeout: const Duration(seconds: 60),
        streamingTimeout: const Duration(seconds: 600),
        maxRetries: 5,
        httpClient: mockClient(200, {}),
      );
      expect(client.config.timeout, const Duration(seconds: 60));
      expect(client.config.streamingTimeout, const Duration(seconds: 600));
      expect(client.config.maxRetries, 5);
      client.close();
    });
  });
}
