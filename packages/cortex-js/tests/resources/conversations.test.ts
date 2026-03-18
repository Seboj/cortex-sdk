import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, mockStreamFetch, createClient } from '../helpers.js';

describe('conversations', () => {
  describe('list', () => {
    it('lists conversations', async () => {
      const fetch = mockFetch({
        conversations: [
          { id: 'conv-1', title: 'Chat 1', createdAt: '2024-01-01', updatedAt: '2024-01-01' },
        ],
        total: 1,
      });
      const client = createClient(fetch);

      const result = await client.conversations.list();
      expect(result.conversations).toHaveLength(1);
      expect(result.total).toBe(1);

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/conversations');
    });

    it('passes pagination params', async () => {
      const fetch = mockFetch({ conversations: [], total: 0 });
      const client = createClient(fetch);

      await client.conversations.list({ limit: 10, offset: 20 });

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toContain('limit=10');
      expect(url).toContain('offset=20');
    });
  });

  describe('create', () => {
    it('creates a conversation', async () => {
      const fetch = mockFetch({
        id: 'conv-2',
        title: 'New Chat',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
      });
      const client = createClient(fetch);

      const result = await client.conversations.create({ title: 'New Chat', model: 'gpt-4' });
      expect(result.id).toBe('conv-2');
      expect(result.title).toBe('New Chat');
    });
  });

  describe('get', () => {
    it('gets a conversation', async () => {
      const fetch = mockFetch({
        id: 'conv-1',
        title: 'Chat 1',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
      });
      const client = createClient(fetch);

      const result = await client.conversations.get('conv-1');
      expect(result.id).toBe('conv-1');

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/conversations/conv-1');
    });

    it('throws ValidationError when id is empty', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.conversations.get('')).rejects.toThrow(ValidationError);
    });
  });

  describe('update', () => {
    it('updates a conversation', async () => {
      const fetch = mockFetch({
        id: 'conv-1',
        title: 'Updated Title',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-02',
      });
      const client = createClient(fetch);

      const result = await client.conversations.update('conv-1', { title: 'Updated Title' });
      expect(result.title).toBe('Updated Title');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/conversations/conv-1');
      expect(opts.method).toBe('PATCH');
    });
  });

  describe('delete', () => {
    it('deletes a conversation', async () => {
      const fetch = mockFetch({ id: 'conv-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.conversations.delete('conv-1');
      expect(result.deleted).toBe(true);

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(opts.method).toBe('DELETE');
    });
  });

  describe('messages', () => {
    it('streams messages', async () => {
      const chunk = JSON.stringify({
        id: 'msg-1',
        object: 'chat.completion.chunk',
        created: 1700000000,
        model: 'gpt-4',
        choices: [{ index: 0, delta: { content: 'Hello' }, finish_reason: null }],
      });

      const fetch = mockStreamFetch([`data: ${chunk}\n\ndata: [DONE]\n\n`]);
      const client = createClient(fetch);

      const stream = await client.conversations.messages('conv-1');
      const chunks = [];
      for await (const c of stream) {
        chunks.push(c);
      }
      expect(chunks).toHaveLength(1);

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/conversations/conv-1/messages');
    });

    it('throws ValidationError when id is empty', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.conversations.messages('')).rejects.toThrow(ValidationError);
    });
  });
});
