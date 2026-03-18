import 'dart:convert';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  group('ChatCompletionsResource', () {
    late CortexClient client;

    tearDown(() => client.close());

    test('create returns ChatCompletion', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, sampleChatCompletion()),
      );

      final response = await client.chat.completions.create(
        model: 'gpt-4',
        messages: [const ChatMessage.user('Hello')],
      );

      expect(response.id, 'chatcmpl-123');
      expect(response.model, 'gpt-4');
      expect(response.choices.first.message.content,
          'Hello! How can I help you?');
      expect(response.usage!.totalTokens, 21);
    });

    test('create sends correct request body', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
            200, sampleChatCompletion(), requests),
      );

      await client.chat.completions.create(
        model: 'gpt-4',
        messages: [
          const ChatMessage.system('You are helpful'),
          const ChatMessage.user('Hello'),
        ],
        temperature: 0.7,
        maxTokens: 100,
      );

      expect(requests, hasLength(1));
      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['model'], 'gpt-4');
      expect(body['temperature'], 0.7);
      expect(body['max_tokens'], 100);
      expect(body['stream'], false);
      expect((body['messages'] as List).length, 2);
    });

    test('create sends Authorization header', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
            200, sampleChatCompletion(), requests),
      );

      await client.chat.completions.create(
        model: 'gpt-4',
        messages: [const ChatMessage.user('Hello')],
      );

      expect(
        requests.first.headers['Authorization'],
        'Bearer sk-cortex-test-key-1234',
      );
    });

    test('create validates empty model', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.create(
          model: '',
          messages: [const ChatMessage.user('Hello')],
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create validates empty messages', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [],
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create validates temperature range', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          temperature: 3.0,
        ),
        throwsA(isA<CortexValidationException>()),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          temperature: -1.0,
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create validates topP range', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          topP: 1.5,
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create validates presencePenalty range', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          presencePenalty: 3.0,
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create validates frequencyPenalty range', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
          frequencyPenalty: -3.0,
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });

    test('create with tools', () async {
      final requests = <http.Request>[];
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: recordingMockClient(
            200, sampleChatCompletion(), requests),
      );

      await client.chat.completions.create(
        model: 'gpt-4',
        messages: [const ChatMessage.user('What is the weather?')],
        tools: [
          ToolDefinition(
            function_: const FunctionDefinition(
              name: 'get_weather',
              description: 'Get weather for a city',
              parameters: {
                'type': 'object',
                'properties': {
                  'city': {'type': 'string'},
                },
              },
            ),
          ),
        ],
      );

      final body = jsonDecode(requests.first.body) as Map<String, dynamic>;
      expect(body['tools'], hasLength(1));
    });

    test('create handles 401 error', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(401, {'error': 'Invalid API key'}),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
        ),
        throwsA(isA<CortexAuthenticationException>()),
      );
    });

    test('create handles 429 error', () async {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        maxRetries: 0,
        httpClient: mockClient(429, 'Rate limited'),
      );

      expect(
        () => client.chat.completions.create(
          model: 'gpt-4',
          messages: [const ChatMessage.user('Hello')],
        ),
        throwsA(isA<CortexRateLimitException>()),
      );
    });

    test('createStream returns Stream of chunks', () async {
      final sseBody = sampleSseStream(
        contentChunks: ['Hello', ' world', '!'],
      );

      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: StreamingMockClient(sseBody),
      );

      final chunks = await client.chat.completions
          .createStream(
            model: 'gpt-4',
            messages: [const ChatMessage.user('Hello')],
          )
          .toList();

      expect(chunks, hasLength(3));
      expect(chunks[0].choices.first.delta?.content, 'Hello');
      expect(chunks[1].choices.first.delta?.content, ' world');
      expect(chunks[2].choices.first.delta?.content, '!');
    });

    test('createStream validates parameters', () {
      client = CortexClient(
        apiKey: 'sk-cortex-test-key-1234',
        httpClient: mockClient(200, {}),
      );

      expect(
        () => client.chat.completions.createStream(
          model: '',
          messages: [const ChatMessage.user('Hello')],
        ),
        throwsA(isA<CortexValidationException>()),
      );
    });
  });
}
