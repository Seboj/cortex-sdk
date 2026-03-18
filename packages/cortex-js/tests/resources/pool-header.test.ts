import { describe, it, expect } from 'vitest';
import { mockFetch } from '../helpers.js';
import { CortexClient } from '../../src/client.js';

const MOCK_CHAT_RESPONSE = {
  id: 'chatcmpl-abc123',
  object: 'chat.completion',
  created: 1700000000,
  model: 'gpt-4',
  choices: [
    {
      index: 0,
      message: { role: 'assistant', content: 'Hello!' },
      finish_reason: 'stop',
    },
  ],
  usage: { prompt_tokens: 10, completion_tokens: 3, total_tokens: 13 },
};

const MOCK_COMPLETION_RESPONSE = {
  id: 'cmpl-abc123',
  object: 'text_completion',
  created: 1700000000,
  model: 'gpt-4',
  choices: [{ index: 0, text: 'World', finish_reason: 'stop' }],
  usage: { prompt_tokens: 5, completion_tokens: 3, total_tokens: 8 },
};

const MOCK_EMBEDDING_RESPONSE = {
  object: 'list',
  data: [{ object: 'embedding', embedding: [0.1, 0.2], index: 0 }],
  model: 'text-embedding-ada-002',
  usage: { prompt_tokens: 5, total_tokens: 5 },
};

function createClientWithPool(
  fetchFn: ReturnType<typeof import('vitest').vi.fn>,
  defaultPool?: string,
): CortexClient {
  return new CortexClient({
    apiKey: 'sk-cortex-test-key-12345',
    llmBaseUrl: 'https://api.test.com/v1',
    adminBaseUrl: 'https://admin.test.com',
    fetch: fetchFn as unknown as typeof globalThis.fetch,
    maxRetries: 0,
    defaultPool,
  });
}

describe('x-cortex-pool header', () => {
  describe('chat.completions', () => {
    it('sends x-cortex-pool header when pool is specified per-request', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClientWithPool(fetch);

      await client.chat.completions.create(
        { model: 'gpt-4', messages: [{ role: 'user', content: 'Hello' }] },
        { pool: 'cortexvlm' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortexvlm');
    });

    it('sends x-cortex-pool from client defaultPool', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClientWithPool(fetch, 'cortex-stt');

      await client.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }],
      });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortex-stt');
    });

    it('per-request pool overrides client defaultPool', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClientWithPool(fetch, 'default');

      await client.chat.completions.create(
        { model: 'gpt-4', messages: [{ role: 'user', content: 'Hello' }] },
        { pool: 'cortexvlm' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortexvlm');
    });

    it('no x-cortex-pool header when neither pool nor defaultPool set', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClientWithPool(fetch);

      await client.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }],
      });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBeUndefined();
    });
  });

  describe('model is optional', () => {
    it('chat.completions.create works without model', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClientWithPool(fetch, 'cortexvlm');

      await client.chat.completions.create({
        messages: [{ role: 'user', content: 'Hello' }],
      });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      const body = JSON.parse(opts.body as string);
      expect(body.model).toBeUndefined();
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortexvlm');
    });

    it('completions.create works without model', async () => {
      const fetch = mockFetch(MOCK_COMPLETION_RESPONSE);
      const client = createClientWithPool(fetch);

      await client.completions.create(
        { prompt: 'Hello' },
        { pool: 'default' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      const body = JSON.parse(opts.body as string);
      expect(body.model).toBeUndefined();
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('default');
    });

    it('embeddings.create works without model', async () => {
      const fetch = mockFetch(MOCK_EMBEDDING_RESPONSE);
      const client = createClientWithPool(fetch);

      await client.embeddings.create(
        { input: 'Hello' },
        { pool: 'default' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      const body = JSON.parse(opts.body as string);
      expect(body.model).toBeUndefined();
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('default');
    });
  });

  describe('completions pool header', () => {
    it('sends x-cortex-pool when pool specified', async () => {
      const fetch = mockFetch(MOCK_COMPLETION_RESPONSE);
      const client = createClientWithPool(fetch);

      await client.completions.create(
        { model: 'gpt-4', prompt: 'Hello' },
        { pool: 'cortex-stt' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortex-stt');
    });
  });

  describe('embeddings pool header', () => {
    it('sends x-cortex-pool when pool specified', async () => {
      const fetch = mockFetch(MOCK_EMBEDDING_RESPONSE);
      const client = createClientWithPool(fetch);

      await client.embeddings.create(
        { model: 'text-embedding-ada-002', input: 'Hello' },
        { pool: 'cortexvlm' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortexvlm');
    });
  });

  describe('audio pool header', () => {
    it('sends x-cortex-pool when pool specified', async () => {
      const fetch = mockFetch({ text: 'Hello world!' });
      const client = createClientWithPool(fetch);

      const file = new Blob(['audio-data'], { type: 'audio/wav' });
      await client.audio.transcribe(
        { file, model: 'whisper-1' },
        { pool: 'cortex-stt-diarize' },
      );

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortex-stt-diarize');
    });

    it('audio.transcribe works without model', async () => {
      const fetch = mockFetch({ text: 'Hello world!' });
      const client = createClientWithPool(fetch, 'cortex-stt');

      const file = new Blob(['audio-data'], { type: 'audio/wav' });
      await client.audio.transcribe({ file });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      const formData = opts.body as FormData;
      expect(formData.get('model')).toBeNull();
      expect((opts.headers as Record<string, string>)['x-cortex-pool']).toBe('cortex-stt');
    });
  });
});
