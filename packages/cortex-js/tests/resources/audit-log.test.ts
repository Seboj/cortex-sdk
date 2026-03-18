import { describe, it, expect } from 'vitest';
import { mockFetch, createClient } from '../helpers.js';

describe('auditLog', () => {
  describe('list', () => {
    it('lists audit log entries', async () => {
      const mockResponse = {
        entries: [
          { id: 'al-1', action: 'user.login', actor: 'u-1', timestamp: '2024-01-01T00:00:00Z' },
        ],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.auditLog.list();

      expect(result.entries).toHaveLength(1);
      expect(result.entries[0]!.action).toBe('user.login');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/audit-log');
      expect(opts.method).toBe('GET');
    });

    it('passes limit query parameter', async () => {
      const fetch = mockFetch({ entries: [] });
      const client = createClient(fetch);

      await client.auditLog.list({ limit: 50 });

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/admin/audit-log?limit=50');
    });
  });
});
