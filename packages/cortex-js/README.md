# @Seboj/cortex-sdk

Official TypeScript SDK for the Cortex LLM Gateway API.

## Installation

```bash
npm install @Seboj/cortex-sdk
```

Requires Node.js 18+ (uses native `fetch`).

## Quick Start

```typescript
import { CortexClient } from '@Seboj/cortex-sdk';

const cortex = new CortexClient({ apiKey: 'sk-cortex-...' });

// Chat completion
const response = await cortex.chat.completions.create({
  model: 'default',
  messages: [{ role: 'user', content: 'Hello!' }],
});
console.log(response.choices[0].message.content);
```

## Configuration

```typescript
const cortex = new CortexClient({
  apiKey: 'sk-cortex-...',               // Required
  llmBaseUrl: 'https://custom-api.com/v1', // Default: https://cortexapi.nfinitmonkeys.com/v1
  adminBaseUrl: 'https://custom-admin.com', // Default: https://admin.nfinitmonkeys.com
  timeout: 30000,                          // Request timeout (ms), default: 30000
  streamTimeout: 300000,                   // Streaming timeout (ms), default: 300000
  maxRetries: 3,                           // Retry count, default: 3
  defaultHeaders: { 'X-Custom': 'value' }, // Extra headers on every request
});
```

## LLM Gateway

### Chat Completions

```typescript
// Non-streaming
const chat = await cortex.chat.completions.create({
  model: 'gpt-4',
  messages: [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'What is TypeScript?' },
  ],
  temperature: 0.7,
  max_tokens: 500,
});

// Streaming
const stream = await cortex.chat.completions.create({
  model: 'gpt-4',
  messages: [{ role: 'user', content: 'Tell me a story' }],
  stream: true,
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? '');
}

// Collect streamed text
const text = await stream.toText();
```

### Text Completions

```typescript
const completion = await cortex.completions.create({
  model: 'gpt-3.5-turbo-instruct',
  prompt: 'Once upon a time',
  max_tokens: 100,
});
```

### Embeddings

```typescript
const embeddings = await cortex.embeddings.create({
  model: 'text-embedding-ada-002',
  input: 'The quick brown fox',
});
```

### Models

```typescript
const models = await cortex.models.list();
```

## Admin / Platform API

### API Keys

```typescript
const keys = await cortex.keys.list();
const newKey = await cortex.keys.create({ name: 'Production Key' });
await cortex.keys.delete('key-id');
```

### Teams

```typescript
const teams = await cortex.teams.list();
const team = await cortex.teams.create({ name: 'Engineering' });
const details = await cortex.teams.get('team-id');
await cortex.teams.delete('team-id');

// Members
await cortex.teams.members.add('team-id', { userId: 'user-id', role: 'member' });
await cortex.teams.members.update('team-id', 'member-id', { role: 'admin' });
await cortex.teams.members.remove('team-id', 'member-id');
```

### Usage & Performance

```typescript
const usage = await cortex.usage.get({ startDate: '2024-01-01', granularity: 'daily' });
const limits = await cortex.usage.limits();
const perf = await cortex.performance.get();
```

### Conversations

```typescript
const convos = await cortex.conversations.list({ limit: 10 });
const convo = await cortex.conversations.create({ title: 'New Chat' });
const details = await cortex.conversations.get('conv-id');
await cortex.conversations.update('conv-id', { title: 'Renamed' });
await cortex.conversations.delete('conv-id');

// Stream messages (SSE)
const msgStream = await cortex.conversations.messages('conv-id');
for await (const chunk of msgStream) {
  console.log(chunk);
}
```

### Iris (Document Extraction)

```typescript
const result = await cortex.iris.extract({
  document: 'John Doe, age 30, lives in NYC.',
  schema: { name: 'string', age: 'number', city: 'string' },
});

const jobs = await cortex.iris.jobs({ limit: 10 });
const schemas = await cortex.iris.schemas();
```

### Plugins, PDF, Web Search

```typescript
const plugins = await cortex.plugins.list();

const pdf = await cortex.pdf.generate({ content: '# Report\nContent here.' });

const results = await cortex.webSearch.search({ query: 'TypeScript best practices' });
```

## Error Handling

All errors extend `CortexError`:

```typescript
import {
  CortexError,
  AuthenticationError,
  RateLimitError,
  ValidationError,
  TimeoutError,
  ConnectionError,
  NotFoundError,
  ServerError,
} from '@Seboj/cortex-sdk';

try {
  await cortex.chat.completions.create({ ... });
} catch (error) {
  if (error instanceof RateLimitError) {
    console.log(`Rate limited. Retry after ${error.retryAfter}s`);
  } else if (error instanceof AuthenticationError) {
    console.log('Invalid API key');
  } else if (error instanceof ValidationError) {
    console.log(`Validation failed on field: ${error.field}`);
  } else if (error instanceof TimeoutError) {
    console.log('Request timed out');
  }
}
```

API keys are never exposed in error messages or stack traces.

## Cancellation

Use `AbortController` to cancel requests:

```typescript
const controller = new AbortController();

setTimeout(() => controller.abort(), 5000);

const response = await cortex.chat.completions.create(
  { model: 'gpt-4', messages: [{ role: 'user', content: 'Hello' }] },
  { signal: controller.signal },
);
```

## Retry Behavior

The SDK automatically retries on status codes 429, 500, 502, 503, 504 with exponential backoff and jitter. It respects `Retry-After` headers. Configure with `maxRetries` (default: 3).

## Development

```bash
npm install
npm run build
npm test
```

## License

MIT
