import { vi } from 'vitest';
import { CortexClient } from '../src/client.js';

/**
 * Create a mock fetch function that returns a predefined response.
 */
export function mockFetch(
  body: unknown,
  options?: { status?: number; headers?: Record<string, string> },
): ReturnType<typeof vi.fn> {
  const status = options?.status ?? 200;
  const headers = new Headers(options?.headers ?? {});

  return vi.fn().mockResolvedValue({
    ok: status >= 200 && status < 300,
    status,
    statusText: status === 200 ? 'OK' : 'Error',
    headers,
    json: vi.fn().mockResolvedValue(body),
    text: vi.fn().mockResolvedValue(JSON.stringify(body)),
    body: null,
  } satisfies Partial<Response> as unknown as Response);
}

/**
 * Create a mock fetch that returns an SSE streaming response.
 */
export function mockStreamFetch(chunks: string[]): ReturnType<typeof vi.fn> {
  const encoder = new TextEncoder();
  let chunkIndex = 0;

  const readableStream = new ReadableStream<Uint8Array>({
    pull(controller) {
      if (chunkIndex < chunks.length) {
        controller.enqueue(encoder.encode(chunks[chunkIndex]!));
        chunkIndex++;
      } else {
        controller.close();
      }
    },
  });

  return vi.fn().mockResolvedValue({
    ok: true,
    status: 200,
    statusText: 'OK',
    headers: new Headers({ 'content-type': 'text/event-stream' }),
    body: readableStream,
    json: vi.fn(),
    text: vi.fn(),
  } satisfies Partial<Response> as unknown as Response);
}

/**
 * Create a mock fetch that rejects with a network error.
 */
export function mockNetworkError(message = 'Network error'): ReturnType<typeof vi.fn> {
  return vi.fn().mockRejectedValue(new TypeError(message));
}

/**
 * Create a CortexClient with a mock fetch.
 */
export function createClient(
  fetchFn: ReturnType<typeof vi.fn>,
  options?: { maxRetries?: number },
): CortexClient {
  return new CortexClient({
    apiKey: 'sk-cortex-test-key-12345',
    llmBaseUrl: 'https://api.test.com/v1',
    adminBaseUrl: 'https://admin.test.com',
    fetch: fetchFn as unknown as typeof globalThis.fetch,
    maxRetries: options?.maxRetries ?? 0,
  });
}

/**
 * Create a mock fetch that fails N times then succeeds.
 */
export function mockFetchWithRetries(
  failCount: number,
  successBody: unknown,
  failStatus = 500,
): ReturnType<typeof vi.fn> {
  let callCount = 0;
  return vi.fn().mockImplementation(() => {
    callCount++;
    if (callCount <= failCount) {
      return Promise.resolve({
        ok: false,
        status: failStatus,
        statusText: 'Error',
        headers: new Headers(),
        json: () => Promise.resolve({ error: { message: `Error attempt ${callCount}` } }),
        text: () => Promise.resolve('Error'),
        body: null,
      });
    }
    return Promise.resolve({
      ok: true,
      status: 200,
      statusText: 'OK',
      headers: new Headers(),
      json: () => Promise.resolve(successBody),
      text: () => Promise.resolve(JSON.stringify(successBody)),
      body: null,
    });
  });
}
