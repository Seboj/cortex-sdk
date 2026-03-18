import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, mockStreamFetch, createClient } from '../helpers.js';

const MOCK_CHAT_RESPONSE = {
  id: 'chatcmpl-abc123',
  object: 'chat.completion',
  created: 1700000000,
  model: 'gpt-4',
  choices: [
    {
      index: 0,
      message: { role: 'assistant', content: 'Hello! How can I help you?' },
      finish_reason: 'stop',
    },
  ],
  usage: { prompt_tokens: 10, completion_tokens: 8, total_tokens: 18 },
};

describe('chat.completions', () => {
  describe('create (non-streaming)', () => {
    it('sends a chat completion request', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClient(fetch);

      const result = await client.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }],
      });

      expect(result.id).toBe('chatcmpl-abc123');
      expect(result.choices[0]!.message.content).toBe('Hello! How can I help you?');
      expect(result.usage!.total_tokens).toBe(18);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://api.test.com/v1/chat/completions');
      expect(opts.method).toBe('POST');
      expect(JSON.parse(opts.body as string)).toEqual({
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }],
      });
    });

    it('sends all optional parameters', async () => {
      const fetch = mockFetch(MOCK_CHAT_RESPONSE);
      const client = createClient(fetch);

      await client.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hello' }],
        temperature: 0.7,
        max_tokens: 100,
        top_p: 0.9,
        stop: ['\n'],
        presence_penalty: 0.5,
        frequency_penalty: 0.5,
        user: 'user-123',
      });

      const body = JSON.parse((fetch.mock.calls[0] as [string, RequestInit])[1].body as string);
      expect(body.temperature).toBe(0.7);
      expect(body.max_tokens).toBe(100);
      expect(body.top_p).toBe(0.9);
      expect(body.stop).toEqual(['\n']);
    });

    it('throws ValidationError when model is missing', async () => {
      const client = createClient(mockFetch({}));

      await expect(
        client.chat.completions.create({
          model: '',
          messages: [{ role: 'user', content: 'Hello' }],
        }),
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when messages is empty', async () => {
      const client = createClient(mockFetch({}));

      await expect(
        client.chat.completions.create({
          model: 'gpt-4',
          messages: [],
        }),
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when message has no role', async () => {
      const client = createClient(mockFetch({}));

      await expect(
        client.chat.completions.create({
          model: 'gpt-4',
          messages: [{ role: '' as 'user', content: 'Hello' }],
        }),
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when temperature is out of range', async () => {
      const client = createClient(mockFetch({}));

      await expect(
        client.chat.completions.create({
          model: 'gpt-4',
          messages: [{ role: 'user', content: 'Hello' }],
          temperature: 3,
        }),
      ).rejects.toThrow(ValidationError);

      await expect(
        client.chat.completions.create({
          model: 'gpt-4',
          messages: [{ role: 'user', content: 'Hello' }],
          temperature: -1,
        }),
      ).rejects.toThrow(ValidationError);
    });
  });

  describe('create (streaming)', () => {
    it('returns an SSE stream', async () => {
      const chunk = JSON.stringify({
        id: 'chatcmpl-1',
        object: 'chat.completion.chunk',
        created: 1700000000,
        model: 'gpt-4',
        choices: [{ index: 0, delta: { content: 'Hello' }, finish_reason: null }],
      });

      const fetch = mockStreamFetch([`data: ${chunk}\n\ndata: [DONE]\n\n`]);
      const client = createClient(fetch);

      const stream = await client.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: 'Hi' }],
        stream: true,
      });

      const chunks = [];
      for await (const c of stream) {
        chunks.push(c);
      }

      expect(chunks).toHaveLength(1);
      expect(chunks[0]!.choices[0]!.delta.content).toBe('Hello');

      // Verify Accept header was set for streaming
      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['Accept']).toBe('text/event-stream');
    });
  });
});
