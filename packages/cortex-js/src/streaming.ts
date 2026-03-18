import type { ChatCompletionChunk } from './types.js';
import { CortexError, ConnectionError } from './errors.js';

/**
 * Parses Server-Sent Events (SSE) from a ReadableStream and yields
 * typed ChatCompletionChunk objects.
 */
export class SSEStream implements AsyncIterable<ChatCompletionChunk> {
  private readonly response: Response;
  private abortController: AbortController | undefined;

  constructor(response: Response, abortController?: AbortController) {
    this.response = response;
    this.abortController = abortController;
  }

  async *[Symbol.asyncIterator](): AsyncIterator<ChatCompletionChunk> {
    const body = this.response.body;
    if (!body) {
      throw new ConnectionError('Response body is null');
    }

    const reader = body.getReader();
    const decoder = new TextDecoder('utf-8');
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();

        if (done) {
          // Process any remaining data in buffer
          if (buffer.trim()) {
            const chunk = this.parseSSEChunk(buffer);
            if (chunk) yield chunk;
          }
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');

        // Keep the last potentially incomplete line in the buffer
        buffer = lines.pop() ?? '';

        let eventData = '';
        for (const line of lines) {
          const trimmed = line.trim();

          if (trimmed === '') {
            // Empty line = end of event
            if (eventData) {
              const chunk = this.parseSSEChunk(eventData);
              if (chunk) yield chunk;
              eventData = '';
            }
            continue;
          }

          if (trimmed.startsWith('data: ')) {
            const data = trimmed.slice(6);
            if (data === '[DONE]') {
              return;
            }
            eventData += (eventData ? '\n' : '') + data;
          }
          // Ignore other SSE fields (event:, id:, retry:) for now
        }
      }
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return;
      }
      throw error;
    } finally {
      reader.releaseLock();
    }
  }

  /**
   * Abort the underlying stream.
   */
  abort(): void {
    this.abortController?.abort();
  }

  /**
   * Collect all chunks into an array (useful for testing).
   */
  async toArray(): Promise<ChatCompletionChunk[]> {
    const chunks: ChatCompletionChunk[] = [];
    for await (const chunk of this) {
      chunks.push(chunk);
    }
    return chunks;
  }

  /**
   * Collect all content from the stream into a single string.
   */
  async toText(): Promise<string> {
    let text = '';
    for await (const chunk of this) {
      const content = chunk.choices[0]?.delta?.content;
      if (content) text += content;
    }
    return text;
  }

  private parseSSEChunk(data: string): ChatCompletionChunk | null {
    try {
      return JSON.parse(data) as ChatCompletionChunk;
    } catch {
      throw new CortexError(`Failed to parse SSE chunk: ${data.slice(0, 200)}`);
    }
  }
}

/**
 * Parse a raw SSE text string into individual data payloads.
 * Exported for testing.
 */
export function parseSSEText(text: string): string[] {
  const results: string[] = [];
  const lines = text.split('\n');
  let currentData = '';

  for (const line of lines) {
    const trimmed = line.trim();

    if (trimmed === '' && currentData) {
      results.push(currentData);
      currentData = '';
    } else if (trimmed.startsWith('data: ')) {
      const data = trimmed.slice(6);
      if (data !== '[DONE]') {
        currentData += (currentData ? '\n' : '') + data;
      }
    }
  }

  if (currentData) {
    results.push(currentData);
  }

  return results;
}
