import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('pools', () => {
  describe('list', () => {
    it('lists all pools', async () => {
      const mockResponse = {
        pools: [{ id: 'pool-1', name: 'Default', createdAt: '2024-01-01', updatedAt: '2024-01-01' }],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.pools.list();

      expect(result.pools).toHaveLength(1);
      expect(result.pools[0]!.name).toBe('Default');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/pools');
      expect(opts.method).toBe('GET');
    });
  });

  describe('create', () => {
    it('creates a pool', async () => {
      const mockResponse = { id: 'pool-2', name: 'New Pool', createdAt: '2024-01-01', updatedAt: '2024-01-01' };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.pools.create({ name: 'New Pool' });

      expect(result.id).toBe('pool-2');
      expect(result.name).toBe('New Pool');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/pools');
      expect(opts.method).toBe('POST');
      expect(JSON.parse(opts.body as string)).toEqual({ name: 'New Pool' });
    });

    it('throws ValidationError when name is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.create({ name: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('update', () => {
    it('updates a pool', async () => {
      const fetch = mockFetch({ id: 'pool-1', name: 'Updated', createdAt: '2024-01-01', updatedAt: '2024-01-02' });
      const client = createClient(fetch);

      const result = await client.pools.update('pool-1', { name: 'Updated' });

      expect(result.name).toBe('Updated');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/pools/pool-1');
      expect(opts.method).toBe('PATCH');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.update('', { name: 'x' })).rejects.toThrow(ValidationError);
    });
  });

  describe('delete', () => {
    it('deletes a pool', async () => {
      const fetch = mockFetch({ id: 'pool-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.pools.delete('pool-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/pools/pool-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.delete('')).rejects.toThrow(ValidationError);
    });
  });

  describe('addBackend', () => {
    it('adds a backend to a pool', async () => {
      const fetch = mockFetch({ id: 'pb-1', backendId: 'b-1', priority: 1 });
      const client = createClient(fetch);

      const result = await client.pools.addBackend('pool-1', { backendId: 'b-1', priority: 1 });

      expect(result.backendId).toBe('b-1');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/pools/pool-1/backends');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when poolId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.addBackend('', { backendId: 'b-1' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when backendId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.addBackend('pool-1', { backendId: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('removeBackend', () => {
    it('removes a backend from a pool', async () => {
      const fetch = mockFetch({ id: 'b-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.pools.removeBackend('pool-1', 'b-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/pools/pool-1/backends/b-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when poolId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.removeBackend('', 'b-1')).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when backendId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.pools.removeBackend('pool-1', '')).rejects.toThrow(ValidationError);
    });
  });
});
