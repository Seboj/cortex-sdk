import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('adminKeys', () => {
  describe('list', () => {
    it('lists admin API keys', async () => {
      const mockResponse = {
        keys: [{ id: 'ak-1', name: 'Admin Key', key: 'sk-admin-***', createdAt: '2024-01-01' }],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.adminKeys.list();

      expect(result.keys).toHaveLength(1);
      expect(result.keys[0]!.name).toBe('Admin Key');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/api-keys');
      expect(opts.method).toBe('GET');
    });
  });

  describe('create', () => {
    it('creates an admin API key', async () => {
      const mockResponse = { id: 'ak-2', name: 'New Admin Key', key: 'sk-admin-new', createdAt: '2024-01-15' };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.adminKeys.create({ name: 'New Admin Key' });

      expect(result.id).toBe('ak-2');
      expect(result.name).toBe('New Admin Key');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/api-keys');
      expect(opts.method).toBe('POST');
      expect(JSON.parse(opts.body as string)).toEqual({ name: 'New Admin Key' });
    });

    it('throws ValidationError when name is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.adminKeys.create({ name: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('update', () => {
    it('updates an admin API key', async () => {
      const fetch = mockFetch({ id: 'ak-1', name: 'Updated Key', key: 'sk-admin-***', createdAt: '2024-01-01' });
      const client = createClient(fetch);

      const result = await client.adminKeys.update('ak-1', { name: 'Updated Key' });

      expect(result.name).toBe('Updated Key');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/api-keys/ak-1');
      expect(opts.method).toBe('PATCH');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.adminKeys.update('', { name: 'x' })).rejects.toThrow(ValidationError);
    });
  });

  describe('delete', () => {
    it('revokes an admin API key', async () => {
      const fetch = mockFetch({ id: 'ak-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.adminKeys.delete('ak-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/api-keys/ak-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.adminKeys.delete('')).rejects.toThrow(ValidationError);
    });
  });

  describe('regenerate', () => {
    it('regenerates an admin API key', async () => {
      const fetch = mockFetch({ id: 'ak-1', key: 'sk-admin-regenerated' });
      const client = createClient(fetch);

      const result = await client.adminKeys.regenerate('ak-1');

      expect(result.key).toBe('sk-admin-regenerated');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/api-keys/ak-1/regenerate');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.adminKeys.regenerate('')).rejects.toThrow(ValidationError);
    });
  });
});
