/// All request and response model classes for the Cortex SDK.
library;

import 'package:meta/meta.dart';

// ---------------------------------------------------------------------------
// Chat Messages
// ---------------------------------------------------------------------------

/// Role of a chat message participant.
enum ChatRole {
  /// System prompt message.
  system,

  /// User message.
  user,

  /// Assistant response message.
  assistant,

  /// Tool/function call result message.
  tool,

  /// Function call result message (legacy).
  function_;

  /// Converts this enum to its JSON string representation.
  String toJson() {
    if (this == ChatRole.function_) return 'function';
    return name;
  }

  /// Parses a JSON string into a [ChatRole].
  static ChatRole fromJson(String value) {
    if (value == 'function') return ChatRole.function_;
    return ChatRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatRole.user,
    );
  }
}

/// A message in a chat conversation.
@immutable
class ChatMessage {
  /// The role of the message author.
  final ChatRole role;

  /// The content of the message.
  final String? content;

  /// The name of the author (optional).
  final String? name;

  /// Tool call ID this message is responding to.
  final String? toolCallId;

  /// Tool calls requested by the assistant.
  final List<ToolCall>? toolCalls;

  /// Creates a [ChatMessage].
  const ChatMessage({
    required this.role,
    this.content,
    this.name,
    this.toolCallId,
    this.toolCalls,
  });

  /// Creates a system message.
  const ChatMessage.system(String content)
      : this(role: ChatRole.system, content: content);

  /// Creates a user message.
  const ChatMessage.user(String content)
      : this(role: ChatRole.user, content: content);

  /// Creates an assistant message.
  const ChatMessage.assistant(String content)
      : this(role: ChatRole.assistant, content: content);

  /// Creates a tool result message.
  const ChatMessage.tool({
    required String content,
    required String toolCallId,
  }) : this(
          role: ChatRole.tool,
          content: content,
          toolCallId: toolCallId,
        );

  /// Creates a [ChatMessage] from a JSON map.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: ChatRole.fromJson(json['role'] as String),
      content: json['content'] as String?,
      name: json['name'] as String?,
      toolCallId: json['tool_call_id'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List<dynamic>)
              .map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Converts this message to a JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'role': role.toJson(),
    };
    if (content != null) map['content'] = content;
    if (name != null) map['name'] = name;
    if (toolCallId != null) map['tool_call_id'] = toolCallId;
    if (toolCalls != null) {
      map['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
    }
    return map;
  }

  @override
  String toString() => 'ChatMessage(role: $role, content: $content)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          role == other.role &&
          content == other.content &&
          name == other.name &&
          toolCallId == other.toolCallId;

  @override
  int get hashCode => Object.hash(role, content, name, toolCallId);
}

/// A tool call requested by the assistant.
@immutable
class ToolCall {
  /// Unique identifier for this tool call.
  final String id;

  /// The type of tool call (always "function" currently).
  final String type;

  /// The function to call.
  final FunctionCall function_;

  /// Creates a [ToolCall].
  const ToolCall({
    required this.id,
    this.type = 'function',
    required this.function_,
  });

  /// Creates a [ToolCall] from a JSON map.
  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'function',
      function_:
          FunctionCall.fromJson(json['function'] as Map<String, dynamic>),
    );
  }

  /// Converts this tool call to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function_.toJson(),
      };

  @override
  String toString() => 'ToolCall(id: $id, function: ${function_.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolCall &&
          id == other.id &&
          type == other.type &&
          function_ == other.function_;

  @override
  int get hashCode => Object.hash(id, type, function_);
}

/// A function call within a tool call.
@immutable
class FunctionCall {
  /// The name of the function to call.
  final String name;

  /// The arguments to pass to the function, as a JSON string.
  final String arguments;

  /// Creates a [FunctionCall].
  const FunctionCall({
    required this.name,
    required this.arguments,
  });

  /// Creates a [FunctionCall] from a JSON map.
  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      name: json['name'] as String,
      arguments: json['arguments'] as String,
    );
  }

  /// Converts this function call to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };

  @override
  String toString() => 'FunctionCall(name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionCall &&
          name == other.name &&
          arguments == other.arguments;

  @override
  int get hashCode => Object.hash(name, arguments);
}

// ---------------------------------------------------------------------------
// Chat Completions
// ---------------------------------------------------------------------------

/// Response format specification.
@immutable
class ResponseFormat {
  /// The type of response format (e.g., "text", "json_object").
  final String type;

  /// Creates a [ResponseFormat].
  const ResponseFormat({required this.type});

  /// Text response format.
  static const ResponseFormat text = ResponseFormat(type: 'text');

  /// JSON object response format.
  static const ResponseFormat jsonObject =
      ResponseFormat(type: 'json_object');

  /// Creates a [ResponseFormat] from a JSON map.
  factory ResponseFormat.fromJson(Map<String, dynamic> json) {
    return ResponseFormat(type: json['type'] as String);
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'type': type};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseFormat && type == other.type;

  @override
  int get hashCode => type.hashCode;
}

/// A tool definition for function calling.
@immutable
class ToolDefinition {
  /// The type of tool (always "function").
  final String type;

  /// The function definition.
  final FunctionDefinition function_;

  /// Creates a [ToolDefinition].
  const ToolDefinition({
    this.type = 'function',
    required this.function_,
  });

  /// Creates a [ToolDefinition] from a JSON map.
  factory ToolDefinition.fromJson(Map<String, dynamic> json) {
    return ToolDefinition(
      type: json['type'] as String? ?? 'function',
      function_: FunctionDefinition.fromJson(
          json['function'] as Map<String, dynamic>),
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function_.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolDefinition &&
          type == other.type &&
          function_ == other.function_;

  @override
  int get hashCode => Object.hash(type, function_);
}

/// A function definition within a tool.
@immutable
class FunctionDefinition {
  /// The name of the function.
  final String name;

  /// A description of the function.
  final String? description;

  /// The parameters schema as a JSON-compatible map.
  final Map<String, dynamic>? parameters;

  /// Creates a [FunctionDefinition].
  const FunctionDefinition({
    required this.name,
    this.description,
    this.parameters,
  });

  /// Creates a [FunctionDefinition] from a JSON map.
  factory FunctionDefinition.fromJson(Map<String, dynamic> json) {
    return FunctionDefinition(
      name: json['name'] as String,
      description: json['description'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name};
    if (description != null) map['description'] = description;
    if (parameters != null) map['parameters'] = parameters;
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionDefinition && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Request parameters for creating a chat completion.
@immutable
class ChatCompletionRequest {
  /// The model to use. If omitted, the pool's default model is used.
  final String? model;

  /// The messages in the conversation.
  final List<ChatMessage> messages;

  /// Sampling temperature (0-2).
  final double? temperature;

  /// Top-p nucleus sampling.
  final double? topP;

  /// Number of completions to generate.
  final int? n;

  /// Whether to stream the response.
  final bool? stream;

  /// Stop sequences.
  final List<String>? stop;

  /// Maximum number of tokens to generate.
  final int? maxTokens;

  /// Presence penalty (-2 to 2).
  final double? presencePenalty;

  /// Frequency penalty (-2 to 2).
  final double? frequencyPenalty;

  /// Token bias map.
  final Map<String, int>? logitBias;

  /// User identifier.
  final String? user;

  /// Tools available for the model to call.
  final List<ToolDefinition>? tools;

  /// How the model should choose which tool to call.
  final dynamic toolChoice;

  /// Response format specification.
  final ResponseFormat? responseFormat;

  /// Random seed for deterministic results.
  final int? seed;

  /// Creates a [ChatCompletionRequest].
  const ChatCompletionRequest({
    this.model,
    required this.messages,
    this.temperature,
    this.topP,
    this.n,
    this.stream,
    this.stop,
    this.maxTokens,
    this.presencePenalty,
    this.frequencyPenalty,
    this.logitBias,
    this.user,
    this.tools,
    this.toolChoice,
    this.responseFormat,
    this.seed,
  });

  /// Converts this request to a JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (model != null) map['model'] = model;
    if (temperature != null) map['temperature'] = temperature;
    if (topP != null) map['top_p'] = topP;
    if (n != null) map['n'] = n;
    if (stream != null) map['stream'] = stream;
    if (stop != null) map['stop'] = stop;
    if (maxTokens != null) map['max_tokens'] = maxTokens;
    if (presencePenalty != null) map['presence_penalty'] = presencePenalty;
    if (frequencyPenalty != null) map['frequency_penalty'] = frequencyPenalty;
    if (logitBias != null) map['logit_bias'] = logitBias;
    if (user != null) map['user'] = user;
    if (tools != null) {
      map['tools'] = tools!.map((t) => t.toJson()).toList();
    }
    if (toolChoice != null) map['tool_choice'] = toolChoice;
    if (responseFormat != null) {
      map['response_format'] = responseFormat!.toJson();
    }
    if (seed != null) map['seed'] = seed;
    return map;
  }
}

/// A chat completion response.
@immutable
class ChatCompletion {
  /// Unique identifier for the completion.
  final String id;

  /// Object type (always "chat.completion").
  final String object;

  /// Unix timestamp of creation.
  final int created;

  /// Model used.
  final String model;

  /// The completion choices.
  final List<ChatChoice> choices;

  /// Token usage statistics.
  final Usage? usage;

  /// System fingerprint.
  final String? systemFingerprint;

  /// Creates a [ChatCompletion].
  const ChatCompletion({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
    this.systemFingerprint,
  });

  /// Creates a [ChatCompletion] from a JSON map.
  factory ChatCompletion.fromJson(Map<String, dynamic> json) {
    return ChatCompletion(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => ChatChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      systemFingerprint: json['system_fingerprint'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'object': object,
      'created': created,
      'model': model,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
    if (usage != null) map['usage'] = usage!.toJson();
    if (systemFingerprint != null) {
      map['system_fingerprint'] = systemFingerprint;
    }
    return map;
  }

  @override
  String toString() => 'ChatCompletion(id: $id, model: $model)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCompletion && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A single choice in a chat completion.
@immutable
class ChatChoice {
  /// The index of this choice.
  final int index;

  /// The message generated.
  final ChatMessage message;

  /// The reason generation stopped.
  final String? finishReason;

  /// Creates a [ChatChoice].
  const ChatChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  /// Creates a [ChatChoice] from a JSON map.
  factory ChatChoice.fromJson(Map<String, dynamic> json) {
    return ChatChoice(
      index: json['index'] as int,
      message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'index': index,
        'message': message.toJson(),
        if (finishReason != null) 'finish_reason': finishReason,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatChoice && index == other.index;

  @override
  int get hashCode => index.hashCode;
}

// ---------------------------------------------------------------------------
// Streaming Chat Completions
// ---------------------------------------------------------------------------

/// A streaming chat completion chunk.
@immutable
class ChatCompletionChunk {
  /// Unique identifier for the chunk.
  final String id;

  /// Object type (always "chat.completion.chunk").
  final String object;

  /// Unix timestamp of creation.
  final int created;

  /// Model used.
  final String model;

  /// The delta choices.
  final List<ChatChunkChoice> choices;

  /// System fingerprint.
  final String? systemFingerprint;

  /// Usage (only present in last chunk when requested).
  final Usage? usage;

  /// Creates a [ChatCompletionChunk].
  const ChatCompletionChunk({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.systemFingerprint,
    this.usage,
  });

  /// Creates a [ChatCompletionChunk] from a JSON map.
  factory ChatCompletionChunk.fromJson(Map<String, dynamic> json) {
    return ChatCompletionChunk(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => ChatChunkChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      systemFingerprint: json['system_fingerprint'] as String?,
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'object': object,
      'created': created,
      'model': model,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
    if (systemFingerprint != null) {
      map['system_fingerprint'] = systemFingerprint;
    }
    if (usage != null) map['usage'] = usage!.toJson();
    return map;
  }

  @override
  String toString() => 'ChatCompletionChunk(id: $id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCompletionChunk && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A single choice in a streaming chat completion chunk.
@immutable
class ChatChunkChoice {
  /// The index of this choice.
  final int index;

  /// The delta content.
  final ChatDelta? delta;

  /// The reason generation stopped.
  final String? finishReason;

  /// Creates a [ChatChunkChoice].
  const ChatChunkChoice({
    required this.index,
    this.delta,
    this.finishReason,
  });

  /// Creates a [ChatChunkChoice] from a JSON map.
  factory ChatChunkChoice.fromJson(Map<String, dynamic> json) {
    return ChatChunkChoice(
      index: json['index'] as int,
      delta: json['delta'] != null
          ? ChatDelta.fromJson(json['delta'] as Map<String, dynamic>)
          : null,
      finishReason: json['finish_reason'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'index': index,
        if (delta != null) 'delta': delta!.toJson(),
        if (finishReason != null) 'finish_reason': finishReason,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatChunkChoice && index == other.index;

  @override
  int get hashCode => index.hashCode;
}

/// Delta content in a streaming chunk.
@immutable
class ChatDelta {
  /// The role, if present in this delta.
  final ChatRole? role;

  /// The content fragment.
  final String? content;

  /// Tool calls in this delta.
  final List<ToolCall>? toolCalls;

  /// Creates a [ChatDelta].
  const ChatDelta({
    this.role,
    this.content,
    this.toolCalls,
  });

  /// Creates a [ChatDelta] from a JSON map.
  factory ChatDelta.fromJson(Map<String, dynamic> json) {
    return ChatDelta(
      role: json['role'] != null
          ? ChatRole.fromJson(json['role'] as String)
          : null,
      content: json['content'] as String?,
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List<dynamic>)
              .map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (role != null) map['role'] = role!.toJson();
    if (content != null) map['content'] = content;
    if (toolCalls != null) {
      map['tool_calls'] = toolCalls!.map((t) => t.toJson()).toList();
    }
    return map;
  }

  @override
  String toString() => 'ChatDelta(content: $content)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatDelta &&
          role == other.role &&
          content == other.content;

  @override
  int get hashCode => Object.hash(role, content);
}

// ---------------------------------------------------------------------------
// Text Completions
// ---------------------------------------------------------------------------

/// Request parameters for text completions.
@immutable
class CompletionRequest {
  /// The model to use. If omitted, the pool's default model is used.
  final String? model;

  /// The prompt to complete.
  final String prompt;

  /// Maximum tokens to generate.
  final int? maxTokens;

  /// Sampling temperature.
  final double? temperature;

  /// Top-p nucleus sampling.
  final double? topP;

  /// Number of completions.
  final int? n;

  /// Whether to stream.
  final bool? stream;

  /// Stop sequences.
  final List<String>? stop;

  /// Presence penalty.
  final double? presencePenalty;

  /// Frequency penalty.
  final double? frequencyPenalty;

  /// User identifier.
  final String? user;

  /// Creates a [CompletionRequest].
  const CompletionRequest({
    this.model,
    required this.prompt,
    this.maxTokens,
    this.temperature,
    this.topP,
    this.n,
    this.stream,
    this.stop,
    this.presencePenalty,
    this.frequencyPenalty,
    this.user,
  });

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'prompt': prompt,
    };
    if (model != null) map['model'] = model;
    if (maxTokens != null) map['max_tokens'] = maxTokens;
    if (temperature != null) map['temperature'] = temperature;
    if (topP != null) map['top_p'] = topP;
    if (n != null) map['n'] = n;
    if (stream != null) map['stream'] = stream;
    if (stop != null) map['stop'] = stop;
    if (presencePenalty != null) map['presence_penalty'] = presencePenalty;
    if (frequencyPenalty != null) map['frequency_penalty'] = frequencyPenalty;
    if (user != null) map['user'] = user;
    return map;
  }
}

/// A text completion response.
@immutable
class Completion {
  /// Unique identifier.
  final String id;

  /// Object type.
  final String object;

  /// Unix timestamp.
  final int created;

  /// Model used.
  final String model;

  /// The completion choices.
  final List<CompletionChoice> choices;

  /// Token usage.
  final Usage? usage;

  /// Creates a [Completion].
  const Completion({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  /// Creates a [Completion] from a JSON map.
  factory Completion.fromJson(Map<String, dynamic> json) {
    return Completion(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map((e) => CompletionChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'object': object,
      'created': created,
      'model': model,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
    if (usage != null) map['usage'] = usage!.toJson();
    return map;
  }

  @override
  String toString() => 'Completion(id: $id, model: $model)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Completion && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A single choice in a text completion.
@immutable
class CompletionChoice {
  /// The index of this choice.
  final int index;

  /// The generated text.
  final String text;

  /// The reason generation stopped.
  final String? finishReason;

  /// Creates a [CompletionChoice].
  const CompletionChoice({
    required this.index,
    required this.text,
    this.finishReason,
  });

  /// Creates a [CompletionChoice] from a JSON map.
  factory CompletionChoice.fromJson(Map<String, dynamic> json) {
    return CompletionChoice(
      index: json['index'] as int,
      text: json['text'] as String,
      finishReason: json['finish_reason'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'index': index,
        'text': text,
        if (finishReason != null) 'finish_reason': finishReason,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionChoice &&
          index == other.index &&
          text == other.text;

  @override
  int get hashCode => Object.hash(index, text);
}

// ---------------------------------------------------------------------------
// Embeddings
// ---------------------------------------------------------------------------

/// Request for generating embeddings.
@immutable
class EmbeddingRequest {
  /// The model to use. If omitted, the pool's default model is used.
  final String? model;

  /// Input text or list of texts.
  final dynamic input;

  /// Encoding format.
  final String? encodingFormat;

  /// Creates an [EmbeddingRequest].
  const EmbeddingRequest({
    this.model,
    required this.input,
    this.encodingFormat,
  });

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'input': input,
    };
    if (model != null) map['model'] = model;
    if (encodingFormat != null) map['encoding_format'] = encodingFormat;
    return map;
  }
}

/// An embedding response.
@immutable
class EmbeddingResponse {
  /// Object type.
  final String object;

  /// The embedding data.
  final List<EmbeddingData> data;

  /// Model used.
  final String model;

  /// Token usage.
  final Usage? usage;

  /// Creates an [EmbeddingResponse].
  const EmbeddingResponse({
    required this.object,
    required this.data,
    required this.model,
    this.usage,
  });

  /// Creates an [EmbeddingResponse] from a JSON map.
  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    return EmbeddingResponse(
      object: json['object'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => EmbeddingData.fromJson(e as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String,
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'object': object,
      'data': data.map((d) => d.toJson()).toList(),
      'model': model,
    };
    if (usage != null) map['usage'] = usage!.toJson();
    return map;
  }

  @override
  String toString() => 'EmbeddingResponse(model: $model)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddingResponse && model == other.model;

  @override
  int get hashCode => model.hashCode;
}

/// A single embedding vector.
@immutable
class EmbeddingData {
  /// Object type.
  final String object;

  /// The embedding vector.
  final List<double> embedding;

  /// Index in the input list.
  final int index;

  /// Creates an [EmbeddingData].
  const EmbeddingData({
    required this.object,
    required this.embedding,
    required this.index,
  });

  /// Creates an [EmbeddingData] from a JSON map.
  factory EmbeddingData.fromJson(Map<String, dynamic> json) {
    return EmbeddingData(
      object: json['object'] as String,
      embedding: (json['embedding'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      index: json['index'] as int,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'object': object,
        'embedding': embedding,
        'index': index,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddingData && index == other.index;

  @override
  int get hashCode => index.hashCode;
}

// ---------------------------------------------------------------------------
// Usage
// ---------------------------------------------------------------------------

/// Token usage statistics.
@immutable
class Usage {
  /// Number of tokens in the prompt.
  final int promptTokens;

  /// Number of tokens in the completion.
  final int completionTokens;

  /// Total tokens used.
  final int totalTokens;

  /// Creates a [Usage].
  const Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  /// Creates a [Usage] from a JSON map.
  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] as int,
      completionTokens: json['completion_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'total_tokens': totalTokens,
      };

  @override
  String toString() =>
      'Usage(prompt: $promptTokens, completion: $completionTokens, total: $totalTokens)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usage &&
          promptTokens == other.promptTokens &&
          completionTokens == other.completionTokens &&
          totalTokens == other.totalTokens;

  @override
  int get hashCode =>
      Object.hash(promptTokens, completionTokens, totalTokens);
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A model available on the platform.
@immutable
class Model {
  /// Model identifier.
  final String id;

  /// Object type.
  final String object;

  /// Unix timestamp of creation.
  final int? created;

  /// The organization that owns the model.
  final String? ownedBy;

  /// Additional model metadata.
  final Map<String, dynamic>? metadata;

  /// Creates a [Model].
  const Model({
    required this.id,
    required this.object,
    this.created,
    this.ownedBy,
    this.metadata,
  });

  /// Creates a [Model] from a JSON map.
  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int?,
      ownedBy: json['owned_by'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'object': object,
    };
    if (created != null) map['created'] = created;
    if (ownedBy != null) map['owned_by'] = ownedBy;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }

  @override
  String toString() => 'Model(id: $id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Model && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Response from listing models.
@immutable
class ModelList {
  /// Object type.
  final String object;

  /// The list of models.
  final List<Model> data;

  /// Creates a [ModelList].
  const ModelList({
    required this.object,
    required this.data,
  });

  /// Creates a [ModelList] from a JSON map.
  factory ModelList.fromJson(Map<String, dynamic> json) {
    return ModelList(
      object: json['object'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => Model.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'object': object,
        'data': data.map((m) => m.toJson()).toList(),
      };

  @override
  String toString() => 'ModelList(count: ${data.length})';
}

// ---------------------------------------------------------------------------
// API Keys
// ---------------------------------------------------------------------------

/// An API key.
@immutable
class ApiKey {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String? name;

  /// The key value (only returned on creation, masked otherwise).
  final String? key;

  /// Creation timestamp.
  final String? createdAt;

  /// Last used timestamp.
  final String? lastUsedAt;

  /// Whether the key is active.
  final bool? active;

  /// Scopes/permissions.
  final List<String>? scopes;

  /// Creates an [ApiKey].
  const ApiKey({
    required this.id,
    this.name,
    this.key,
    this.createdAt,
    this.lastUsedAt,
    this.active,
    this.scopes,
  });

  /// Creates an [ApiKey] from a JSON map.
  factory ApiKey.fromJson(Map<String, dynamic> json) {
    return ApiKey(
      id: json['id'] as String,
      name: json['name'] as String?,
      key: json['key'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      lastUsedAt:
          json['lastUsedAt'] as String? ?? json['last_used_at'] as String?,
      active: json['active'] as bool?,
      scopes: json['scopes'] != null
          ? (json['scopes'] as List<dynamic>).cast<String>()
          : null,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (name != null) map['name'] = name;
    if (key != null) map['key'] = key;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (lastUsedAt != null) map['lastUsedAt'] = lastUsedAt;
    if (active != null) map['active'] = active;
    if (scopes != null) map['scopes'] = scopes;
    return map;
  }

  @override
  String toString() => 'ApiKey(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiKey && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Teams
// ---------------------------------------------------------------------------

/// A team.
@immutable
class Team {
  /// Unique identifier.
  final String id;

  /// Team name.
  final String name;

  /// Description.
  final String? description;

  /// Team members.
  final List<TeamMember>? members;

  /// Creation timestamp.
  final String? createdAt;

  /// Last updated timestamp.
  final String? updatedAt;

  /// Creates a [Team].
  const Team({
    required this.id,
    required this.name,
    this.description,
    this.members,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Team] from a JSON map.
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      members: json['members'] != null
          ? (json['members'] as List<dynamic>)
              .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
    };
    if (description != null) map['description'] = description;
    if (members != null) {
      map['members'] = members!.map((m) => m.toJson()).toList();
    }
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    return map;
  }

  @override
  String toString() => 'Team(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Team && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A team member.
@immutable
class TeamMember {
  /// Member identifier.
  final String id;

  /// Member email.
  final String? email;

  /// Member name.
  final String? name;

  /// Role in the team.
  final String role;

  /// When they joined.
  final String? joinedAt;

  /// Creates a [TeamMember].
  const TeamMember({
    required this.id,
    this.email,
    this.name,
    required this.role,
    this.joinedAt,
  });

  /// Creates a [TeamMember] from a JSON map.
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      role: json['role'] as String,
      joinedAt: json['joinedAt'] as String? ?? json['joined_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'role': role,
    };
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (joinedAt != null) map['joinedAt'] = joinedAt;
    return map;
  }

  @override
  String toString() => 'TeamMember(id: $id, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TeamMember && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Usage Stats & Limits
// ---------------------------------------------------------------------------

/// Usage statistics response.
@immutable
class UsageStats {
  /// Total requests made.
  final int? totalRequests;

  /// Total tokens consumed.
  final int? totalTokens;

  /// Total prompt tokens.
  final int? promptTokens;

  /// Total completion tokens.
  final int? completionTokens;

  /// Per-model usage breakdown.
  final List<ModelUsage>? byModel;

  /// Time period start.
  final String? periodStart;

  /// Time period end.
  final String? periodEnd;

  /// Raw data from the API.
  final Map<String, dynamic> raw;

  /// Creates a [UsageStats].
  const UsageStats({
    this.totalRequests,
    this.totalTokens,
    this.promptTokens,
    this.completionTokens,
    this.byModel,
    this.periodStart,
    this.periodEnd,
    this.raw = const {},
  });

  /// Creates a [UsageStats] from a JSON map.
  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      totalRequests: json['totalRequests'] as int? ??
          json['total_requests'] as int?,
      totalTokens:
          json['totalTokens'] as int? ?? json['total_tokens'] as int?,
      promptTokens:
          json['promptTokens'] as int? ?? json['prompt_tokens'] as int?,
      completionTokens: json['completionTokens'] as int? ??
          json['completion_tokens'] as int?,
      byModel: json['byModel'] != null
          ? (json['byModel'] as List<dynamic>)
              .map((e) => ModelUsage.fromJson(e as Map<String, dynamic>))
              .toList()
          : json['by_model'] != null
              ? (json['by_model'] as List<dynamic>)
                  .map((e) => ModelUsage.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
      periodStart:
          json['periodStart'] as String? ?? json['period_start'] as String?,
      periodEnd:
          json['periodEnd'] as String? ?? json['period_end'] as String?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (totalRequests != null) map['totalRequests'] = totalRequests;
    if (totalTokens != null) map['totalTokens'] = totalTokens;
    if (promptTokens != null) map['promptTokens'] = promptTokens;
    if (completionTokens != null) map['completionTokens'] = completionTokens;
    if (byModel != null) {
      map['byModel'] = byModel!.map((m) => m.toJson()).toList();
    }
    if (periodStart != null) map['periodStart'] = periodStart;
    if (periodEnd != null) map['periodEnd'] = periodEnd;
    return map;
  }

  @override
  String toString() =>
      'UsageStats(requests: $totalRequests, tokens: $totalTokens)';
}

/// Per-model usage breakdown.
@immutable
class ModelUsage {
  /// Model identifier.
  final String model;

  /// Number of requests.
  final int? requests;

  /// Number of tokens used.
  final int? tokens;

  /// Creates a [ModelUsage].
  const ModelUsage({
    required this.model,
    this.requests,
    this.tokens,
  });

  /// Creates a [ModelUsage] from a JSON map.
  factory ModelUsage.fromJson(Map<String, dynamic> json) {
    return ModelUsage(
      model: json['model'] as String,
      requests: json['requests'] as int?,
      tokens: json['tokens'] as int?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'model': model};
    if (requests != null) map['requests'] = requests;
    if (tokens != null) map['tokens'] = tokens;
    return map;
  }

  @override
  String toString() => 'ModelUsage(model: $model)';
}

/// Usage limits response.
@immutable
class UsageLimits {
  /// Rate limit (requests per minute).
  final int? requestsPerMinute;

  /// Token limit per request.
  final int? tokensPerRequest;

  /// Monthly token budget.
  final int? monthlyTokenBudget;

  /// Tokens used this month.
  final int? tokensUsedThisMonth;

  /// Raw data from the API.
  final Map<String, dynamic> raw;

  /// Creates a [UsageLimits].
  const UsageLimits({
    this.requestsPerMinute,
    this.tokensPerRequest,
    this.monthlyTokenBudget,
    this.tokensUsedThisMonth,
    this.raw = const {},
  });

  /// Creates a [UsageLimits] from a JSON map.
  factory UsageLimits.fromJson(Map<String, dynamic> json) {
    return UsageLimits(
      requestsPerMinute: json['requestsPerMinute'] as int? ??
          json['requests_per_minute'] as int?,
      tokensPerRequest: json['tokensPerRequest'] as int? ??
          json['tokens_per_request'] as int?,
      monthlyTokenBudget: json['monthlyTokenBudget'] as int? ??
          json['monthly_token_budget'] as int?,
      tokensUsedThisMonth: json['tokensUsedThisMonth'] as int? ??
          json['tokens_used_this_month'] as int?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (requestsPerMinute != null) {
      map['requestsPerMinute'] = requestsPerMinute;
    }
    if (tokensPerRequest != null) {
      map['tokensPerRequest'] = tokensPerRequest;
    }
    if (monthlyTokenBudget != null) {
      map['monthlyTokenBudget'] = monthlyTokenBudget;
    }
    if (tokensUsedThisMonth != null) {
      map['tokensUsedThisMonth'] = tokensUsedThisMonth;
    }
    return map;
  }

  @override
  String toString() => 'UsageLimits(rpm: $requestsPerMinute)';
}

// ---------------------------------------------------------------------------
// Performance
// ---------------------------------------------------------------------------

/// Performance metrics response.
@immutable
class PerformanceMetrics {
  /// Average latency in milliseconds.
  final double? avgLatencyMs;

  /// P95 latency in milliseconds.
  final double? p95LatencyMs;

  /// P99 latency in milliseconds.
  final double? p99LatencyMs;

  /// Success rate (0-1).
  final double? successRate;

  /// Total requests in the period.
  final int? totalRequests;

  /// Error rate (0-1).
  final double? errorRate;

  /// Raw data from the API.
  final Map<String, dynamic> raw;

  /// Creates a [PerformanceMetrics].
  const PerformanceMetrics({
    this.avgLatencyMs,
    this.p95LatencyMs,
    this.p99LatencyMs,
    this.successRate,
    this.totalRequests,
    this.errorRate,
    this.raw = const {},
  });

  /// Creates a [PerformanceMetrics] from a JSON map.
  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      avgLatencyMs: (json['avgLatencyMs'] as num?)?.toDouble() ??
          (json['avg_latency_ms'] as num?)?.toDouble(),
      p95LatencyMs: (json['p95LatencyMs'] as num?)?.toDouble() ??
          (json['p95_latency_ms'] as num?)?.toDouble(),
      p99LatencyMs: (json['p99LatencyMs'] as num?)?.toDouble() ??
          (json['p99_latency_ms'] as num?)?.toDouble(),
      successRate: (json['successRate'] as num?)?.toDouble() ??
          (json['success_rate'] as num?)?.toDouble(),
      totalRequests: json['totalRequests'] as int? ??
          json['total_requests'] as int?,
      errorRate: (json['errorRate'] as num?)?.toDouble() ??
          (json['error_rate'] as num?)?.toDouble(),
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (avgLatencyMs != null) map['avgLatencyMs'] = avgLatencyMs;
    if (p95LatencyMs != null) map['p95LatencyMs'] = p95LatencyMs;
    if (p99LatencyMs != null) map['p99LatencyMs'] = p99LatencyMs;
    if (successRate != null) map['successRate'] = successRate;
    if (totalRequests != null) map['totalRequests'] = totalRequests;
    if (errorRate != null) map['errorRate'] = errorRate;
    return map;
  }

  @override
  String toString() =>
      'PerformanceMetrics(avgLatency: ${avgLatencyMs}ms, successRate: $successRate)';
}

// ---------------------------------------------------------------------------
// Conversations
// ---------------------------------------------------------------------------

/// A conversation.
@immutable
class Conversation {
  /// Unique identifier.
  final String id;

  /// Conversation title.
  final String? title;

  /// Model used.
  final String? model;

  /// Creation timestamp.
  final String? createdAt;

  /// Last updated timestamp.
  final String? updatedAt;

  /// Message count.
  final int? messageCount;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  /// Creates a [Conversation].
  const Conversation({
    required this.id,
    this.title,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.messageCount,
    this.metadata,
  });

  /// Creates a [Conversation] from a JSON map.
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      model: json['model'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
      messageCount: json['messageCount'] as int? ??
          json['message_count'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (title != null) map['title'] = title;
    if (model != null) map['model'] = model;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    if (messageCount != null) map['messageCount'] = messageCount;
    if (metadata != null) map['metadata'] = metadata;
    return map;
  }

  @override
  String toString() => 'Conversation(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A conversation message (used in SSE streaming).
@immutable
class ConversationMessage {
  /// Message identifier.
  final String? id;

  /// Role of the message author.
  final String? role;

  /// Message content.
  final String? content;

  /// Timestamp.
  final String? createdAt;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates a [ConversationMessage].
  const ConversationMessage({
    this.id,
    this.role,
    this.content,
    this.createdAt,
    this.raw = const {},
  });

  /// Creates a [ConversationMessage] from a JSON map.
  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String?,
      role: json['role'] as String?,
      content: json['content'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (role != null) map['role'] = role;
    if (content != null) map['content'] = content;
    if (createdAt != null) map['createdAt'] = createdAt;
    return map;
  }

  @override
  String toString() => 'ConversationMessage(id: $id, role: $role)';
}

// ---------------------------------------------------------------------------
// Iris (Data Extraction)
// ---------------------------------------------------------------------------

/// An Iris extraction job.
@immutable
class IrisJob {
  /// Job identifier.
  final String? id;

  /// Job status.
  final String? status;

  /// Extracted data.
  final Map<String, dynamic>? result;

  /// Error message if failed.
  final String? error;

  /// Creation timestamp.
  final String? createdAt;

  /// Completion timestamp.
  final String? completedAt;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates an [IrisJob].
  const IrisJob({
    this.id,
    this.status,
    this.result,
    this.error,
    this.createdAt,
    this.completedAt,
    this.raw = const {},
  });

  /// Creates an [IrisJob] from a JSON map.
  factory IrisJob.fromJson(Map<String, dynamic> json) {
    return IrisJob(
      id: json['id'] as String?,
      status: json['status'] as String?,
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      completedAt:
          json['completedAt'] as String? ?? json['completed_at'] as String?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (status != null) map['status'] = status;
    if (result != null) map['result'] = result;
    if (error != null) map['error'] = error;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (completedAt != null) map['completedAt'] = completedAt;
    return map;
  }

  @override
  String toString() => 'IrisJob(id: $id, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrisJob && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// An Iris extraction schema.
@immutable
class IrisSchema {
  /// Schema identifier.
  final String? id;

  /// Schema name.
  final String? name;

  /// Schema definition.
  final Map<String, dynamic>? schema;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates an [IrisSchema].
  const IrisSchema({
    this.id,
    this.name,
    this.schema,
    this.raw = const {},
  });

  /// Creates an [IrisSchema] from a JSON map.
  factory IrisSchema.fromJson(Map<String, dynamic> json) {
    return IrisSchema(
      id: json['id'] as String?,
      name: json['name'] as String?,
      schema: json['schema'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (name != null) map['name'] = name;
    if (schema != null) map['schema'] = schema;
    return map;
  }

  @override
  String toString() => 'IrisSchema(id: $id, name: $name)';
}

// ---------------------------------------------------------------------------
// Plugins
// ---------------------------------------------------------------------------

/// A plugin.
@immutable
class Plugin {
  /// Plugin identifier.
  final String? id;

  /// Plugin name.
  final String? name;

  /// Plugin description.
  final String? description;

  /// Whether the plugin is enabled.
  final bool? enabled;

  /// Plugin version.
  final String? version;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates a [Plugin].
  const Plugin({
    this.id,
    this.name,
    this.description,
    this.enabled,
    this.version,
    this.raw = const {},
  });

  /// Creates a [Plugin] from a JSON map.
  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      enabled: json['enabled'] as bool?,
      version: json['version'] as String?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (enabled != null) map['enabled'] = enabled;
    if (version != null) map['version'] = version;
    return map;
  }

  @override
  String toString() => 'Plugin(id: $id, name: $name)';
}

// ---------------------------------------------------------------------------
// PDF Generation
// ---------------------------------------------------------------------------

/// Response from PDF generation.
@immutable
class PdfGenerationResult {
  /// URL to the generated PDF.
  final String? url;

  /// Base64-encoded PDF data.
  final String? data;

  /// Job status.
  final String? status;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates a [PdfGenerationResult].
  const PdfGenerationResult({
    this.url,
    this.data,
    this.status,
    this.raw = const {},
  });

  /// Creates a [PdfGenerationResult] from a JSON map.
  factory PdfGenerationResult.fromJson(Map<String, dynamic> json) {
    return PdfGenerationResult(
      url: json['url'] as String?,
      data: json['data'] as String?,
      status: json['status'] as String?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (url != null) map['url'] = url;
    if (data != null) map['data'] = data;
    if (status != null) map['status'] = status;
    return map;
  }

  @override
  String toString() => 'PdfGenerationResult(status: $status)';
}

// ---------------------------------------------------------------------------
// Web Search
// ---------------------------------------------------------------------------

/// A web search result.
@immutable
class WebSearchResult {
  /// The title of the result.
  final String? title;

  /// The URL.
  final String? url;

  /// The snippet/description.
  final String? snippet;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates a [WebSearchResult].
  const WebSearchResult({
    this.title,
    this.url,
    this.snippet,
    this.raw = const {},
  });

  /// Creates a [WebSearchResult] from a JSON map.
  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      title: json['title'] as String?,
      url: json['url'] as String?,
      snippet: json['snippet'] as String?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (url != null) map['url'] = url;
    if (snippet != null) map['snippet'] = snippet;
    return map;
  }

  @override
  String toString() => 'WebSearchResult(title: $title)';
}

/// Response from web search.
@immutable
class WebSearchResponse {
  /// The search results.
  final List<WebSearchResult> results;

  /// Total number of results.
  final int? totalResults;

  /// Raw data.
  final Map<String, dynamic> raw;

  /// Creates a [WebSearchResponse].
  const WebSearchResponse({
    required this.results,
    this.totalResults,
    this.raw = const {},
  });

  /// Creates a [WebSearchResponse] from a JSON map.
  factory WebSearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    return WebSearchResponse(
      results: resultsList
          .map((e) => WebSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalResults: json['totalResults'] as int? ??
          json['total_results'] as int?,
      raw: json,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'results': results.map((r) => r.toJson()).toList(),
        if (totalResults != null) 'totalResults': totalResults,
      };

  @override
  String toString() => 'WebSearchResponse(count: ${results.length})';
}

// ---------------------------------------------------------------------------
// Optimizations
// ---------------------------------------------------------------------------

/// Optimization settings.
@immutable
class OptimizationSettings {
  /// Raw data from the API.
  final Map<String, dynamic> raw;

  /// Creates an [OptimizationSettings].
  const OptimizationSettings({this.raw = const {}});

  /// Creates from JSON.
  factory OptimizationSettings.fromJson(Map<String, dynamic> json) {
    return OptimizationSettings(raw: json);
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => raw;

  @override
  String toString() => 'OptimizationSettings()';
}

// ---------------------------------------------------------------------------
// Pools
// ---------------------------------------------------------------------------

/// A backend pool.
@immutable
class Pool {
  /// Unique identifier.
  final String id;

  /// Pool name.
  final String? name;

  /// Pool description.
  final String? description;

  /// List of backend IDs in this pool.
  final List<String>? backends;

  /// Creation timestamp.
  final String? createdAt;

  /// Last updated timestamp.
  final String? updatedAt;

  /// Creates a [Pool].
  const Pool({
    required this.id,
    this.name,
    this.description,
    this.backends,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Pool] from a JSON map.
  factory Pool.fromJson(Map<String, dynamic> json) {
    return Pool(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      backends: json['backends'] != null
          ? (json['backends'] as List<dynamic>).cast<String>()
          : null,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (backends != null) map['backends'] = backends;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    return map;
  }

  @override
  String toString() => 'Pool(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Pool && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Backends
// ---------------------------------------------------------------------------

/// A backend server.
@immutable
class Backend {
  /// Unique identifier.
  final String id;

  /// Backend name.
  final String? name;

  /// Backend URL.
  final String? url;

  /// Backend status.
  final String? status;

  /// Backend type/provider.
  final String? provider;

  /// Available models on this backend.
  final List<BackendModel>? models;

  /// Creation timestamp.
  final String? createdAt;

  /// Last updated timestamp.
  final String? updatedAt;

  /// Creates a [Backend].
  const Backend({
    required this.id,
    this.name,
    this.url,
    this.status,
    this.provider,
    this.models,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Backend] from a JSON map.
  factory Backend.fromJson(Map<String, dynamic> json) {
    return Backend(
      id: json['id'] as String,
      name: json['name'] as String?,
      url: json['url'] as String?,
      status: json['status'] as String?,
      provider: json['provider'] as String?,
      models: json['models'] != null
          ? (json['models'] as List<dynamic>)
              .map((e) => BackendModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (name != null) map['name'] = name;
    if (url != null) map['url'] = url;
    if (status != null) map['status'] = status;
    if (provider != null) map['provider'] = provider;
    if (models != null) {
      map['models'] = models!.map((m) => m.toJson()).toList();
    }
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    return map;
  }

  @override
  String toString() => 'Backend(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Backend && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A model available on a backend.
@immutable
class BackendModel {
  /// Model identifier.
  final String id;

  /// Display name.
  final String? displayName;

  /// Creates a [BackendModel].
  const BackendModel({
    required this.id,
    this.displayName,
  });

  /// Creates a [BackendModel] from a JSON map.
  factory BackendModel.fromJson(Map<String, dynamic> json) {
    return BackendModel(
      id: json['id'] as String,
      displayName:
          json['displayName'] as String? ?? json['display_name'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (displayName != null) map['displayName'] = displayName;
    return map;
  }

  @override
  String toString() => 'BackendModel(id: $id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BackendModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

/// A Cortex platform user.
@immutable
class CortexUser {
  /// Unique identifier.
  final String id;

  /// User email.
  final String? email;

  /// Display name.
  final String? name;

  /// User role.
  final String? role;

  /// Account status.
  final String? status;

  /// Creation timestamp.
  final String? createdAt;

  /// Last updated timestamp.
  final String? updatedAt;

  /// Creates a [CortexUser].
  const CortexUser({
    required this.id,
    this.email,
    this.name,
    this.role,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [CortexUser] from a JSON map.
  factory CortexUser.fromJson(Map<String, dynamic> json) {
    return CortexUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (role != null) map['role'] = role;
    if (status != null) map['status'] = status;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    return map;
  }

  @override
  String toString() => 'CortexUser(id: $id, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CortexUser && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Pending user approval count.
@immutable
class PendingCount {
  /// Number of users awaiting approval.
  final int count;

  /// Creates a [PendingCount].
  const PendingCount({required this.count});

  /// Creates a [PendingCount] from a JSON map.
  factory PendingCount.fromJson(Map<String, dynamic> json) {
    return PendingCount(
      count: json['count'] as int? ?? 0,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'count': count};

  @override
  String toString() => 'PendingCount(count: $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PendingCount && count == other.count;

  @override
  int get hashCode => count.hashCode;
}

// ---------------------------------------------------------------------------
// Usage Limits (Admin)
// ---------------------------------------------------------------------------

/// A usage limit configuration.
@immutable
class UsageLimit {
  /// Unique identifier.
  final String? id;

  /// User ID this limit applies to.
  final String? userId;

  /// Team ID this limit applies to.
  final String? teamId;

  /// Rate limit (requests per minute).
  final int? requestsPerMinute;

  /// Token limit per request.
  final int? tokensPerRequest;

  /// Monthly token budget.
  final int? monthlyTokenBudget;

  /// Creates a [UsageLimit].
  const UsageLimit({
    this.id,
    this.userId,
    this.teamId,
    this.requestsPerMinute,
    this.tokensPerRequest,
    this.monthlyTokenBudget,
  });

  /// Creates a [UsageLimit] from a JSON map.
  factory UsageLimit.fromJson(Map<String, dynamic> json) {
    return UsageLimit(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String?,
      teamId: json['teamId'] as String? ?? json['team_id'] as String?,
      requestsPerMinute: json['requestsPerMinute'] as int? ??
          json['requests_per_minute'] as int?,
      tokensPerRequest: json['tokensPerRequest'] as int? ??
          json['tokens_per_request'] as int?,
      monthlyTokenBudget: json['monthlyTokenBudget'] as int? ??
          json['monthly_token_budget'] as int?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (userId != null) map['userId'] = userId;
    if (teamId != null) map['teamId'] = teamId;
    if (requestsPerMinute != null) {
      map['requestsPerMinute'] = requestsPerMinute;
    }
    if (tokensPerRequest != null) {
      map['tokensPerRequest'] = tokensPerRequest;
    }
    if (monthlyTokenBudget != null) {
      map['monthlyTokenBudget'] = monthlyTokenBudget;
    }
    return map;
  }

  @override
  String toString() => 'UsageLimit(id: $id, userId: $userId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UsageLimit && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Admin API Keys
// ---------------------------------------------------------------------------

/// An admin API key.
@immutable
class AdminApiKey {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String? name;

  /// The key value (only returned on creation, masked otherwise).
  final String? key;

  /// Whether the key is active.
  final bool? active;

  /// Creation timestamp.
  final String? createdAt;

  /// Last used timestamp.
  final String? lastUsedAt;

  /// Creates an [AdminApiKey].
  const AdminApiKey({
    required this.id,
    this.name,
    this.key,
    this.active,
    this.createdAt,
    this.lastUsedAt,
  });

  /// Creates an [AdminApiKey] from a JSON map.
  factory AdminApiKey.fromJson(Map<String, dynamic> json) {
    return AdminApiKey(
      id: json['id'] as String,
      name: json['name'] as String?,
      key: json['key'] as String?,
      active: json['active'] as bool?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      lastUsedAt:
          json['lastUsedAt'] as String? ?? json['last_used_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'id': id};
    if (name != null) map['name'] = name;
    if (key != null) map['key'] = key;
    if (active != null) map['active'] = active;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (lastUsedAt != null) map['lastUsedAt'] = lastUsedAt;
    return map;
  }

  @override
  String toString() => 'AdminApiKey(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AdminApiKey && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Audit Log
// ---------------------------------------------------------------------------

/// An audit log entry.
@immutable
class AuditLogEntry {
  /// Unique identifier.
  final String? id;

  /// Action performed.
  final String? action;

  /// User who performed the action.
  final String? userId;

  /// Target resource type.
  final String? resourceType;

  /// Target resource ID.
  final String? resourceId;

  /// Additional details.
  final Map<String, dynamic>? details;

  /// Timestamp.
  final String? createdAt;

  /// Creates an [AuditLogEntry].
  const AuditLogEntry({
    this.id,
    this.action,
    this.userId,
    this.resourceType,
    this.resourceId,
    this.details,
    this.createdAt,
  });

  /// Creates an [AuditLogEntry] from a JSON map.
  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String?,
      action: json['action'] as String?,
      userId: json['userId'] as String? ?? json['user_id'] as String?,
      resourceType: json['resourceType'] as String? ??
          json['resource_type'] as String?,
      resourceId:
          json['resourceId'] as String? ?? json['resource_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (action != null) map['action'] = action;
    if (userId != null) map['userId'] = userId;
    if (resourceType != null) map['resourceType'] = resourceType;
    if (resourceId != null) map['resourceId'] = resourceId;
    if (details != null) map['details'] = details;
    if (createdAt != null) map['createdAt'] = createdAt;
    return map;
  }

  @override
  String toString() => 'AuditLogEntry(id: $id, action: $action)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuditLogEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

/// An authenticated user profile.
@immutable
class AuthUser {
  /// Unique identifier.
  final String? id;

  /// User email.
  final String? email;

  /// Display name.
  final String? name;

  /// User role.
  final String? role;

  /// Creates an [AuthUser].
  const AuthUser({
    this.id,
    this.email,
    this.name,
    this.role,
  });

  /// Creates an [AuthUser] from a JSON map.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      role: json['role'] as String?,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (email != null) map['email'] = email;
    if (name != null) map['name'] = name;
    if (role != null) map['role'] = role;
    return map;
  }

  @override
  String toString() => 'AuthUser(id: $id, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthUser && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Login response with token.
@immutable
class AuthTokenResponse {
  /// The authentication token.
  final String token;

  /// The authenticated user.
  final AuthUser? user;

  /// Creates an [AuthTokenResponse].
  const AuthTokenResponse({
    required this.token,
    this.user,
  });

  /// Creates an [AuthTokenResponse] from a JSON map.
  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      token: json['token'] as String,
      user: json['user'] != null
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'token': token};
    if (user != null) map['user'] = user!.toJson();
    return map;
  }

  @override
  String toString() => 'AuthTokenResponse(token: ***)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokenResponse && token == other.token;

  @override
  int get hashCode => token.hashCode;
}

// ---------------------------------------------------------------------------
// Audio
// ---------------------------------------------------------------------------

/// An audio transcription result.
@immutable
class AudioTranscription {
  /// The transcribed text.
  final String text;

  /// Creates an [AudioTranscription].
  const AudioTranscription({
    required this.text,
  });

  /// Creates an [AudioTranscription] from a JSON map.
  factory AudioTranscription.fromJson(Map<String, dynamic> json) {
    return AudioTranscription(
      text: json['text'] as String,
    );
  }

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'text': text};

  @override
  String toString() => 'AudioTranscription(text: ${text.length > 50 ? '${text.substring(0, 50)}...' : text})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioTranscription && text == other.text;

  @override
  int get hashCode => text.hashCode;
}

// ---------------------------------------------------------------------------
// Client Configuration
// ---------------------------------------------------------------------------

/// Configuration for the Cortex SDK client.
@immutable
class CortexConfig {
  /// The API key for authentication.
  final String apiKey;

  /// Base URL for the LLM Gateway API.
  final String gatewayBaseUrl;

  /// Base URL for the Admin/Platform API.
  final String adminBaseUrl;

  /// Request timeout duration.
  final Duration timeout;

  /// Streaming request timeout duration.
  final Duration streamingTimeout;

  /// Maximum number of retries for retryable errors.
  final int maxRetries;

  /// Base delay for exponential backoff.
  final Duration retryBaseDelay;

  /// Maximum delay for exponential backoff.
  final Duration retryMaxDelay;

  /// Default pool slug for routing requests.
  ///
  /// Known pools: 'default', 'cortexvlm' (vision), 'cortex-stt' (speech-to-text),
  /// 'cortex-stt-diarize' (STT with speaker diarization).
  /// When set, all LLM requests include `x-cortex-pool` header unless overridden.
  final String? defaultPool;

  /// Creates a [CortexConfig].
  const CortexConfig({
    required this.apiKey,
    this.gatewayBaseUrl = 'https://cortexapi.nfinitmonkeys.com/v1',
    this.adminBaseUrl = 'https://admin.nfinitmonkeys.com',
    this.timeout = const Duration(seconds: 30),
    this.streamingTimeout = const Duration(seconds: 300),
    this.maxRetries = 3,
    this.retryBaseDelay = const Duration(milliseconds: 500),
    this.retryMaxDelay = const Duration(seconds: 30),
    this.defaultPool,
  });

  /// Returns a masked version of the API key for safe logging.
  String get maskedApiKey {
    if (apiKey.length <= 8) return '***';
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
  }

  @override
  String toString() =>
      'CortexConfig(apiKey: $maskedApiKey, gateway: $gatewayBaseUrl)';
}
