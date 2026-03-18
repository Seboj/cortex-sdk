import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('ChatRole', () {
    test('toJson and fromJson roundtrip', () {
      for (final role in ChatRole.values) {
        final json = role.toJson();
        final parsed = ChatRole.fromJson(json);
        expect(parsed, role);
      }
    });

    test('function_ serializes as "function"', () {
      expect(ChatRole.function_.toJson(), 'function');
      expect(ChatRole.fromJson('function'), ChatRole.function_);
    });

    test('unknown role defaults to user', () {
      expect(ChatRole.fromJson('unknown_role'), ChatRole.user);
    });
  });

  group('ChatMessage', () {
    test('factory constructors', () {
      final system = const ChatMessage.system('You are helpful');
      expect(system.role, ChatRole.system);
      expect(system.content, 'You are helpful');

      final user = const ChatMessage.user('Hello');
      expect(user.role, ChatRole.user);

      final assistant = const ChatMessage.assistant('Hi there');
      expect(assistant.role, ChatRole.assistant);

      final tool = const ChatMessage.tool(
        content: 'result',
        toolCallId: 'call-123',
      );
      expect(tool.role, ChatRole.tool);
      expect(tool.toolCallId, 'call-123');
    });

    test('fromJson and toJson roundtrip', () {
      const msg = ChatMessage(
        role: ChatRole.user,
        content: 'Hello',
        name: 'Alice',
      );
      final json = msg.toJson();
      final restored = ChatMessage.fromJson(json);
      expect(restored.role, ChatRole.user);
      expect(restored.content, 'Hello');
      expect(restored.name, 'Alice');
    });

    test('fromJson with tool calls', () {
      final json = {
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 'call-1',
            'type': 'function',
            'function': {
              'name': 'get_weather',
              'arguments': '{"location":"NYC"}',
            },
          },
        ],
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.toolCalls, hasLength(1));
      expect(msg.toolCalls!.first.function_.name, 'get_weather');
    });

    test('toJson omits null fields', () {
      const msg = ChatMessage.user('Hello');
      final json = msg.toJson();
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('tool_call_id'), isFalse);
      expect(json.containsKey('tool_calls'), isFalse);
    });

    test('equality', () {
      const a = ChatMessage.user('Hello');
      const b = ChatMessage.user('Hello');
      const c = ChatMessage.user('Bye');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ToolCall', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'call-1',
        'type': 'function',
        'function': {
          'name': 'get_weather',
          'arguments': '{"city":"NYC"}',
        },
      };
      final tc = ToolCall.fromJson(json);
      expect(tc.id, 'call-1');
      expect(tc.function_.name, 'get_weather');

      final restored = ToolCall.fromJson(tc.toJson());
      expect(restored, equals(tc));
    });
  });

  group('FunctionCall', () {
    test('roundtrip', () {
      const fc = FunctionCall(name: 'test', arguments: '{}');
      final restored = FunctionCall.fromJson(fc.toJson());
      expect(restored, equals(fc));
    });
  });

  group('ChatCompletion', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'chatcmpl-123',
        'object': 'chat.completion',
        'created': 1677652288,
        'model': 'gpt-4',
        'choices': [
          {
            'index': 0,
            'message': {'role': 'assistant', 'content': 'Hello!'},
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': 9,
          'completion_tokens': 12,
          'total_tokens': 21,
        },
        'system_fingerprint': 'fp_abc123',
      };
      final completion = ChatCompletion.fromJson(json);
      expect(completion.id, 'chatcmpl-123');
      expect(completion.model, 'gpt-4');
      expect(completion.choices, hasLength(1));
      expect(completion.choices.first.message.content, 'Hello!');
      expect(completion.usage!.totalTokens, 21);
      expect(completion.systemFingerprint, 'fp_abc123');
    });

    test('toJson roundtrip', () {
      final json = {
        'id': 'chatcmpl-123',
        'object': 'chat.completion',
        'created': 1677652288,
        'model': 'gpt-4',
        'choices': [
          {
            'index': 0,
            'message': {'role': 'assistant', 'content': 'Hello!'},
            'finish_reason': 'stop',
          },
        ],
      };
      final completion = ChatCompletion.fromJson(json);
      final restored = ChatCompletion.fromJson(completion.toJson());
      expect(restored.id, completion.id);
      expect(restored.model, completion.model);
    });
  });

  group('ChatCompletionChunk', () {
    test('fromJson parses streaming chunk', () {
      final json = {
        'id': 'chatcmpl-123',
        'object': 'chat.completion.chunk',
        'created': 1677652288,
        'model': 'gpt-4',
        'choices': [
          {
            'index': 0,
            'delta': {'role': 'assistant', 'content': 'Hello'},
            'finish_reason': null,
          },
        ],
      };
      final chunk = ChatCompletionChunk.fromJson(json);
      expect(chunk.id, 'chatcmpl-123');
      expect(chunk.choices.first.delta?.content, 'Hello');
      expect(chunk.choices.first.delta?.role, ChatRole.assistant);
      expect(chunk.choices.first.finishReason, isNull);
    });
  });

  group('ChatDelta', () {
    test('fromJson with content only', () {
      final delta = ChatDelta.fromJson({'content': 'Hi'});
      expect(delta.content, 'Hi');
      expect(delta.role, isNull);
    });

    test('fromJson with role only', () {
      final delta = ChatDelta.fromJson({'role': 'assistant'});
      expect(delta.role, ChatRole.assistant);
      expect(delta.content, isNull);
    });

    test('toJson omits null fields', () {
      const delta = ChatDelta(content: 'Hi');
      final json = delta.toJson();
      expect(json.containsKey('role'), isFalse);
      expect(json['content'], 'Hi');
    });
  });

  group('Completion', () {
    test('fromJson', () {
      final json = {
        'id': 'cmpl-123',
        'object': 'text_completion',
        'created': 1677652288,
        'model': 'gpt-3.5',
        'choices': [
          {
            'index': 0,
            'text': 'world!',
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': 5,
          'completion_tokens': 2,
          'total_tokens': 7,
        },
      };
      final completion = Completion.fromJson(json);
      expect(completion.id, 'cmpl-123');
      expect(completion.choices.first.text, 'world!');
    });
  });

  group('EmbeddingResponse', () {
    test('fromJson', () {
      final json = {
        'object': 'list',
        'data': [
          {
            'object': 'embedding',
            'embedding': [0.1, 0.2, 0.3],
            'index': 0,
          },
        ],
        'model': 'text-embedding-ada-002',
        'usage': {
          'prompt_tokens': 5,
          'completion_tokens': 0,
          'total_tokens': 5,
        },
      };
      final response = EmbeddingResponse.fromJson(json);
      expect(response.data, hasLength(1));
      expect(response.data.first.embedding, [0.1, 0.2, 0.3]);
      expect(response.model, 'text-embedding-ada-002');
    });
  });

  group('Usage', () {
    test('fromJson and toJson', () {
      final json = {
        'prompt_tokens': 100,
        'completion_tokens': 50,
        'total_tokens': 150,
      };
      final usage = Usage.fromJson(json);
      expect(usage.promptTokens, 100);
      expect(usage.completionTokens, 50);
      expect(usage.totalTokens, 150);

      final restored = Usage.fromJson(usage.toJson());
      expect(restored, equals(usage));
    });

    test('equality', () {
      const a = Usage(
          promptTokens: 10, completionTokens: 5, totalTokens: 15);
      const b = Usage(
          promptTokens: 10, completionTokens: 5, totalTokens: 15);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Model', () {
    test('fromJson', () {
      final model = Model.fromJson({
        'id': 'gpt-4',
        'object': 'model',
        'created': 1677652288,
        'owned_by': 'openai',
      });
      expect(model.id, 'gpt-4');
      expect(model.ownedBy, 'openai');
    });

    test('equality by id', () {
      final a = Model.fromJson({'id': 'gpt-4', 'object': 'model'});
      final b = Model.fromJson({'id': 'gpt-4', 'object': 'model'});
      expect(a, equals(b));
    });
  });

  group('ModelList', () {
    test('fromJson', () {
      final list = ModelList.fromJson({
        'object': 'list',
        'data': [
          {'id': 'gpt-4', 'object': 'model'},
          {'id': 'gpt-3.5', 'object': 'model'},
        ],
      });
      expect(list.data, hasLength(2));
    });
  });

  group('ApiKey', () {
    test('fromJson handles both camelCase and snake_case', () {
      final camel = ApiKey.fromJson({
        'id': 'key-1',
        'name': 'Test',
        'createdAt': '2024-01-01',
      });
      expect(camel.createdAt, '2024-01-01');

      final snake = ApiKey.fromJson({
        'id': 'key-1',
        'name': 'Test',
        'created_at': '2024-01-01',
      });
      expect(snake.createdAt, '2024-01-01');
    });
  });

  group('Team', () {
    test('fromJson with members', () {
      final team = Team.fromJson({
        'id': 'team-1',
        'name': 'Engineering',
        'members': [
          {'id': 'm-1', 'role': 'admin', 'email': 'alice@example.com'},
        ],
      });
      expect(team.members, hasLength(1));
      expect(team.members!.first.email, 'alice@example.com');
    });
  });

  group('TeamMember', () {
    test('roundtrip', () {
      const member = TeamMember(id: 'm-1', role: 'admin', email: 'a@b.com');
      final restored = TeamMember.fromJson(member.toJson());
      expect(restored.id, 'm-1');
      expect(restored.role, 'admin');
      expect(restored.email, 'a@b.com');
    });
  });

  group('UsageStats', () {
    test('fromJson', () {
      final stats = UsageStats.fromJson({
        'totalRequests': 1000,
        'totalTokens': 50000,
      });
      expect(stats.totalRequests, 1000);
      expect(stats.totalTokens, 50000);
    });
  });

  group('UsageLimits', () {
    test('fromJson', () {
      final limits = UsageLimits.fromJson({
        'requestsPerMinute': 60,
        'tokensPerRequest': 4096,
      });
      expect(limits.requestsPerMinute, 60);
      expect(limits.tokensPerRequest, 4096);
    });
  });

  group('PerformanceMetrics', () {
    test('fromJson', () {
      final metrics = PerformanceMetrics.fromJson({
        'avgLatencyMs': 150.5,
        'successRate': 0.99,
        'totalRequests': 10000,
      });
      expect(metrics.avgLatencyMs, 150.5);
      expect(metrics.successRate, 0.99);
      expect(metrics.totalRequests, 10000);
    });
  });

  group('Conversation', () {
    test('fromJson', () {
      final conv = Conversation.fromJson({
        'id': 'conv-1',
        'title': 'Test',
        'model': 'gpt-4',
        'messageCount': 5,
      });
      expect(conv.id, 'conv-1');
      expect(conv.messageCount, 5);
    });
  });

  group('IrisJob', () {
    test('fromJson', () {
      final job = IrisJob.fromJson({
        'id': 'job-1',
        'status': 'completed',
        'result': {'name': 'John'},
      });
      expect(job.status, 'completed');
      expect(job.result!['name'], 'John');
    });
  });

  group('IrisSchema', () {
    test('fromJson', () {
      final schema = IrisSchema.fromJson({
        'id': 'schema-1',
        'name': 'Invoice',
        'schema': {'type': 'object'},
      });
      expect(schema.name, 'Invoice');
    });
  });

  group('Plugin', () {
    test('fromJson', () {
      final plugin = Plugin.fromJson({
        'id': 'plugin-1',
        'name': 'Search',
        'enabled': true,
      });
      expect(plugin.name, 'Search');
      expect(plugin.enabled, isTrue);
    });
  });

  group('PdfGenerationResult', () {
    test('fromJson', () {
      final result = PdfGenerationResult.fromJson({
        'url': 'https://example.com/doc.pdf',
        'status': 'completed',
      });
      expect(result.url, 'https://example.com/doc.pdf');
      expect(result.status, 'completed');
    });
  });

  group('WebSearchResult', () {
    test('fromJson', () {
      final result = WebSearchResult.fromJson({
        'title': 'Example',
        'url': 'https://example.com',
        'snippet': 'A description',
      });
      expect(result.title, 'Example');
    });
  });

  group('WebSearchResponse', () {
    test('fromJson', () {
      final response = WebSearchResponse.fromJson({
        'results': [
          {'title': 'A', 'url': 'https://a.com'},
          {'title': 'B', 'url': 'https://b.com'},
        ],
        'totalResults': 100,
      });
      expect(response.results, hasLength(2));
      expect(response.totalResults, 100);
    });

    test('handles missing results', () {
      final response = WebSearchResponse.fromJson({});
      expect(response.results, isEmpty);
    });
  });

  group('ResponseFormat', () {
    test('constants', () {
      expect(ResponseFormat.text.type, 'text');
      expect(ResponseFormat.jsonObject.type, 'json_object');
    });

    test('roundtrip', () {
      const rf = ResponseFormat(type: 'json_object');
      final restored = ResponseFormat.fromJson(rf.toJson());
      expect(restored, equals(rf));
    });
  });

  group('ToolDefinition', () {
    test('roundtrip', () {
      final td = ToolDefinition(
        function_: const FunctionDefinition(
          name: 'get_weather',
          description: 'Gets weather',
          parameters: {
            'type': 'object',
            'properties': {
              'city': {'type': 'string'},
            },
          },
        ),
      );
      final restored = ToolDefinition.fromJson(td.toJson());
      expect(restored.function_.name, 'get_weather');
    });
  });

  group('OptimizationSettings', () {
    test('fromJson preserves raw data', () {
      final settings = OptimizationSettings.fromJson({
        'caching': true,
        'compression': 'gzip',
      });
      expect(settings.raw['caching'], isTrue);
    });
  });

  group('CortexConfig', () {
    test('defaults', () {
      const config = CortexConfig(apiKey: 'test');
      expect(config.gatewayBaseUrl, 'https://cortexapi.nfinitmonkeys.com/v1');
      expect(config.adminBaseUrl, 'https://admin.nfinitmonkeys.com');
      expect(config.timeout, const Duration(seconds: 30));
      expect(config.streamingTimeout, const Duration(seconds: 300));
      expect(config.maxRetries, 3);
    });
  });
}
