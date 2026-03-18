/// Shared test helpers and mock HTTP client.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Creates a mock HTTP client that returns a fixed JSON response.
MockClient mockClient(
  int statusCode,
  dynamic body, {
  Map<String, String>? headers,
}) {
  return MockClient((request) async {
    return http.Response(
      body is String ? body : jsonEncode(body),
      statusCode,
      headers: {
        'content-type': 'application/json',
        ...?headers,
      },
    );
  });
}

/// Creates a mock HTTP client that records requests and returns a response.
MockClient recordingMockClient(
  int statusCode,
  dynamic body,
  List<http.Request> requests,
) {
  return MockClient((request) async {
    requests.add(request as http.Request);
    return http.Response(
      body is String ? body : jsonEncode(body),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  });
}

/// Creates a mock HTTP client that returns different responses
/// based on the request count.
MockClient sequentialMockClient(List<http.Response> responses) {
  var index = 0;
  return MockClient((request) async {
    if (index < responses.length) {
      return responses[index++];
    }
    return responses.last;
  });
}

/// A sample chat completion JSON response.
Map<String, dynamic> sampleChatCompletion({
  String id = 'chatcmpl-123',
  String model = 'gpt-4',
  String content = 'Hello! How can I help you?',
  String finishReason = 'stop',
}) =>
    {
      'id': id,
      'object': 'chat.completion',
      'created': 1677652288,
      'model': model,
      'choices': [
        {
          'index': 0,
          'message': {
            'role': 'assistant',
            'content': content,
          },
          'finish_reason': finishReason,
        }
      ],
      'usage': {
        'prompt_tokens': 9,
        'completion_tokens': 12,
        'total_tokens': 21,
      },
    };

/// A sample SSE stream body for chat completion chunks.
String sampleSseStream({
  String id = 'chatcmpl-123',
  String model = 'gpt-4',
  List<String> contentChunks = const ['Hello', '!', ' How', ' can', ' I help?'],
}) {
  final buffer = StringBuffer();
  for (var i = 0; i < contentChunks.length; i++) {
    final chunk = {
      'id': id,
      'object': 'chat.completion.chunk',
      'created': 1677652288,
      'model': model,
      'choices': [
        {
          'index': 0,
          'delta': {
            if (i == 0) 'role': 'assistant',
            'content': contentChunks[i],
          },
          'finish_reason': i == contentChunks.length - 1 ? 'stop' : null,
        }
      ],
    };
    buffer.writeln('data: ${jsonEncode(chunk)}');
    buffer.writeln();
  }
  buffer.writeln('data: [DONE]');
  buffer.writeln();
  return buffer.toString();
}

/// A sample model list JSON response.
Map<String, dynamic> sampleModelList() => {
      'object': 'list',
      'data': [
        {
          'id': 'gpt-4',
          'object': 'model',
          'created': 1677652288,
          'owned_by': 'openai',
        },
        {
          'id': 'gpt-3.5-turbo',
          'object': 'model',
          'created': 1677652288,
          'owned_by': 'openai',
        },
      ],
    };

/// Sample API key response.
Map<String, dynamic> sampleApiKey({
  String id = 'key-123',
  String name = 'Test Key',
}) =>
    {
      'id': id,
      'name': name,
      'key': 'sk-cortex-abc123def456',
      'createdAt': '2024-01-01T00:00:00Z',
      'active': true,
    };

/// Sample team response.
Map<String, dynamic> sampleTeam({
  String id = 'team-123',
  String name = 'Engineering',
}) =>
    {
      'id': id,
      'name': name,
      'description': 'The engineering team',
      'createdAt': '2024-01-01T00:00:00Z',
      'members': [
        {
          'id': 'member-1',
          'email': 'alice@example.com',
          'name': 'Alice',
          'role': 'admin',
        },
      ],
    };

/// Sample usage stats response.
Map<String, dynamic> sampleUsageStats() => {
      'totalRequests': 1000,
      'totalTokens': 50000,
      'promptTokens': 30000,
      'completionTokens': 20000,
      'periodStart': '2024-01-01T00:00:00Z',
      'periodEnd': '2024-01-31T23:59:59Z',
    };

/// Sample conversation response.
Map<String, dynamic> sampleConversation({
  String id = 'conv-123',
  String title = 'Test Conversation',
}) =>
    {
      'id': id,
      'title': title,
      'model': 'gpt-4',
      'createdAt': '2024-01-01T00:00:00Z',
      'messageCount': 5,
    };

/// Sample Iris job response.
Map<String, dynamic> sampleIrisJob({
  String id = 'job-123',
  String status = 'completed',
}) =>
    {
      'id': id,
      'status': status,
      'result': {'name': 'John Doe', 'email': 'john@example.com'},
      'createdAt': '2024-01-01T00:00:00Z',
    };

/// A mock HTTP client that returns streamed responses.
///
/// Use this for testing SSE/streaming endpoints.
class StreamingMockClient extends http.BaseClient {
  final String _body;
  final int _statusCode;

  /// Creates a [StreamingMockClient] that returns [body] as a streamed
  /// response with the given [statusCode].
  StreamingMockClient(this._body, {int statusCode = 200})
      : _statusCode = statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final controller = StreamController<List<int>>();
    final response = http.StreamedResponse(
      controller.stream,
      _statusCode,
      headers: {'content-type': 'text/event-stream'},
      request: request,
    );
    // Add body bytes asynchronously.
    scheduleMicrotask(() {
      controller.add(utf8.encode(_body));
      controller.close();
    });
    return response;
  }
}
