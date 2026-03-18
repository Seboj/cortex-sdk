# Cortex Python SDK

Python client for the Cortex LLM Gateway and Admin API.

## Installation

```bash
pip install cortex-sdk
```

## Quick Start

```python
from cortex_sdk import CortexClient

client = CortexClient(api_key="sk-cortex-...")

# Chat completions
response = client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Hello!"}],
)
print(response.choices[0].message.content)

client.close()
```

## Async Usage

```python
import asyncio
from cortex_sdk import AsyncCortexClient

async def main():
    async with AsyncCortexClient(api_key="sk-cortex-...") as client:
        response = await client.chat.completions.create(
            model="default",
            messages=[{"role": "user", "content": "Hello!"}],
        )
        print(response.choices[0].message.content)

asyncio.run(main())
```

## Streaming

```python
# Sync streaming
stream = client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True,
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")

# Async streaming
stream = await async_client.chat.completions.create(
    model="default",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True,
)
async for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

## Configuration

```python
client = CortexClient(
    api_key="sk-cortex-...",
    llm_base_url="https://cortexapi.nfinitmonkeys.com/v1",   # LLM gateway
    admin_base_url="https://admin.nfinitmonkeys.com",         # Admin API
    timeout=30.0,               # Request timeout (seconds)
    streaming_timeout=300.0,    # Streaming timeout (seconds)
    max_retries=3,              # Retry count for transient errors
    extra_headers={"X-Custom": "value"},
)
```

## LLM Gateway

### Chat Completions

```python
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is Python?"},
    ],
    temperature=0.7,
    max_tokens=500,
)
```

### Text Completions

```python
response = client.completions.create(
    model="gpt-3.5-turbo-instruct",
    prompt="Once upon a time",
    max_tokens=100,
)
print(response.choices[0].text)
```

### Embeddings

```python
response = client.embeddings.create(
    model="text-embedding-ada-002",
    input="Hello world",
)
print(response.data[0].embedding)
```

### Models

```python
models = client.models.list()
for model in models.data:
    print(model.id)
```

## Admin API

### API Keys

```python
# List keys
keys = client.keys.list()

# Create key
key = client.keys.create(name="Production", scopes=["chat", "embeddings"])

# Delete key
client.keys.delete("key-id")
```

### Teams

```python
# List / create / get / delete teams
teams = client.teams.list()
team = client.teams.create(name="Engineering")
team = client.teams.get("team-id")
client.teams.delete("team-id")

# Members
member = client.teams.add_member("team-id", email="alice@example.com", role="admin")
client.teams.update_member("team-id", "member-id", role="viewer")
client.teams.remove_member("team-id", "member-id")
```

### Usage & Performance

```python
stats = client.usage.get(params={"start_date": "2024-01-01"})
limits = client.usage.limits()
metrics = client.performance.get()
```

### Conversations

```python
convos = client.conversations.list()
convo = client.conversations.create(title="My Chat", model="gpt-4")
convo = client.conversations.get("conv-id")
convo = client.conversations.update("conv-id", title="New Title")
client.conversations.delete("conv-id")

# Stream messages (SSE)
for msg in client.conversations.messages("conv-id"):
    print(msg.content)
```

### Iris (Document Extraction)

```python
job = client.iris.extract(
    document_url="https://example.com/invoice.pdf",
    schema_id="invoice-schema",
)
jobs = client.iris.list_jobs(limit=10)
schemas = client.iris.list_schemas()
```

### Other Resources

```python
# Plugins & Optimizations
plugins = client.plugins.list()
opts = client.optimizations.get()

# Admin models config
models = client.admin_models.list()

# PDF generation
pdf = client.pdf.generate(content="# Report", template="default")

# Web search
results = client.web_search.search(query="Python programming", num_results=5)
```

## Error Handling

```python
from cortex_sdk import (
    CortexError,
    AuthenticationError,
    RateLimitError,
    NotFoundError,
    InternalServerError,
)

try:
    response = client.chat.completions.create(...)
except AuthenticationError:
    print("Invalid API key")
except RateLimitError as e:
    print(f"Rate limited. Retry after {e.retry_after}s")
except NotFoundError:
    print("Resource not found")
except InternalServerError:
    print("Server error — will be retried automatically")
except CortexError as e:
    print(f"SDK error: {e.message}")
```

## Retry Behavior

The SDK automatically retries on HTTP 429, 500, 502, 503, and 504 with exponential backoff and jitter. The `Retry-After` header is respected when present. Configure with `max_retries` (default: 3).

## Development

```bash
pip install -e ".[dev]"
pytest
```

## License

MIT
