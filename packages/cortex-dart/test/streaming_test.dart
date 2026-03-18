import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:test/test.dart';

/// Helper to create a [Stream<List<int>>] from encoded bytes,
/// avoiding the Uint8List/List<int> variance issue.
Stream<List<int>> _byteStream(String text) {
  final bytes = utf8.encode(text);
  return Stream<List<int>>.value(bytes);
}

void main() {
  group('SseTransformer', () {
    test('parses simple SSE stream', () async {
      final chunks = <ChatCompletionChunk>[];
      final data = _buildSseData([
        _chunk('chatcmpl-1', 'Hello', role: 'assistant'),
        _chunk('chatcmpl-1', ' world'),
        _chunk('chatcmpl-1', '!', finishReason: 'stop'),
      ]);

      await _byteStream(data)
          .transform(const SseTransformer())
          .forEach(chunks.add);

      expect(chunks, hasLength(3));
      expect(chunks[0].choices.first.delta?.content, 'Hello');
      expect(chunks[0].choices.first.delta?.role, ChatRole.assistant);
      expect(chunks[1].choices.first.delta?.content, ' world');
      expect(chunks[2].choices.first.delta?.content, '!');
      expect(chunks[2].choices.first.finishReason, 'stop');
    });

    test('handles [DONE] marker', () async {
      final chunks = <ChatCompletionChunk>[];
      const data = 'data: {"id":"c1","object":"chat.completion.chunk",'
          '"created":1,"model":"m","choices":[{"index":0,'
          '"delta":{"content":"Hi"},"finish_reason":null}]}\n\n'
          'data: [DONE]\n\n';

      final byteStream = _byteStream(data);
      await byteStream
          .transform(const SseTransformer())
          .forEach(chunks.add);

      expect(chunks, hasLength(1));
      expect(chunks.first.choices.first.delta?.content, 'Hi');
    });

    test('ignores comment lines', () async {
      final chunks = <ChatCompletionChunk>[];
      const data = ': this is a comment\n'
          'data: {"id":"c1","object":"chat.completion.chunk",'
          '"created":1,"model":"m","choices":[{"index":0,'
          '"delta":{"content":"Hi"},"finish_reason":null}]}\n\n';

      final byteStream = _byteStream(data);
      await byteStream
          .transform(const SseTransformer())
          .forEach(chunks.add);

      expect(chunks, hasLength(1));
    });

    test('ignores empty lines', () async {
      final chunks = <ChatCompletionChunk>[];
      const data = '\n\n'
          'data: {"id":"c1","object":"chat.completion.chunk",'
          '"created":1,"model":"m","choices":[{"index":0,'
          '"delta":{"content":"Hi"},"finish_reason":null}]}\n\n'
          '\n\n';

      final byteStream = _byteStream(data);
      await byteStream
          .transform(const SseTransformer())
          .forEach(chunks.add);

      expect(chunks, hasLength(1));
    });

    test('handles malformed JSON with error', () async {
      final chunks = <ChatCompletionChunk>[];
      final errors = <Object>[];
      const data = 'data: {invalid json}\n\n';

      final byteStream = _byteStream(data);
      final completer = Completer<void>();
      byteStream.transform(const SseTransformer()).listen(
        chunks.add,
        onError: (Object e) => errors.add(e),
        onDone: () => completer.complete(),
        cancelOnError: false,
      );
      await completer.future;

      expect(chunks, isEmpty);
      expect(errors, hasLength(1));
      expect(errors.first, isA<CortexStreamException>());
    });

    test('supports pause and resume', () async {
      final chunks = <ChatCompletionChunk>[];
      final data = _buildSseData([
        _chunk('c1', 'a'),
        _chunk('c1', 'b'),
        _chunk('c1', 'c'),
      ]);

      final byteStream = _byteStream(data);
      final stream = byteStream.transform(const SseTransformer());

      final completer = Completer<void>();
      late StreamSubscription<ChatCompletionChunk> sub;
      sub = stream.listen((chunk) {
        chunks.add(chunk);
        if (chunks.length == 1) {
          sub.pause();
          // Resume after a tick.
          Future<void>.delayed(Duration.zero).then((_) => sub.resume());
        }
      }, onDone: () => completer.complete());

      await completer.future;
      expect(chunks, hasLength(3));
    });

    test('handles multi-chunk byte delivery', () async {
      final chunks = <ChatCompletionChunk>[];
      final line1 = 'data: ${jsonEncode(_chunk('c1', 'Hello'))}\n\n';
      final line2 = 'data: ${jsonEncode(_chunk('c1', ' world'))}\n\n';
      final line3 = 'data: [DONE]\n\n';

      // Deliver bytes in separate chunks.
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode(line1));
      controller.add(utf8.encode(line2));
      controller.add(utf8.encode(line3));
      controller.close();

      await controller.stream
          .transform(const SseTransformer())
          .forEach(chunks.add);

      expect(chunks, hasLength(2));
    });
  });

  group('ConversationSseTransformer', () {
    test('parses conversation messages', () async {
      final messages = <ConversationMessage>[];
      const data = 'data: {"id":"m1","role":"user","content":"Hello"}\n\n'
          'data: {"id":"m2","role":"assistant","content":"Hi!"}\n\n'
          'data: [DONE]\n\n';

      final byteStream = _byteStream(data);
      await byteStream
          .transform(const ConversationSseTransformer())
          .forEach(messages.add);

      expect(messages, hasLength(2));
      expect(messages[0].role, 'user');
      expect(messages[1].content, 'Hi!');
    });
  });
}

Map<String, dynamic> _chunk(String id, String content,
    {String? role, String? finishReason}) {
  return {
    'id': id,
    'object': 'chat.completion.chunk',
    'created': 1677652288,
    'model': 'gpt-4',
    'choices': [
      {
        'index': 0,
        'delta': {
          if (role != null) 'role': role,
          'content': content,
        },
        'finish_reason': finishReason,
      },
    ],
  };
}

String _buildSseData(List<Map<String, dynamic>> chunks) {
  final buffer = StringBuffer();
  for (final chunk in chunks) {
    buffer.writeln('data: ${jsonEncode(chunk)}');
    buffer.writeln();
  }
  buffer.writeln('data: [DONE]');
  buffer.writeln();
  return buffer.toString();
}
