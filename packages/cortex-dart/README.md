# Cortex SDK for Dart/Flutter

Official Dart/Flutter SDK for the [Cortex LLM Gateway](https://admin.nfinitmonkeys.com) by InfiniteMonkeys.

## Installation

```yaml
dependencies:
  nfinitmonkeys_cortex_sdk: ^1.0.0
```

## Quick Start

```dart
import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';

final cortex = CortexClient(apiKey: 'sk-cortex-...');

// Chat completion
final response = await cortex.chat.completions.create(
  model: 'default',
  messages: [ChatMessage.user('Hello!')],
);
print(response.choices.first.message.content);

// Streaming
final stream = cortex.chat.completions.createStream(
  model: 'default',
  messages: [ChatMessage.user('Tell me a story')],
);
await for (final chunk in stream) {
  stdout.write(chunk.choices.first.delta?.content ?? '');
}

// Embeddings
final embeddings = await cortex.embeddings.create(
  model: 'BAAI/bge-m3',
  input: 'Hello world',
);

// Admin: API Keys
final keys = await cortex.keys.list();
final newKey = await cortex.keys.create(name: 'My App');

// Admin: Teams
final teams = await cortex.teams.list();

// Admin: Usage
final usage = await cortex.usage.getStats();
final limits = await cortex.usage.getLimits();

// Iris: Document Extraction
final job = await cortex.iris.extract(document: 'Extract data from this...');
```

## Features

- **LLM API**: Chat completions, text completions, embeddings, model listing
- **Admin API**: API key management, teams & members, usage tracking, performance metrics
- **Conversations**: Full CRUD with SSE message streaming
- **Iris**: Structured document extraction with job tracking
- **Utilities**: PDF generation, web search, plugin listing

## Security

- API keys are never exposed in exceptions or `toString()` output
- HTTPS enforced for all non-localhost connections
- Header injection prevention
- Configurable request timeouts (30s default, 300s for streaming)
- Retry with exponential backoff + jitter on 429/5xx errors

## License

MIT
