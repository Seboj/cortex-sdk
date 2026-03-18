# Cortex SDK

Official SDKs for the [Cortex Secure LLM Gateway](https://admin.nfinitmonkeys.com) by InfiniteMonkeys.

Cortex is a self-hosted, OpenAI-compatible LLM gateway with built-in auth, rate limiting, usage tracking, team management, and document extraction.

## Installation

### TypeScript / JavaScript

```bash
npm install @nfinitmonkeys/cortex-sdk
```

```typescript
import { CortexClient } from '@nfinitmonkeys/cortex-sdk';

const cortex = new CortexClient({ apiKey: 'sk-cortex-...' });

const response = await cortex.chat.completions.create({
  model: 'default',
  messages: [{ role: 'user', content: 'Hello!' }],
});
console.log(response.choices[0].message.content);
```

### Dart / Flutter

```yaml
# pubspec.yaml
dependencies:
  nfinitmonkeys_cortex_sdk: ^1.0.0
```

```dart
import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';

final cortex = CortexClient(apiKey: 'sk-cortex-...');

final response = await cortex.chat.completions.create(
  model: 'default',
  messages: [ChatMessage.user('Hello!')],
);
print(response.choices.first.message.content);
```

### Python

```bash
pip install nfinitmonkeys-cortex-sdk
```

```python
from cortex_sdk import CortexClient

client = CortexClient(api_key="sk-cortex-...")

response = client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Hello!"}],
)
print(response.choices[0].message.content)
```

---

## Features

All three SDKs provide the same capabilities:

### LLM Gateway (OpenAI-compatible)

| Feature | Description |
|---|---|
| **Chat Completions** | Streaming and non-streaming chat with tool/function calling support |
| **Text Completions** | Legacy completion API |
| **Embeddings** | Vector embeddings for search and RAG |
| **Models** | List available models |

### Platform / Admin API

| Feature | Description |
|---|---|
| **API Keys** | Create, list, and revoke API keys |
| **Teams** | Create teams, manage members and roles |
| **Usage** | Query usage stats, check rate limits |
| **Performance** | Performance metrics |
| **Conversations** | Full CRUD with real-time SSE message streaming |
| **Iris** | Structured document extraction with async job tracking |
| **Plugins** | List available plugins |
| **PDF** | Generate PDF documents |
| **Web Search** | Search the web |

---

## Streaming

All SDKs support streaming chat completions via Server-Sent Events (SSE):

**TypeScript:**
```typescript
const stream = await cortex.chat.completions.create({
  model: 'default',
  messages: [{ role: 'user', content: 'Tell me a story' }],
  stream: true,
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? '');
}
```

**Dart:**
```dart
final stream = cortex.chat.completions.createStream(
  model: 'default',
  messages: [ChatMessage.user('Tell me a story')],
);

await for (final chunk in stream) {
  stdout.write(chunk.choices.first.delta?.content ?? '');
}
```

**Python:**
```python
stream = client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True,
)

for chunk in stream:
    print(chunk.choices[0].delta.content or "", end="")
```

---

## Configuration

All SDKs accept the same configuration options:

| Option | Default | Description |
|---|---|---|
| `apiKey` | *required* | Your Cortex API key (`sk-cortex-...`) |
| `llmBaseUrl` | `https://cortexapi.nfinitmonkeys.com/v1` | LLM gateway URL |
| `adminBaseUrl` | `https://admin.nfinitmonkeys.com` | Admin API URL |
| `timeout` | 30s | Request timeout |
| `streamTimeout` | 300s | Streaming request timeout |
| `maxRetries` | 3 | Max retry attempts on transient errors |

---

## Error Handling

All SDKs provide typed errors:

- **AuthenticationError** — Invalid or missing API key (401)
- **PermissionDeniedError** — Insufficient permissions (403)
- **NotFoundError** — Resource not found (404)
- **RateLimitError** — Rate limit exceeded (429), includes `retryAfter`
- **ServerError** — Internal server error (500+)
- **ValidationError** — Invalid request parameters
- **TimeoutError** — Request timed out
- **ConnectionError** — Network connectivity issue

API keys are **never** exposed in error messages, logs, or stack traces.

---

## Security

- HTTPS enforced for all non-localhost connections
- Header injection prevention
- API key masking in all error output and `toString()` representations
- Configurable request timeouts
- Automatic retry with exponential backoff + jitter on 429/5xx

---

## Packages

| Package | Registry | Install |
|---|---|---|
| [`@nfinitmonkeys/cortex-sdk`](packages/cortex-js/) | npm | `npm install @nfinitmonkeys/cortex-sdk` |
| [`nfinitmonkeys_cortex_sdk`](packages/cortex-dart/) | pub.dev | `nfinitmonkeys_cortex_sdk: ^1.0.0` |
| [`cortex-sdk`](packages/cortex-python/) | PyPI | `pip install nfinitmonkeys-cortex-sdk` |

See each package's README for full API documentation.

## License

MIT — Copyright (c) 2026 InfiniteMonkeys
