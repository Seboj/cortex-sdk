import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';


import '../helpers.dart';

void main() {
  group('ConversationsResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('list returns conversations', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {
          'data': [
            sampleConversation(id: 'conv-1', title: 'Chat 1'),
            sampleConversation(id: 'conv-2', title: 'Chat 2'),
          ],
        }),
      );

      final conversations = await client.conversations.list();
      expect(conversations, hasLength(2));
      expect(conversations.first.title, 'Chat 1');
    });

    test('create sends correct body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
            200, sampleConversation(), requests),
      );

      final conv = await client.conversations.create(
        title: 'New Chat',
        model: 'gpt-4',
      );

      expect(conv.id, 'conv-123');
      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['title'], 'New Chat');
      expect(body['model'], 'gpt-4');
    });

    test('get returns conversation by id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, sampleConversation()),
      );

      final conv = await client.conversations.get('conv-123');
      expect(conv.id, 'conv-123');
      expect(conv.title, 'Test Conversation');
    });

    test('get validates empty id', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.conversations.get(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('update sends PATCH request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
            200, sampleConversation(), requests),
      );

      await client.conversations.update(
        'conv-123',
        title: 'Updated Title',
      );

      expect(requests.first.method, 'PATCH');
      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['title'], 'Updated Title');
    });

    test('delete sends DELETE request', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(200, {}, requests),
      );

      await client.conversations.delete('conv-123');
      expect(requests.first.method, 'DELETE');
    });

    test('streamMessages returns message stream', () async {
      const sseBody =
          'data: {"id":"m1","role":"user","content":"Hello"}\n\n'
          'data: {"id":"m2","role":"assistant","content":"Hi!"}\n\n'
          'data: [DONE]\n\n';

      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: StreamingMockClient(sseBody),
      );

      final messages =
          await client.conversations.streamMessages('conv-123').toList();
      expect(messages, hasLength(2));
      expect(messages[0].role, 'user');
      expect(messages[1].content, 'Hi!');
    });

    test('streamMessages validates empty id', () {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.conversations.streamMessages(''),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('handles 404 for missing conversation', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(404, 'Not found'),
      );

      expect(
        () => client.conversations.get('nonexistent'),
        throwsA(isA<CortexNotFoundException>()),
      );
    });
  });
}
