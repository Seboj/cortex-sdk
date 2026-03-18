/// Conversations resource.
library;

import 'dart:async';

import '../errors.dart';
import '../http_client.dart';
import '../streaming.dart';
import '../types.dart';

/// Provides access to conversation management endpoints.
class ConversationsResource {
  final CortexHttpClient _client;
  final String _baseUrl;

  /// Creates a [ConversationsResource].
  ConversationsResource({
    required CortexHttpClient client,
    required String baseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  /// Lists all conversations.
  Future<List<Conversation>> list() async {
    final json = await _client.get('$_baseUrl/api/conversations');
    final data = json['data'] as List<dynamic>? ??
        json['conversations'] as List<dynamic>?;
    if (data != null) {
      return data
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <Conversation>[];
  }

  /// Creates a new conversation.
  ///
  /// [title] is the conversation title.
  /// [model] is the model to use.
  /// [metadata] is optional additional data.
  Future<Conversation> create({
    String? title,
    String? model,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (model != null) body['model'] = model;
    if (metadata != null) body['metadata'] = metadata;

    final json =
        await _client.post('$_baseUrl/api/conversations', body: body);
    return Conversation.fromJson(json);
  }

  /// Gets a conversation by ID.
  Future<Conversation> get(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    final json = await _client.get('$_baseUrl/api/conversations/$id');
    return Conversation.fromJson(json);
  }

  /// Updates a conversation.
  ///
  /// [id] is the conversation identifier.
  /// [title] optionally updates the title.
  /// [metadata] optionally updates metadata.
  Future<Conversation> update(
    String id, {
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (metadata != null) body['metadata'] = metadata;

    final json = await _client.patch(
      '$_baseUrl/api/conversations/$id',
      body: body,
    );
    return Conversation.fromJson(json);
  }

  /// Deletes a conversation.
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }
    await _client.delete('$_baseUrl/api/conversations/$id');
  }

  /// Streams messages from a conversation via SSE.
  ///
  /// Returns a [Stream] of [ConversationMessage] objects.
  Stream<ConversationMessage> streamMessages(String id) {
    if (id.isEmpty) {
      throw const CortexValidationException(
        message: 'ID must not be empty.',
        parameter: 'id',
      );
    }

    late final StreamController<ConversationMessage> controller;
    controller = StreamController<ConversationMessage>(
      onListen: () async {
        try {
          final response = await _client.getStream(
            '$_baseUrl/api/conversations/$id/messages',
          );
          await response.stream
              .transform(const ConversationSseTransformer())
              .pipe(controller);
        } catch (e, st) {
          controller.addError(e, st);
          await controller.close();
        }
      },
    );
    return controller.stream;
  }
}

