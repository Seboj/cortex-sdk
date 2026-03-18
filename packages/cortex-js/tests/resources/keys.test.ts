import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('keys', () => {
  describe('list', () => {
    it('lists API keys', async () => {
      const mockResponse = {
        keys: [
          { id: 'key-1', name: 'Test Key', key: 'sk-cortex-***', createdAt: '2024-01-01' },
        ],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.keys.list();

      expect(result.keys).toHaveLength(1);
      expect(result.keys[0]!.name).toBe('Test Key');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/keys');
      expect(opts.method).toBe('GET');
    });
  });

  describe('create', () => {
    it('creates an API key', async () => {
      const mockResponse = {
        id: 'key-2',
        name: 'New Key',
        key: 'sk-cortex-newkey123',
        createdAt: '2024-01-15',
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.keys.create({ name: 'New Key' });

      expect(result.id).toBe('key-2');
      expect(result.name).toBe('New Key');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/keys');
      expect(opts.method).toBe('POST');
      expect(JSON.parse(opts.body as string)).toEqual({ name: 'New Key' });
    });

    it('throws ValidationError when name is missing', async () => {
      const client = createClient(mockFetch({}));

      await expect(client.keys.create({ name: '' })).rejects.toThrow(ValidationError);
    });

    it('passes scopes and expiresAt', async () => {
      const fetch = mockFetch({ id: 'key-3', name: 'Scoped', key: 'sk-cortex-x', createdAt: '2024-01-01' });
      const client = createClient(fetch);

      await client.keys.create({
        name: 'Scoped',
        scopes: ['chat', 'embeddings'],
        expiresAt: '2025-01-01',
      });

      const body = JSON.parse((fetch.mock.calls[0] as [string, RequestInit])[1].body as string);
      expect(body.scopes).toEqual(['chat', 'embeddings']);
      expect(body.expiresAt).toBe('2025-01-01');
    });
  });

  describe('delete', () => {
    it('deletes an API key', async () => {
      const fetch = mockFetch({ id: 'key-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.keys.delete('key-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/keys/key-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));

      await expect(client.keys.delete('')).rejects.toThrow(ValidationError);
    });

    it('encodes special characters in id', async () => {
      const fetch = mockFetch({ id: 'key/special', deleted: true });
      const client = createClient(fetch);

      await client.keys.delete('key/special');

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/keys/key%2Fspecial');
    });
  });
});
