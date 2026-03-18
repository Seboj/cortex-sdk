import { describe, it, expect, vi } from 'vitest';
import { CortexClient } from '../src/client.js';
import {
  AuthenticationError,
  ValidationError,
  TimeoutError,
  ConnectionError,
  RateLimitError,
  ServerError,
  NotFoundError,
} from '../src/errors.js';
import { mockFetch, mockNetworkError, mockFetchWithRetries, createClient } from './helpers.js';

describe('CortexClient', () => {
  describe('constructor', () => {
    it('creates a client with required options', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(client).toBeInstanceOf(CortexClient);
      expect(client.chat).toBeDefined();
      expect(client.completions).toBeDefined();
      expect(client.embeddings).toBeDefined();
      expect(client.models).toBeDefined();
      expect(client.keys).toBeDefined();
      expect(client.teams).toBeDefined();
      expect(client.usage).toBeDefined();
      expect(client.performance).toBeDefined();
      expect(client.conversations).toBeDefined();
      expect(client.iris).toBeDefined();
      expect(client.plugins).toBeDefined();
      expect(client.pdf).toBeDefined();
      expect(client.webSearch).toBeDefined();
    });

    it('throws AuthenticationError when apiKey is missing', () => {
      expect(() => new CortexClient({ apiKey: '' })).toThrow(AuthenticationError);
    });

    it('throws ValidationError when apiKey is not a string', () => {
      expect(() => new CortexClient({ apiKey: 123 as unknown as string })).toThrow(ValidationError);
    });

    it('uses default URLs when not specified', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test',
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(client._llmBaseUrl).toBe('https://cortexapi.nfinitmonkeys.com/v1');
      expect(client._adminBaseUrl).toBe('https://admin.nfinitmonkeys.com');
    });

    it('accepts custom base URLs', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test',
        llmBaseUrl: 'https://custom-api.example.com/v1',
        adminBaseUrl: 'https://custom-admin.example.com',
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(client._llmBaseUrl).toBe('https://custom-api.example.com/v1');
      expect(client._adminBaseUrl).toBe('https://custom-admin.example.com');
    });

    it('strips trailing slashes from base URLs', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test',
        llmBaseUrl: 'https://api.example.com/v1/',
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(client._llmBaseUrl).toBe('https://api.example.com/v1');
    });

    it('throws ValidationError on invalid base URL', () => {
      expect(
        () => new CortexClient({ apiKey: 'sk-cortex-test', llmBaseUrl: 'not-a-url' }),
      ).toThrow(ValidationError);
    });

    it('throws ValidationError on non-HTTP protocol', () => {
      expect(
        () => new CortexClient({ apiKey: 'sk-cortex-test', llmBaseUrl: 'ftp://example.com' }),
      ).toThrow(ValidationError);
    });

    it('rejects headers with newlines (header injection prevention)', () => {
      expect(
        () =>
          new CortexClient({
            apiKey: 'sk-cortex-test',
            defaultHeaders: { 'X-Custom': 'value\r\nInjected: header' },
          }),
      ).toThrow(ValidationError);
    });

    it('is immutable after construction', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test',
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(() => {
        (client as Record<string, unknown>)['_apiKey'] = 'new-key';
      }).toThrow();
    });

    it('uses custom timeout values', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test',
        timeout: 5000,
        streamTimeout: 60000,
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(client._timeout).toBe(5000);
      expect(client._streamTimeout).toBe(60000);
    });

    it('uses custom maxRetries', () => {
      const client = new CortexClient({
        apiKey: 'sk-cortex-test',
        maxRetries: 5,
        fetch: mockFetch({}) as unknown as typeof globalThis.fetch,
      });
      expect(client._maxRetries).toBe(5);
    });
  });

  describe('_request', () => {
    it('sends Authorization header', async () => {
      const fetch = mockFetch({ data: 'test' });
      const client = createClient(fetch);

      await client._request('GET', 'https://api.test.com/v1/models');

      expect(fetch).toHaveBeenCalledOnce();
      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['Authorization']).toBe(
        'Bearer sk-cortex-test-key-12345',
      );
    });

    it('sends User-Agent header', async () => {
      const fetch = mockFetch({ data: 'test' });
      const client = createClient(fetch);

      await client._request('GET', 'https://api.test.com/v1/models');

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['User-Agent']).toMatch(
        /^cortex-sdk-js\//,
      );
    });

    it('sends Content-Type for POST requests', async () => {
      const fetch = mockFetch({ id: '1' });
      const client = createClient(fetch);

      await client._request('POST', 'https://api.test.com/v1/test', {
        body: { key: 'value' },
      });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['Content-Type']).toBe('application/json');
      expect(opts.body).toBe(JSON.stringify({ key: 'value' }));
    });

    it('appends query parameters', async () => {
      const fetch = mockFetch({ data: [] });
      const client = createClient(fetch);

      await client._request('GET', 'https://api.test.com/v1/test', {
        query: { limit: 10, offset: undefined, name: 'test' },
      });

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toContain('limit=10');
      expect(url).toContain('name=test');
      expect(url).not.toContain('offset');
    });

    it('maps 401 to AuthenticationError', async () => {
      const fetch = mockFetch({ error: { message: 'Invalid API key' } }, { status: 401 });
      const client = createClient(fetch);

      await expect(client._request('GET', 'https://api.test.com/v1/test')).rejects.toThrow(
        AuthenticationError,
      );
    });

    it('maps 404 to NotFoundError', async () => {
      const fetch = mockFetch({ error: { message: 'Not found' } }, { status: 404 });
      const client = createClient(fetch);

      await expect(client._request('GET', 'https://api.test.com/v1/test')).rejects.toThrow(
        NotFoundError,
      );
    });

    it('maps 429 to RateLimitError with retryAfter', async () => {
      const fetch = mockFetch(
        { error: { message: 'Rate limited' } },
        { status: 429, headers: { 'retry-after': '5' } },
      );
      const client = createClient(fetch);

      try {
        await client._request('GET', 'https://api.test.com/v1/test');
        expect.fail('Should have thrown');
      } catch (error) {
        expect(error).toBeInstanceOf(RateLimitError);
        expect((error as RateLimitError).retryAfter).toBe(5);
      }
    });

    it('maps 500+ to ServerError', async () => {
      const fetch = mockFetch({ error: { message: 'Internal error' } }, { status: 500 });
      const client = createClient(fetch);

      await expect(client._request('GET', 'https://api.test.com/v1/test')).rejects.toThrow(
        ServerError,
      );
    });

    it('throws ConnectionError on network failure', async () => {
      const fetch = mockNetworkError('fetch failed');
      const client = createClient(fetch);

      await expect(client._request('GET', 'https://api.test.com/v1/test')).rejects.toThrow(
        ConnectionError,
      );
    });

    it('handles AbortController cancellation', async () => {
      const controller = new AbortController();
      controller.abort();

      const fetch = mockFetch({ data: 'test' });
      const client = createClient(fetch);

      await expect(
        client._request('GET', 'https://api.test.com/v1/test', {
          requestOptions: { signal: controller.signal },
        }),
      ).rejects.toThrow('Request was aborted');
    });

    it('includes custom default headers', async () => {
      const fetch = mockFetch({ data: 'test' });
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        defaultHeaders: { 'X-Custom': 'value' },
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 0,
      });

      await client._request('GET', 'https://api.test.com/v1/test');

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['X-Custom']).toBe('value');
    });

    it('includes per-request headers', async () => {
      const fetch = mockFetch({ data: 'test' });
      const client = createClient(fetch);

      await client._request('GET', 'https://api.test.com/v1/test', {
        requestOptions: { headers: { 'X-Request-Id': 'abc-123' } },
      });

      const [, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect((opts.headers as Record<string, string>)['X-Request-Id']).toBe('abc-123');
    });
  });

  describe('retry logic', () => {
    it('retries on 500 errors', async () => {
      const fetch = mockFetchWithRetries(2, { data: 'success' }, 500);
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 3,
      });

      const result = await client._request<{ data: string }>(
        'GET',
        'https://api.test.com/v1/test',
      );
      expect(result.data).toBe('success');
      expect(fetch).toHaveBeenCalledTimes(3); // 2 failures + 1 success
    });

    it('retries on 429 errors', async () => {
      const fetch = mockFetchWithRetries(1, { data: 'success' }, 429);
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 2,
      });

      const result = await client._request<{ data: string }>(
        'GET',
        'https://api.test.com/v1/test',
      );
      expect(result.data).toBe('success');
      expect(fetch).toHaveBeenCalledTimes(2);
    });

    it('does not retry on 401 errors', async () => {
      const fetch = mockFetch({ error: { message: 'Unauthorized' } }, { status: 401 });
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 3,
      });

      await expect(
        client._request('GET', 'https://api.test.com/v1/test'),
      ).rejects.toThrow(AuthenticationError);
      expect(fetch).toHaveBeenCalledTimes(1);
    });

    it('does not retry on 404 errors', async () => {
      const fetch = mockFetch({ error: { message: 'Not found' } }, { status: 404 });
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 3,
      });

      await expect(
        client._request('GET', 'https://api.test.com/v1/test'),
      ).rejects.toThrow(NotFoundError);
      expect(fetch).toHaveBeenCalledTimes(1);
    });

    it('gives up after maxRetries', async () => {
      const fetch = mockFetchWithRetries(10, { data: 'success' }, 500);
      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 2,
      });

      await expect(
        client._request('GET', 'https://api.test.com/v1/test'),
      ).rejects.toThrow(ServerError);
      expect(fetch).toHaveBeenCalledTimes(3); // initial + 2 retries
    });

    it('retries on network errors', async () => {
      let callCount = 0;
      const fetch = vi.fn().mockImplementation(() => {
        callCount++;
        if (callCount <= 2) {
          return Promise.reject(new TypeError('Network error'));
        }
        return Promise.resolve({
          ok: true,
          status: 200,
          headers: new Headers(),
          json: () => Promise.resolve({ data: 'recovered' }),
          body: null,
        });
      });

      const client = new CortexClient({
        apiKey: 'sk-cortex-test-key',
        llmBaseUrl: 'https://api.test.com/v1',
        fetch: fetch as unknown as typeof globalThis.fetch,
        maxRetries: 3,
      });

      const result = await client._request<{ data: string }>(
        'GET',
        'https://api.test.com/v1/test',
      );
      expect(result.data).toBe('recovered');
      expect(fetch).toHaveBeenCalledTimes(3);
    });
  });
});
