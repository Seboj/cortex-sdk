import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('iris', () => {
  describe('extract', () => {
    it('extracts structured data', async () => {
      const mockResponse = {
        id: 'job-1',
        status: 'completed',
        result: { name: 'John Doe', age: 30 },
        createdAt: '2024-01-01',
        completedAt: '2024-01-01',
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.iris.extract({
        document: 'John Doe is 30 years old.',
        schema: { name: 'string', age: 'number' },
      });

      expect(result.status).toBe('completed');
      expect(result.result).toEqual({ name: 'John Doe', age: 30 });

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/iris/extract');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when document is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(
        client.iris.extract({ document: '', schema: 'test' }),
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when schema is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(
        client.iris.extract({ document: 'doc', schema: '' }),
      ).rejects.toThrow(ValidationError);
    });
  });

  describe('jobs', () => {
    it('lists jobs', async () => {
      const mockResponse = [
        { id: 'job-1', status: 'completed', createdAt: '2024-01-01' },
        { id: 'job-2', status: 'processing', createdAt: '2024-01-02' },
      ];
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.iris.jobs();
      expect(result).toHaveLength(2);

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/iris/jobs');
    });

    it('passes limit param', async () => {
      const fetch = mockFetch([]);
      const client = createClient(fetch);

      await client.iris.jobs({ limit: 5 });

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toContain('limit=5');
    });
  });

  describe('schemas', () => {
    it('lists schemas', async () => {
      const mockResponse = [
        { id: 's-1', name: 'Person', schema: { name: 'string' }, createdAt: '2024-01-01', updatedAt: '2024-01-01' },
      ];
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.iris.schemas();
      expect(result).toHaveLength(1);
      expect(result[0]!.name).toBe('Person');

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/iris/schemas');
    });
  });
});
