/// Chat completions resource.
library;

import 'dart:async';

import '../errors.dart';
import '../http_client.dart';
import '../streaming.dart';
import '../types.dart';

/// Provides access to the chat completions API.
///
/// Usage:
/// ```dart
/// final response = await cortex.chat.completions.create(
///   model: 'default',
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
class ChatResource {
  /// The completions sub-resource.
  final ChatCompletionsResource completions;

  /// Creates a [ChatResource].
  ChatResource({
    required CortexHttpClient client,
    required String baseUrl,
    String? defaultPool,
  }) : completions = ChatCompletionsResource(
          client: client,
          baseUrl: baseUrl,
          defaultPool: defaultPool,
        );
}

/// Provides chat completion creation and streaming.
class ChatCompletionsResource {
  final CortexHttpClient _client;
  final String _baseUrl;
  final String? _defaultPool;

  /// Creates a [ChatCompletionsResource].
  ChatCompletionsResource({
    required CortexHttpClient client,
    required String baseUrl,
    String? defaultPool,
  })  : _client = client,
        _baseUrl = baseUrl,
        _defaultPool = defaultPool;

  /// Creates a chat completion.
  ///
  /// [model] is the model identifier to use.
  /// [messages] is the conversation history.
  /// [temperature] controls randomness (0-2).
  /// [maxTokens] limits the response length.
  /// [tools] defines functions the model may call.
  /// [responseFormat] specifies the output format.
  Future<ChatCompletion> create({
    String? model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? n,
    List<String>? stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, int>? logitBias,
    String? user,
    List<ToolDefinition>? tools,
    dynamic toolChoice,
    ResponseFormat? responseFormat,
    int? seed,
    String? pool,
  }) async {
    _validateCreateParams(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
    );

    final request = ChatCompletionRequest(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      n: n,
      stream: false,
      stop: stop,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      user: user,
      tools: tools,
      toolChoice: toolChoice,
      responseFormat: responseFormat,
      seed: seed,
    );

    // Resolve pool: per-request > client default > none
    final resolvedPool = pool ?? _defaultPool;
    final extraHeaders = <String, String>{};
    if (resolvedPool != null) {
      extraHeaders['x-cortex-pool'] = resolvedPool;
    }

    final json = await _client.post(
      '$_baseUrl/chat/completions',
      body: request.toJson(),
      extraHeaders: extraHeaders.isNotEmpty ? extraHeaders : null,
    );
    return ChatCompletion.fromJson(json);
  }

  /// Creates a streaming chat completion.
  ///
  /// Returns a [Stream] of [ChatCompletionChunk] objects.
  ///
  /// ```dart
  /// await for (final chunk in cortex.chat.completions.createStream(
  ///   model: 'default',
  ///   messages: [ChatMessage.user('Hello')],
  /// )) {
  ///   stdout.write(chunk.choices.first.delta?.content ?? '');
  /// }
  /// ```
  Stream<ChatCompletionChunk> createStream({
    String? model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? n,
    List<String>? stop,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    Map<String, int>? logitBias,
    String? user,
    List<ToolDefinition>? tools,
    dynamic toolChoice,
    ResponseFormat? responseFormat,
    int? seed,
    String? pool,
  }) {
    _validateCreateParams(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
    );

    final request = ChatCompletionRequest(
      model: model,
      messages: messages,
      temperature: temperature,
      topP: topP,
      n: n,
      stream: true,
      stop: stop,
      maxTokens: maxTokens,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: logitBias,
      user: user,
      tools: tools,
      toolChoice: toolChoice,
      responseFormat: responseFormat,
      seed: seed,
    );

    // Resolve pool: per-request > client default > none
    final resolvedPool = pool ?? _defaultPool;
    final extraHeaders = <String, String>{};
    if (resolvedPool != null) {
      extraHeaders['x-cortex-pool'] = resolvedPool;
    }

    // We return a stream that lazily initiates the HTTP request.
    late final StreamController<ChatCompletionChunk> controller;
    controller = StreamController<ChatCompletionChunk>(
      onListen: () async {
        try {
          final response = await _client.postStream(
            '$_baseUrl/chat/completions',
            body: request.toJson(),
            extraHeaders: extraHeaders.isNotEmpty ? extraHeaders : null,
          );
          await response.stream
              .transform(const SseTransformer())
              .pipe(controller);
        } catch (e, st) {
          controller.addError(e, st);
          await controller.close();
        }
      },
    );
    return controller.stream;
  }

  void _validateCreateParams({
    String? model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    double? presencePenalty,
    double? frequencyPenalty,
  }) {
    if (model != null && model.isEmpty) {
      throw const CortexValidationException(
        message: 'Model must not be empty.',
        parameter: 'model',
      );
    }
    if (messages.isEmpty) {
      throw const CortexValidationException(
        message: 'Messages must not be empty.',
        parameter: 'messages',
      );
    }
    if (temperature != null && (temperature < 0 || temperature > 2)) {
      throw const CortexValidationException(
        message: 'Temperature must be between 0 and 2.',
        parameter: 'temperature',
      );
    }
    if (topP != null && (topP < 0 || topP > 1)) {
      throw const CortexValidationException(
        message: 'top_p must be between 0 and 1.',
        parameter: 'topP',
      );
    }
    if (presencePenalty != null &&
        (presencePenalty < -2 || presencePenalty > 2)) {
      throw const CortexValidationException(
        message: 'Presence penalty must be between -2 and 2.',
        parameter: 'presencePenalty',
      );
    }
    if (frequencyPenalty != null &&
        (frequencyPenalty < -2 || frequencyPenalty > 2)) {
      throw const CortexValidationException(
        message: 'Frequency penalty must be between -2 and 2.',
        parameter: 'frequencyPenalty',
      );
    }
  }
}

