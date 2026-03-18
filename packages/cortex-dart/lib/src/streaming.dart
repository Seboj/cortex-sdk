/// SSE (Server-Sent Events) stream parsing for the Cortex SDK.
library;

import 'dart:async';
import 'dart:convert';

import 'errors.dart';
import 'types.dart';

/// Parses a raw byte stream from an SSE endpoint into typed chunks.
///
/// Handles the SSE wire format:
/// ```
/// data: {"id":"...","choices":[...]}
///
/// data: [DONE]
/// ```
class SseTransformer
    implements StreamTransformer<List<int>, ChatCompletionChunk> {
  /// Creates an [SseTransformer].
  const SseTransformer();

  @override
  Stream<ChatCompletionChunk> bind(Stream<List<int>> stream) {
    return _parseStream(stream);
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<List<int>, ChatCompletionChunk, RS, RT>(this);

  Stream<ChatCompletionChunk> _parseStream(Stream<List<int>> byteStream) {
    late StreamController<ChatCompletionChunk> controller;
    late StreamSubscription<String> subscription;
    final buffer = StringBuffer();

    controller = StreamController<ChatCompletionChunk>(
      onListen: () {
        subscription = byteStream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            _processLine(line, buffer, controller);
          },
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(
              CortexStreamException(message: 'Stream error: $error'),
              stackTrace,
            );
          },
          onDone: () {
            // Process any remaining data in the buffer.
            final remaining = buffer.toString().trim();
            if (remaining.isNotEmpty) {
              _emitData(remaining, controller);
            }
            controller.close();
          },
          cancelOnError: false,
        );
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }

  void _processLine(
    String line,
    StringBuffer buffer,
    StreamController<ChatCompletionChunk> controller,
  ) {
    // SSE lines starting with "data: " carry the payload.
    if (line.startsWith('data: ')) {
      final data = line.substring(6);
      _emitData(data, controller);
    }
    // Ignore comment lines (starting with ':'), event lines, id lines, etc.
  }

  void _emitData(
    String data,
    StreamController<ChatCompletionChunk> controller,
  ) {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == '[DONE]') return;

    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      final chunk = ChatCompletionChunk.fromJson(json);
      controller.add(chunk);
    } on FormatException catch (e) {
      controller.addError(
        CortexStreamException(message: 'Failed to parse SSE data: $e'),
      );
    }
  }
}

/// Parses a raw byte stream into conversation messages (SSE format).
class ConversationSseTransformer
    implements StreamTransformer<List<int>, ConversationMessage> {
  /// Creates a [ConversationSseTransformer].
  const ConversationSseTransformer();

  @override
  Stream<ConversationMessage> bind(Stream<List<int>> stream) {
    return _parseStream(stream);
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<List<int>, ConversationMessage, RS, RT>(this);

  Stream<ConversationMessage> _parseStream(Stream<List<int>> byteStream) {
    late StreamController<ConversationMessage> controller;
    late StreamSubscription<String> subscription;

    controller = StreamController<ConversationMessage>(
      onListen: () {
        subscription = byteStream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data.isEmpty || data == '[DONE]') return;
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                controller.add(ConversationMessage.fromJson(json));
              } on FormatException catch (e) {
                controller.addError(
                  CortexStreamException(
                      message: 'Failed to parse SSE data: $e'),
                );
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(
              CortexStreamException(message: 'Stream error: $error'),
              stackTrace,
            );
          },
          onDone: () => controller.close(),
          cancelOnError: false,
        );
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }
}
