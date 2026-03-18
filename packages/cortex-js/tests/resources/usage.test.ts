import { describe, it, expect } from 'vitest';
import { mockFetch, createClient } from '../helpers.js';

describe('usage', () => {
  describe('get', () => {
    it('gets usage stats', async () => {
      const mockResponse = {
        totalRequests: 1000,
        totalTokens: 50000,
        promptTokens: 30000,
        completionTokens: 20000,
        period: '2024-01',
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.usage.get();
      expect(result.totalRequests).toBe(1000);
      expect(result.totalTokens).toBe(50000);

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/usage');
    });

    it('passes query parameters', async () => {
      const fetch = mockFetch({ totalRequests: 100, totalTokens: 5000, promptTokens: 3000, completionTokens: 2000, period: '2024-01' });
      const client = createClient(fetch);

      await client.usage.get({
        startDate: '2024-01-01',
        endDate: '2024-01-31',
        model: 'gpt-4',
        granularity: 'daily',
      });

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toContain('startDate=2024-01-01');
      expect(url).toContain('endDate=2024-01-31');
      expect(url).toContain('model=gpt-4');
      expect(url).toContain('granularity=daily');
    });
  });

  describe('limits', () => {
    it('gets usage limits', async () => {
      const mockResponse = {
        requestsPerMinute: 60,
        requestsPerDay: 10000,
        tokensPerMinute: 100000,
        tokensPerDay: 1000000,
        currentUsage: {
          requestsThisMinute: 5,
          requestsToday: 500,
          tokensThisMinute: 1000,
          tokensToday: 50000,
        },
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.usage.limits();
      expect(result.requestsPerMinute).toBe(60);
      expect(result.currentUsage.requestsThisMinute).toBe(5);

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/usage/limits');
    });
  });
});
