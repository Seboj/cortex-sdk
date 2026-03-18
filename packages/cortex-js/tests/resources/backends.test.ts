import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('backends', () => {
  describe('list', () => {
    it('lists all backends', async () => {
      const mockResponse = {
        backends: [{ id: 'b-1', name: 'OpenAI', url: 'https://api.openai.com', createdAt: '2024-01-01', updatedAt: '2024-01-01' }],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.backends.list();

      expect(result.backends).toHaveLength(1);
      expect(result.backends[0]!.name).toBe('OpenAI');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/backends');
      expect(opts.method).toBe('GET');
    });
  });

  describe('create', () => {
    it('registers a backend', async () => {
      const mockResponse = { id: 'b-2', name: 'Anthropic', url: 'https://api.anthropic.com', createdAt: '2024-01-01', updatedAt: '2024-01-01' };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.backends.create({ name: 'Anthropic', url: 'https://api.anthropic.com' });

      expect(result.name).toBe('Anthropic');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/backends');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when name is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.create({ name: '', url: 'https://x.com' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when url is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.create({ name: 'Test', url: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('update', () => {
    it('updates a backend', async () => {
      const fetch = mockFetch({ id: 'b-1', name: 'Updated', url: 'https://x.com', createdAt: '2024-01-01', updatedAt: '2024-01-02' });
      const client = createClient(fetch);

      const result = await client.backends.update('b-1', { name: 'Updated' });

      expect(result.name).toBe('Updated');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/backends/b-1');
      expect(opts.method).toBe('PATCH');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.update('', { name: 'x' })).rejects.toThrow(ValidationError);
    });
  });

  describe('delete', () => {
    it('removes a backend', async () => {
      const fetch = mockFetch({ id: 'b-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.backends.delete('b-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/backends/b-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.delete('')).rejects.toThrow(ValidationError);
    });
  });

  describe('discover', () => {
    it('discovers models on a backend', async () => {
      const fetch = mockFetch({ models: [{ id: 'm-1', name: 'gpt-4' }] });
      const client = createClient(fetch);

      const result = await client.backends.discover('b-1');

      expect(result.models).toHaveLength(1);
      expect(result.models[0]!.name).toBe('gpt-4');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/backends/b-1/discover');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.discover('')).rejects.toThrow(ValidationError);
    });
  });

  describe('updateModel', () => {
    it('updates a model display name', async () => {
      const fetch = mockFetch({ id: 'm-1', name: 'gpt-4', displayName: 'GPT-4 Turbo' });
      const client = createClient(fetch);

      const result = await client.backends.updateModel('b-1', 'm-1', { displayName: 'GPT-4 Turbo' });

      expect(result.displayName).toBe('GPT-4 Turbo');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/backends/b-1/models/m-1');
      expect(opts.method).toBe('PATCH');
    });

    it('throws ValidationError when backendId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.updateModel('', 'm-1', { displayName: 'x' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when modelId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.updateModel('b-1', '', { displayName: 'x' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when displayName is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.backends.updateModel('b-1', 'm-1', { displayName: '' })).rejects.toThrow(ValidationError);
    });
  });
});
