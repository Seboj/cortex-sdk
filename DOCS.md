# Cortex SDK — Complete Documentation

> Official SDKs for the [Cortex Secure LLM Gateway](https://admin.nfinitmonkeys.com) by InfiniteMonkeys.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Pool Routing](#pool-routing)
- [LLM API](#llm-api)
  - [Chat Completions](#chat-completions)
  - [Streaming](#streaming)
  - [Text Completions](#text-completions)
  - [Embeddings](#embeddings)
  - [Models](#models)
- [Admin / Platform API](#admin--platform-api)
  - [API Keys](#api-keys)
  - [Teams & Members](#teams--members)
  - [Pools](#pools)
  - [Backends](#backends)
  - [Users (Admin)](#users-admin)
  - [Usage & Limits](#usage--limits)
  - [Usage Limits (Admin)](#usage-limits-admin)
  - [Performance Metrics](#performance-metrics)
  - [Conversations](#conversations)
  - [Iris (Document Extraction)](#iris-document-extraction)
  - [Admin API Keys](#admin-api-keys)
  - [Audit Log](#audit-log)
  - [Auth](#auth)
  - [Audio Transcription](#audio-transcription)
  - [PDF Generation](#pdf-generation)
  - [Web Search](#web-search)
  - [Plugins](#plugins)
- [Error Handling](#error-handling)
- [Retry & Resilience](#retry--resilience)
- [Security](#security)
- [Publishing Status](#publishing-status)

---

## Overview

Cortex is a self-hosted, OpenAI-compatible LLM inference gateway with built-in authentication, rate limiting, usage tracking, team management, and document extraction.

The Cortex SDK provides a unified interface across three platforms:

| Language | Package | Registry |
|---|---|---|
| TypeScript / JavaScript | `@nfinitmonkeys/cortex-sdk` | npm |
| Python | `nfinitmonkeys-cortex-sdk` | PyPI |
| Dart / Flutter | `nfinitmonkeys_cortex_sdk` | pub.dev |

All three SDKs share the same API design, method names, and capabilities.

---

## Installation

### TypeScript / JavaScript

```bash
npm install @nfinitmonkeys/cortex-sdk
```

Requires Node.js 18+ (uses native `fetch`).

### Python

```bash
pip install nfinitmonkeys-cortex-sdk
```

Requires Python 3.9+. Provides both synchronous and asynchronous clients.

### Dart / Flutter

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nfinitmonkeys_cortex_sdk: ^1.0.0
```

Then run:

```bash
dart pub get
```

---

## Quick Start

### TypeScript

```typescript
import { CortexClient } from '@nfinitmonkeys/cortex-sdk';

const cortex = new CortexClient({ apiKey: 'sk-cortex-...' });

const response = await cortex.chat.completions.create({
  model: 'default',
  messages: [{ role: 'user', content: 'Hello!' }],
});

console.log(response.choices[0].message.content);
```

### Python (Sync)

```python
from cortex_sdk import CortexClient

client = CortexClient(api_key="sk-cortex-...")

response = client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Hello!"}],
)

print(response.choices[0].message.content)
```

### Python (Async)

```python
from cortex_sdk import AsyncCortexClient

client = AsyncCortexClient(api_key="sk-cortex-...")

response = await client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Hello!"}],
)

print(response.choices[0].message.content)
```

### Dart

```dart
import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';

final cortex = CortexClient(apiKey: 'sk-cortex-...');

final response = await cortex.chat.completions.create(
  model: 'default',
  messages: [ChatMessage.user('Hello!')],
);

print(response.choices.first.message.content);
```

---

## Configuration

All SDKs accept the same options when creating a client:

| Option | Type | Default | Description |
|---|---|---|---|
| `apiKey` | string | **required** | Your Cortex API key (starts with `sk-cortex-`) |
| `llmBaseUrl` | string | `https://cortexapi.nfinitmonkeys.com/v1` | LLM gateway base URL |
| `adminBaseUrl` | string | `https://admin.nfinitmonkeys.com` | Admin/platform API base URL |
| `timeout` | number | `30000` (30s) | Request timeout in milliseconds |
| `streamTimeout` | number | `300000` (5min) | Streaming request timeout in milliseconds |
| `maxRetries` | number | `3` | Maximum retry attempts for transient errors |
| `defaultHeaders` | map | `{}` | Custom headers to include on every request |
| `defaultPool` | string | `undefined` | Default pool slug for all LLM requests (see [Pool Routing](#pool-routing)) |

### TypeScript

```typescript
const cortex = new CortexClient({
  apiKey: 'sk-cortex-...',
  llmBaseUrl: 'https://my-cortex-server.com/v1',
  adminBaseUrl: 'https://my-cortex-admin.com',
  timeout: 60000,
  maxRetries: 5,
  defaultHeaders: { 'X-Custom-Header': 'value' },
});
```

### Python

```python
client = CortexClient(
    api_key="sk-cortex-...",
    llm_base_url="https://my-cortex-server.com/v1",
    admin_base_url="https://my-cortex-admin.com",
    timeout=60.0,
    max_retries=5,
)
```

### Dart

```dart
final cortex = CortexClient(
  apiKey: 'sk-cortex-...',
  llmBaseUrl: 'https://my-cortex-server.com/v1',
  adminBaseUrl: 'https://my-cortex-admin.com',
  timeout: Duration(seconds: 60),
  maxRetries: 5,
);
```

---

## Pool Routing

Cortex uses **pools** to group backends for load balancing and access control. Every LLM request is routed to a pool, which then dispatches to one of its backends.

### How it works

- Requests include an `x-cortex-pool` header to specify the target pool
- If no pool is specified, the **default** pool is used
- If no `model` is specified, the pool's default model is used
- API keys can be restricted to specific pools via `allowed_pools`

### Built-in pools

| Pool Slug | Purpose |
|---|---|
| `default` | General-purpose LLM inference (chat, completions, embeddings) |
| `cortexvlm` | Vision Language Model — used for image understanding and Iris image extraction |
| `cortex-stt` | Speech-to-Text — Whisper audio transcription |
| `cortex-stt-diarize` | Speech-to-Text with speaker diarization (identifies SPEAKER_0, SPEAKER_1, etc.) |

You can create additional custom pools via the [Pools API](#pools).

### Setting a default pool

Set a default pool for all requests from a client:

**TypeScript:**

```typescript
const cortex = new CortexClient({
  apiKey: 'sk-cortex-...',
  defaultPool: 'cortexvlm',
});

// All requests from this client go to the cortexvlm pool
const response = await cortex.chat.completions.create({
  messages: [{ role: 'user', content: 'Describe this image' }],
});
```

**Python:**

```python
client = CortexClient(api_key="sk-cortex-...", default_pool="cortexvlm")
```

**Dart:**

```dart
final cortex = CortexClient(apiKey: 'sk-cortex-...', defaultPool: 'cortexvlm');
```

### Per-request pool override

Override the pool for a single request:

**TypeScript:**

```typescript
// Use the STT pool for this specific request
const transcription = await cortex.audio.transcribe({
  file: audioBuffer,
  pool: 'cortex-stt-diarize',
});

// Use the VLM pool for vision tasks
const response = await cortex.chat.completions.create({
  messages: [{ role: 'user', content: 'What is in this image?' }],
  pool: 'cortexvlm',
});
```

**Python:**

```python
# Per-request pool
transcription = client.audio.transcribe(file=f, pool="cortex-stt-diarize")
response = client.chat.completions.create(
    messages=[{"role": "user", "content": "Describe this image"}],
    pool="cortexvlm",
)
```

**Dart:**

```dart
final transcription = await cortex.audio.transcribe(
  file: audioBytes,
  fileName: 'audio.mp3',
  pool: 'cortex-stt-diarize',
);
```

### Model is optional

Unlike OpenAI, Cortex does **not** require a `model` parameter. When omitted, the pool's default model is used:

```typescript
// No model specified — uses whatever model the default pool provides
const response = await cortex.chat.completions.create({
  messages: [{ role: 'user', content: 'Hello' }],
});
```

This is useful when your pool has exactly one backend, or when you want the admin to control model selection via pool configuration rather than hardcoding it in client code.

---

## LLM API

The LLM API is OpenAI-compatible. These endpoints hit the Cortex inference gateway.

### Chat Completions

The primary way to interact with language models.

**TypeScript:**

```typescript
const response = await cortex.chat.completions.create({
  model: 'default',
  messages: [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'Explain quantum computing in simple terms.' },
  ],
  temperature: 0.7,
  max_tokens: 500,
  top_p: 0.9,
});

console.log(response.choices[0].message.content);
console.log(`Tokens used: ${response.usage.total_tokens}`);
```

**Python:**

```python
response = client.chat.completions.create(
    model="default",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain quantum computing in simple terms."},
    ],
    temperature=0.7,
    max_tokens=500,
    top_p=0.9,
)

print(response.choices[0].message.content)
print(f"Tokens used: {response.usage.total_tokens}")
```

**Dart:**

```dart
final response = await cortex.chat.completions.create(
  model: 'default',
  messages: [
    ChatMessage.system('You are a helpful assistant.'),
    ChatMessage.user('Explain quantum computing in simple terms.'),
  ],
  temperature: 0.7,
  maxTokens: 500,
  topP: 0.9,
);

print(response.choices.first.message.content);
print('Tokens used: ${response.usage?.totalTokens}');
```

#### Chat Parameters

| Parameter | Type | Description |
|---|---|---|
| `model` | string | Model ID to use (optional — pool default is used if omitted) |
| `messages` | array | Conversation messages (role + content) |
| `pool` | string | Target pool slug (overrides `defaultPool` from client config) |
| `temperature` | float (0-2) | Randomness. Lower = more deterministic |
| `top_p` | float (0-1) | Nucleus sampling threshold |
| `max_tokens` | int | Maximum tokens to generate |
| `n` | int | Number of completions to generate |
| `stop` | string or array | Stop sequences |
| `presence_penalty` | float (-2 to 2) | Penalize repeated topics |
| `frequency_penalty` | float (-2 to 2) | Penalize repeated tokens |
| `tools` | array | Tool/function definitions for function calling |
| `tool_choice` | string or object | How the model should use tools |
| `response_format` | object | Force JSON output (`{ type: "json_object" }`) |
| `seed` | int | Deterministic generation seed |
| `stream` | boolean | Enable streaming (see below) |

#### Message Roles

| Role | Description |
|---|---|
| `system` | Sets the assistant's behavior and personality |
| `user` | The human's message |
| `assistant` | Previous assistant responses (for multi-turn context) |
| `tool` | Tool/function call results |

---

### Streaming

Stream responses token-by-token for real-time output.

**TypeScript:**

```typescript
const stream = await cortex.chat.completions.create({
  model: 'default',
  messages: [{ role: 'user', content: 'Write a poem about the ocean' }],
  stream: true,
});

for await (const chunk of stream) {
  const content = chunk.choices[0]?.delta?.content ?? '';
  process.stdout.write(content);
}

// Or collect all text at once:
const stream2 = await cortex.chat.completions.create({
  model: 'default',
  messages: [{ role: 'user', content: 'Hello' }],
  stream: true,
});
const fullText = await stream2.toText();
```

**Python (Sync):**

```python
stream = client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Write a poem about the ocean"}],
    stream=True,
)

for chunk in stream:
    content = chunk.choices[0].delta.content or ""
    print(content, end="", flush=True)
```

**Python (Async):**

```python
stream = await async_client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Write a poem about the ocean"}],
    stream=True,
)

async for chunk in stream:
    content = chunk.choices[0].delta.content or ""
    print(content, end="", flush=True)
```

**Dart:**

```dart
final stream = cortex.chat.completions.createStream(
  model: 'default',
  messages: [ChatMessage.user('Write a poem about the ocean')],
);

await for (final chunk in stream) {
  stdout.write(chunk.choices.first.delta?.content ?? '');
}
```

---

### Text Completions

Legacy completion API (non-chat format).

**TypeScript:**

```typescript
const response = await cortex.completions.create({
  model: 'default',
  prompt: 'Once upon a time, in a land far away,',
  max_tokens: 200,
  temperature: 0.8,
});

console.log(response.choices[0].text);
```

**Python:**

```python
response = client.completions.create(
    model="default",
    prompt="Once upon a time, in a land far away,",
    max_tokens=200,
    temperature=0.8,
)

print(response.choices[0].text)
```

**Dart:**

```dart
final response = await cortex.completions.create(
  model: 'default',
  prompt: 'Once upon a time, in a land far away,',
  maxTokens: 200,
  temperature: 0.8,
);

print(response.choices.first.text);
```

---

### Embeddings

Generate vector embeddings for text (useful for search, RAG, similarity).

**TypeScript:**

```typescript
const response = await cortex.embeddings.create({
  model: 'BAAI/bge-m3',
  input: 'The quick brown fox jumps over the lazy dog',
});

const vector = response.data[0].embedding; // float array
console.log(`Embedding dimensions: ${vector.length}`);

// Multiple inputs at once
const batch = await cortex.embeddings.create({
  model: 'BAAI/bge-m3',
  input: ['First document', 'Second document', 'Third document'],
});
```

**Python:**

```python
response = client.embeddings.create(
    model="BAAI/bge-m3",
    input="The quick brown fox jumps over the lazy dog",
)

vector = response.data[0].embedding  # list of floats
print(f"Embedding dimensions: {len(vector)}")
```

**Dart:**

```dart
final response = await cortex.embeddings.create(
  model: 'BAAI/bge-m3',
  input: 'The quick brown fox jumps over the lazy dog',
);

final vector = response.data.first.embedding;
print('Embedding dimensions: ${vector.length}');
```

---

### Models

List all available models on the Cortex gateway.

**TypeScript:**

```typescript
const models = await cortex.models.list();
for (const model of models.data) {
  console.log(`${model.id} (owned by ${model.owned_by})`);
}
```

**Python:**

```python
models = client.models.list()
for model in models.data:
    print(f"{model.id} (owned by {model.owned_by})")
```

**Dart:**

```dart
final models = await cortex.models.list();
for (final model in models.data) {
  print('${model.id} (owned by ${model.ownedBy})');
}
```

---

## Admin / Platform API

These endpoints are Cortex-specific (not part of the OpenAI API). They manage your Cortex platform.

### API Keys

Create, list, and revoke API keys for your Cortex instance.

**TypeScript:**

```typescript
// List all API keys
const keys = await cortex.keys.list();
for (const key of keys) {
  console.log(`${key.name}: ${key.id}`);
}

// Create a new key
const newKey = await cortex.keys.create({ name: 'Production App' });
console.log(`New key: ${newKey.key}`); // Only shown once!

// Revoke a key
await cortex.keys.delete('key-id-here');
```

**Python:**

```python
# List all API keys
keys = client.keys.list()
for key in keys:
    print(f"{key.name}: {key.id}")

# Create a new key
new_key = client.keys.create(name="Production App")
print(f"New key: {new_key.key}")  # Only shown once!

# Revoke a key
client.keys.delete("key-id-here")
```

**Dart:**

```dart
// List all API keys
final keys = await cortex.keys.list();
for (final key in keys) {
  print('${key.name}: ${key.id}');
}

// Create a new key
final newKey = await cortex.keys.create(name: 'Production App');
print('New key: ${newKey.key}'); // Only shown once!

// Revoke a key
await cortex.keys.delete('key-id-here');
```

---

### Teams & Members

Manage teams and their members.

**TypeScript:**

```typescript
// List teams
const teams = await cortex.teams.list();

// Create a team
const team = await cortex.teams.create({ name: 'Engineering' });

// Get team details
const details = await cortex.teams.get('team-id');

// Delete a team
await cortex.teams.delete('team-id');

// Add a member
await cortex.teams.members.add('team-id', {
  userId: 'user-id',
  role: 'member',
});

// Update a member's role
await cortex.teams.members.update('team-id', 'member-id', {
  role: 'admin',
});

// Remove a member
await cortex.teams.members.remove('team-id', 'member-id');
```

**Python:**

```python
# List teams
teams = client.teams.list()

# Create a team
team = client.teams.create(name="Engineering")

# Get team details
details = client.teams.get("team-id")

# Delete a team
client.teams.delete("team-id")

# Add a member
client.teams.add_member("team-id", user_id="user-id", role="member")

# Update a member's role
client.teams.update_member("team-id", "member-id", role="admin")

# Remove a member
client.teams.remove_member("team-id", "member-id")
```

**Dart:**

```dart
// List teams
final teams = await cortex.teams.list();

// Create a team
final team = await cortex.teams.create(name: 'Engineering');

// Get team details
final details = await cortex.teams.get('team-id');

// Delete a team
await cortex.teams.delete('team-id');

// Add a member
await cortex.teams.addMember('team-id', userId: 'user-id', role: 'member');

// Update role
await cortex.teams.updateMemberRole('team-id', 'member-id', role: 'admin');

// Remove a member
await cortex.teams.removeMember('team-id', 'member-id');
```

---

### Usage & Limits

Track API usage and check rate limits.

**TypeScript:**

```typescript
// Get usage statistics
const usage = await cortex.usage.get({
  startDate: '2026-01-01',
  endDate: '2026-03-18',
  granularity: 'daily',
});

// Check current limits
const limits = await cortex.usage.limits();
console.log(`Requests remaining: ${limits.remaining}`);
```

**Python:**

```python
# Get usage statistics
usage = client.usage.get(start_date="2026-01-01", end_date="2026-03-18")

# Check current limits
limits = client.usage.limits()
```

**Dart:**

```dart
// Get usage statistics
final usage = await cortex.usage.getStats(
  startDate: '2026-01-01',
  endDate: '2026-03-18',
);

// Check current limits
final limits = await cortex.usage.getLimits();
```

---

### Performance Metrics

Get performance statistics for your Cortex instance.

**TypeScript:**

```typescript
const perf = await cortex.performance.get();
```

**Python:**

```python
perf = client.performance.get()
```

**Dart:**

```dart
final perf = await cortex.performance.getMetrics();
```

---

### Conversations

Manage stored conversations with full CRUD and real-time message streaming.

**TypeScript:**

```typescript
// List conversations
const convos = await cortex.conversations.list({ limit: 10, offset: 0 });

// Create a conversation
const convo = await cortex.conversations.create({ title: 'Project Discussion' });

// Get a conversation
const details = await cortex.conversations.get('conv-id');

// Update a conversation
await cortex.conversations.update('conv-id', { title: 'Renamed Discussion' });

// Delete a conversation
await cortex.conversations.delete('conv-id');

// Stream messages in real-time (SSE)
const messages = await cortex.conversations.messages('conv-id');
for await (const msg of messages) {
  console.log(`${msg.role}: ${msg.content}`);
}
```

**Python:**

```python
# List conversations
convos = client.conversations.list()

# Create a conversation
convo = client.conversations.create(title="Project Discussion")

# Get a conversation
details = client.conversations.get("conv-id")

# Update a conversation
client.conversations.update("conv-id", title="Renamed Discussion")

# Delete a conversation
client.conversations.delete("conv-id")
```

**Dart:**

```dart
// List conversations
final convos = await cortex.conversations.list();

// Create a conversation
final convo = await cortex.conversations.create(title: 'Project Discussion');

// Stream messages in real-time (SSE)
final stream = cortex.conversations.streamMessages('conv-id');
await for (final msg in stream) {
  print('${msg.role}: ${msg.content}');
}
```

---

### Iris (Document Extraction)

Extract structured data from documents using AI.

**TypeScript:**

```typescript
// Extract data from text
const job = await cortex.iris.extract({
  document: 'John Doe, age 30, lives in New York. Works at Acme Corp.',
  schema: {
    type: 'object',
    properties: {
      name: { type: 'string' },
      age: { type: 'number' },
      city: { type: 'string' },
      employer: { type: 'string' },
    },
  },
});

// List recent extraction jobs
const jobs = await cortex.iris.jobs({ limit: 20 });

// List available schemas
const schemas = await cortex.iris.schemas();
```

**Python:**

```python
# Extract data from text
job = client.iris.extract(
    document="John Doe, age 30, lives in New York. Works at Acme Corp.",
    schema={
        "type": "object",
        "properties": {
            "name": {"type": "string"},
            "age": {"type": "number"},
            "city": {"type": "string"},
            "employer": {"type": "string"},
        },
    },
)

# List recent extraction jobs
jobs = client.iris.list_jobs(limit=20)

# List available schemas
schemas = client.iris.list_schemas()
```

**Dart:**

```dart
// Extract data from text
final job = await cortex.iris.extract(
  document: 'John Doe, age 30, lives in New York. Works at Acme Corp.',
);

// List recent extraction jobs
final jobs = await cortex.iris.listJobs(limit: 20);

// List available schemas
final schemas = await cortex.iris.listSchemas();
```

---

### PDF Generation

Generate PDF documents.

**TypeScript:**

```typescript
const pdf = await cortex.pdf.generate({
  content: '# Quarterly Report\n\nRevenue increased by 25%...',
});
```

**Python:**

```python
pdf = client.pdf.generate(content="# Quarterly Report\n\nRevenue increased by 25%...")
```

**Dart:**

```dart
final pdf = await cortex.pdf.generate(content: '# Quarterly Report\n\nRevenue increased by 25%...');
```

---

### Web Search

Perform web searches through the Cortex gateway.

**TypeScript:**

```typescript
const results = await cortex.webSearch.search({
  query: 'latest AI research papers 2026',
});
```

**Python:**

```python
results = client.web_search.search(query="latest AI research papers 2026")
```

**Dart:**

```dart
final results = await cortex.webSearch.search(query: 'latest AI research papers 2026');
```

---

### Pools

Pools group backends for load balancing and access control. API keys can be restricted to specific pools.

**TypeScript:**

```typescript
// List all pools
const pools = await cortex.pools.list();

// Create a pool
const pool = await cortex.pools.create({
  name: 'production',
  description: 'Production inference pool',
  strategy: 'round-robin', // load balancing strategy
});

// Update a pool
await cortex.pools.update('pool-id', { name: 'prod-v2' });

// Delete a pool
await cortex.pools.delete('pool-id');

// Add a backend to a pool
await cortex.pools.addBackend('pool-id', { backendId: 'backend-id' });

// Remove a backend from a pool
await cortex.pools.removeBackend('pool-id', 'backend-id');
```

**Python:**

```python
# List all pools
pools = client.pools.list()

# Create a pool
pool = client.pools.create(name="production", description="Production pool", strategy="round-robin")

# Update a pool
client.pools.update("pool-id", name="prod-v2")

# Delete a pool
client.pools.delete("pool-id")

# Add/remove backends
client.pools.add_backend("pool-id", backend_id="backend-id")
client.pools.remove_backend("pool-id", "backend-id")
```

**Dart:**

```dart
final pools = await cortex.pools.list();
final pool = await cortex.pools.create(name: 'production', description: 'Production pool');
await cortex.pools.update('pool-id', name: 'prod-v2');
await cortex.pools.delete('pool-id');
await cortex.pools.addBackend('pool-id', backendId: 'backend-id');
await cortex.pools.removeBackend('pool-id', 'backend-id');
```

---

### Backends

Backends are the actual inference servers — SGLang, vLLM, Ollama, or cloud providers.

**TypeScript:**

```typescript
// List all backends
const backends = await cortex.backends.list();

// Register a new backend
const backend = await cortex.backends.create({
  name: 'local-vllm',
  base_url: 'http://localhost:8000',
  provider: 'vllm',
  enabled: true,
});

// Update a backend
await cortex.backends.update('backend-id', { enabled: false });

// Delete a backend
await cortex.backends.delete('backend-id');

// Discover models available on a backend
const discovered = await cortex.backends.discover('backend-id');
for (const model of discovered.models) {
  console.log(`Found model: ${model.id}`);
}

// Rename a model's display name
await cortex.backends.updateModel('backend-id', 'model-id', {
  display_name: 'My Custom Name',
});
```

**Python:**

```python
# List backends
backends = client.backends.list()

# Register a backend
backend = client.backends.create(
    name="local-vllm",
    base_url="http://localhost:8000",
    provider="vllm",
    enabled=True,
)

# Discover models on a backend
discovered = client.backends.discover("backend-id")

# Update model display name
client.backends.update_model("backend-id", "model-id", display_name="My Custom Name")
```

**Dart:**

```dart
final backends = await cortex.backends.list();
final backend = await cortex.backends.create(
  name: 'local-vllm',
  baseUrl: 'http://localhost:8000',
  provider: 'vllm',
);
final discovered = await cortex.backends.discover('backend-id');
await cortex.backends.updateModel('backend-id', 'model-id', displayName: 'My Custom Name');
```

---

### Users (Admin)

Manage platform users, including an approval workflow for new signups.

**TypeScript:**

```typescript
// List all users
const users = await cortex.users.list();

// Check pending approvals
const pending = await cortex.users.pendingCount();
console.log(`${pending.count} users waiting for approval`);

// Update a user
await cortex.users.update('user-id', { role: 'admin' });

// Approve / reject a pending user
await cortex.users.approve('user-id');
await cortex.users.reject('user-id');

// Reset a user's password
await cortex.users.resetPassword('user-id');

// Delete a user
await cortex.users.delete('user-id');
```

**Python:**

```python
users = client.users.list()
pending = client.users.pending_count()
client.users.update("user-id", role="admin")
client.users.approve("user-id")
client.users.reject("user-id")
client.users.reset_password("user-id")
client.users.delete("user-id")
```

**Dart:**

```dart
final users = await cortex.users.list();
final pending = await cortex.users.pendingCount();
await cortex.users.approve('user-id');
await cortex.users.reject('user-id');
await cortex.users.resetPassword('user-id');
```

---

### Usage Limits (Admin)

Set per-user and per-team rate limits.

**TypeScript:**

```typescript
// List all usage limits
const limits = await cortex.usageLimits.list();

// Set limits for a user
await cortex.usageLimits.setForUser('user-id', {
  requests_per_minute: 60,
  requests_per_day: 10000,
  tokens_per_minute: 100000,
  tokens_per_day: 1000000,
});

// Remove limits
await cortex.usageLimits.removeForUser('user-id');
await cortex.usageLimits.removeForTeam('team-id');
```

**Python:**

```python
limits = client.usage_limits.list()
client.usage_limits.set_user_limits("user-id",
    requests_per_minute=60,
    requests_per_day=10000,
    tokens_per_minute=100000,
)
client.usage_limits.remove_user_limits("user-id")
client.usage_limits.remove_team_limits("team-id")
```

**Dart:**

```dart
final limits = await cortex.usageLimits.list();
await cortex.usageLimits.setUserLimits('user-id',
  requestsPerMinute: 60,
  requestsPerDay: 10000,
);
await cortex.usageLimits.removeUserLimits('user-id');
await cortex.usageLimits.removeTeamLimits('team-id');
```

---

### Admin API Keys

Manage admin-level API keys (separate from user keys). These have elevated permissions.

**TypeScript:**

```typescript
const keys = await cortex.adminKeys.list();
const newKey = await cortex.adminKeys.create({ name: 'CI/CD Pipeline' });
await cortex.adminKeys.update('key-id', { name: 'Renamed' });
await cortex.adminKeys.delete('key-id');

// Regenerate a key (invalidates the old one)
const regenerated = await cortex.adminKeys.regenerate('key-id');
console.log(`New key: ${regenerated.key}`);
```

**Python:**

```python
keys = client.admin_keys.list()
new_key = client.admin_keys.create(name="CI/CD Pipeline")
client.admin_keys.update("key-id", name="Renamed")
client.admin_keys.delete("key-id")
regenerated = client.admin_keys.regenerate("key-id")
```

**Dart:**

```dart
final keys = await cortex.adminKeys.list();
final newKey = await cortex.adminKeys.create(name: 'CI/CD Pipeline');
final regenerated = await cortex.adminKeys.regenerate('key-id');
```

---

### Audit Log

View a log of all administrative actions for compliance and security.

**TypeScript:**

```typescript
const log = await cortex.auditLog.list({ limit: 100 });
for (const entry of log.data) {
  console.log(`${entry.created_at}: ${entry.actor_email} ${entry.action} on ${entry.resource_type}/${entry.resource_id}`);
}
```

**Python:**

```python
log = client.audit_log.list(limit=100)
for entry in log.data:
    print(f"{entry.created_at}: {entry.actor_email} {entry.action}")
```

**Dart:**

```dart
final log = await cortex.auditLog.list(limit: 100);
for (final entry in log.data) {
  print('${entry.createdAt}: ${entry.actorEmail} ${entry.action}');
}
```

---

### Auth

Authentication endpoints for login, signup, and profile management.

**TypeScript:**

```typescript
// Login (returns a token)
const auth = await cortex.auth.login({
  email: 'user@example.com',
  password: 'secret',
});
console.log(`Token: ${auth.token}`);

// Signup
const signup = await cortex.auth.signup({
  email: 'new@example.com',
  password: 'secret',
  name: 'New User',
});

// Get current profile
const profile = await cortex.auth.me();

// Update profile
await cortex.auth.updateProfile({ name: 'Updated Name' });

// Change password
await cortex.auth.changePassword({
  current_password: 'old',
  new_password: 'new',
});
```

**Python:**

```python
auth = client.auth.login(email="user@example.com", password="secret")
profile = client.auth.me()
client.auth.update_profile(name="Updated Name")
client.auth.change_password(current_password="old", new_password="new")
```

**Dart:**

```dart
final auth = await cortex.auth.login(email: 'user@example.com', password: 'secret');
final profile = await cortex.auth.me();
await cortex.auth.updateProfile(name: 'Updated Name');
await cortex.auth.changePassword(currentPassword: 'old', newPassword: 'new');
```

---

### Audio Transcription

Transcribe audio files using Whisper. Supports multipart file upload.

**TypeScript:**

```typescript
import { readFileSync } from 'fs';

const transcription = await cortex.audio.transcribe({
  file: readFileSync('./recording.mp3'),
  model: 'whisper-1',
  language: 'en',
});

console.log(transcription.text);
console.log(`Duration: ${transcription.duration}s`);
```

**Python:**

```python
with open("recording.mp3", "rb") as f:
    transcription = client.audio.transcribe(
        file=f,
        model="whisper-1",
        language="en",
    )

print(transcription.text)
print(f"Duration: {transcription.duration}s")
```

**Dart:**

```dart
import 'dart:io';

final file = File('recording.mp3');
final transcription = await cortex.audio.transcribe(
  file: await file.readAsBytes(),
  fileName: 'recording.mp3',
  model: 'whisper-1',
  language: 'en',
);

print(transcription.text);
print('Duration: ${transcription.duration}s');
```

---

### Plugins

List available plugins on your Cortex instance.

**TypeScript:**

```typescript
const plugins = await cortex.plugins.list();
```

**Python:**

```python
plugins = client.plugins.list()
```

**Dart:**

```dart
final plugins = await cortex.plugins.list();
```

---

## Error Handling

All SDKs throw typed errors that you can catch and handle specifically.

### Error Types

| Error | HTTP Status | Description |
|---|---|---|
| `AuthenticationError` | 401 | Invalid or missing API key |
| `PermissionDeniedError` | 403 | Insufficient permissions |
| `NotFoundError` | 404 | Resource not found |
| `RateLimitError` | 429 | Rate limit exceeded (check `retryAfter`) |
| `ValidationError` | — | Invalid request parameters (client-side) |
| `ServerError` | 500+ | Internal server error |
| `TimeoutError` | — | Request timed out |
| `ConnectionError` | — | Network connectivity issue |

### TypeScript

```typescript
import {
  CortexError,
  AuthenticationError,
  RateLimitError,
  NotFoundError,
  TimeoutError,
} from '@nfinitmonkeys/cortex-sdk';

try {
  await cortex.chat.completions.create({ ... });
} catch (error) {
  if (error instanceof RateLimitError) {
    console.log(`Rate limited. Retry after ${error.retryAfter} seconds.`);
  } else if (error instanceof AuthenticationError) {
    console.log('Invalid API key. Check your configuration.');
  } else if (error instanceof NotFoundError) {
    console.log('Resource not found.');
  } else if (error instanceof TimeoutError) {
    console.log('Request timed out. Try again.');
  } else if (error instanceof CortexError) {
    console.log(`API error: ${error.message} (status: ${error.statusCode})`);
  }
}
```

### Python

```python
from cortex_sdk import CortexClient
from cortex_sdk.errors import (
    AuthenticationError,
    RateLimitError,
    NotFoundError,
    TimeoutError,
    CortexAPIError,
)

try:
    response = client.chat.completions.create(...)
except RateLimitError as e:
    print(f"Rate limited. Retry after {e.retry_after} seconds.")
except AuthenticationError:
    print("Invalid API key.")
except NotFoundError:
    print("Resource not found.")
except TimeoutError:
    print("Request timed out.")
except CortexAPIError as e:
    print(f"API error: {e.message} (status: {e.status_code})")
```

### Dart

```dart
import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';

try {
  await cortex.chat.completions.create(...);
} on CortexRateLimitException catch (e) {
  print('Rate limited. Retry after ${e.retryAfter} seconds.');
} on CortexAuthenticationException {
  print('Invalid API key.');
} on CortexNotFoundException {
  print('Resource not found.');
} on CortexTimeoutException {
  print('Request timed out.');
} on CortexException catch (e) {
  print('API error: ${e.message} (status: ${e.statusCode})');
}
```

---

## Retry & Resilience

All SDKs automatically retry failed requests with **exponential backoff and jitter**.

### What gets retried

| Status Code | Meaning | Retried? |
|---|---|---|
| 429 | Rate Limited | Yes (respects `Retry-After` header) |
| 500 | Internal Server Error | Yes |
| 502 | Bad Gateway | Yes |
| 503 | Service Unavailable | Yes |
| 504 | Gateway Timeout | Yes |
| Network errors | Connection refused, DNS failure, etc. | Yes |
| 400, 401, 403, 404 | Client errors | **No** (not retried) |

### Retry timing

- **Attempt 1**: Immediate
- **Attempt 2**: ~1 second (with jitter)
- **Attempt 3**: ~2 seconds (with jitter)
- **Attempt 4**: ~4 seconds (with jitter)

If the server sends a `Retry-After` header (common with 429), the SDK uses that value instead.

### Configuration

```typescript
// TypeScript
const cortex = new CortexClient({ apiKey: '...', maxRetries: 5 });
```

```python
# Python
client = CortexClient(api_key="...", max_retries=5)
```

```dart
// Dart
final cortex = CortexClient(apiKey: '...', maxRetries: 5);
```

Set `maxRetries: 0` to disable retries entirely.

---

## Security

### API Key Protection

- API keys are **never** included in error messages, stack traces, or `toString()` output
- Keys are masked in debug representations (e.g., `sk-cortex-...xxxx`)
- The client config is immutable after construction — keys cannot be changed or extracted

### HTTPS Enforcement

- All non-localhost URLs **must** use HTTPS
- HTTP URLs are rejected at client construction time
- `localhost` / `127.0.0.1` URLs are allowed for local development

### Header Injection Prevention

- API keys and custom headers are validated for newline characters (`\r`, `\n`)
- Prevents HTTP header injection attacks

### Request Timeouts

- Default: 30 seconds for regular requests
- Default: 300 seconds (5 minutes) for streaming requests
- Configurable per-client

### Input Validation

- All public methods validate required parameters before making HTTP calls
- Invalid types, missing fields, and out-of-range values are caught early with descriptive error messages

---

## Publishing Status

| SDK | Package Name | Install Command | Status |
|---|---|---|---|
| TypeScript | `@nfinitmonkeys/cortex-sdk` | `npm install @nfinitmonkeys/cortex-sdk` | Published v1.1.0 |
| Python | `nfinitmonkeys-cortex-sdk` | `pip install nfinitmonkeys-cortex-sdk` | Published v1.1.0 |
| Dart | `nfinitmonkeys_cortex_sdk` | `nfinitmonkeys_cortex_sdk: ^1.0.0` in pubspec.yaml | Published v1.0.0 |

---

## License

MIT — Copyright (c) 2026 InfiniteMonkeys
