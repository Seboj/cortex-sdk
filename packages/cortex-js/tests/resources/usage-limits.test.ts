import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('usageLimits', () => {
  describe('list', () => {
    it('lists all usage limits', async () => {
      const mockResponse = {
        limits: [{ id: 'ul-1', entityType: 'user', entityId: 'u-1', requestsPerDay: 1000 }],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.usageLimits.list();

      expect(result.limits).toHaveLength(1);
      expect(result.limits[0]!.entityType).toBe('user');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/usage-limits');
      expect(opts.method).toBe('GET');
    });
  });

  describe('setForUser', () => {
    it('sets usage limits for a user', async () => {
      const mockResponse = { id: 'ul-1', entityType: 'user', entityId: 'u-1', requestsPerDay: 500 };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.usageLimits.setForUser('u-1', { requestsPerDay: 500 });

      expect(result.requestsPerDay).toBe(500);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/usage-limits/user/u-1');
      expect(opts.method).toBe('PUT');
    });

    it('throws ValidationError when userId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.usageLimits.setForUser('', { requestsPerDay: 100 })).rejects.toThrow(ValidationError);
    });
  });

  describe('removeForUser', () => {
    it('removes usage limits for a user', async () => {
      const fetch = mockFetch({ id: 'u-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.usageLimits.removeForUser('u-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/usage-limits/user/u-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when userId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.usageLimits.removeForUser('')).rejects.toThrow(ValidationError);
    });
  });

  describe('removeForTeam', () => {
    it('removes usage limits for a team', async () => {
      const fetch = mockFetch({ id: 't-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.usageLimits.removeForTeam('t-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/usage-limits/team/t-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when teamId is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.usageLimits.removeForTeam('')).rejects.toThrow(ValidationError);
    });
  });
});
