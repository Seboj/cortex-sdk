import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('IrisResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('extract sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, sampleIrisJob(), requests),
      );

      final job = await client.iris.extract({
        'document': 'base64data...',
        'schema_id': 'invoice-v1',
      });

      expect(job.id, 'job-123');
      expect(job.status, 'completed');
      expect(job.result!['name'], 'John Doe');

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['schema_id'], 'invoice-v1');
    });

    test('extract validates empty data', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.iris.extract({}),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('listJobs returns jobs', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleIrisJob(id: 'job-1'),
            sampleIrisJob(id: 'job-2', status: 'processing'),
          ],
        }),
      );

      final jobs = await client.iris.listJobs();
      expect(jobs, hasLength(2));
      expect(jobs.last.status, 'processing');
    });

    test('listJobs passes limit parameter', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {'data': <dynamic>[]}, requests),
      );

      await client.iris.listJobs(limit: 10);

      final uri = requests.first.url;
      expect(uri.queryParameters['limit'], '10');
    });

    test('listSchemas returns schemas', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            {
              'id': 'schema-1',
              'name': 'Invoice',
              'schema': {'type': 'object'},
            },
          ],
        }),
      );

      final schemas = await client.iris.listSchemas();
      expect(schemas, hasLength(1));
      expect(schemas.first.name, 'Invoice');
    });
  });
}
