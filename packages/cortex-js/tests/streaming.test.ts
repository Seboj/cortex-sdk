import { describe, it, expect } from 'vitest';
import { SSEStream, parseSSEText } from '../src/streaming.js';

function createSSEResponse(chunks: string[]): Response {
  const encoder = new TextEncoder();
  let index = 0;

  const stream = new ReadableStream<Uint8Array>({
    pull(controller) {
      if (index < chunks.length) {
        controller.enqueue(encoder.encode(chunks[index]!));
        index++;
      } else {
        controller.close();
      }
    },
  });

  return {
    ok: true,
    status: 200,
    headers: new Headers({ 'content-type': 'text/event-stream' }),
    body: stream,
  } as unknown as Response;
}

describe('SSEStream', () => {
  it('parses single SSE event', async () => {
    const data = JSON.stringify({
      id: 'chatcmpl-1',
      object: 'chat.completion.chunk',
      created: 1700000000,
      model: 'gpt-4',
      choices: [{ index: 0, delta: { content: 'Hello' }, finish_reason: null }],
    });

    const response = createSSEResponse([`data: ${data}\n\n`]);
    const stream = new SSEStream(response);
    const chunks = await stream.toArray();

    expect(chunks).toHaveLength(1);
    expect(chunks[0]!.choices[0]!.delta.content).toBe('Hello');
  });

  it('parses multiple SSE events', async () => {
    const chunk1 = JSON.stringify({
      id: 'chatcmpl-1',
      object: 'chat.completion.chunk',
      created: 1700000000,
      model: 'gpt-4',
      choices: [{ index: 0, delta: { content: 'Hello' }, finish_reason: null }],
    });
    const chunk2 = JSON.stringify({
      id: 'chatcmpl-1',
      object: 'chat.completion.chunk',
      created: 1700000000,
      model: 'gpt-4',
      choices: [{ index: 0, delta: { content: ' world' }, finish_reason: null }],
    });

    const response = createSSEResponse([
      `data: ${chunk1}\n\ndata: ${chunk2}\n\n`,
    ]);
    const stream = new SSEStream(response);
    const chunks = await stream.toArray();

    expect(chunks).toHaveLength(2);
    expect(chunks[0]!.choices[0]!.delta.content).toBe('Hello');
    expect(chunks[1]!.choices[0]!.delta.content).toBe(' world');
  });

  it('stops at [DONE] marker', async () => {
    const chunk1 = JSON.stringify({
      id: 'chatcmpl-1',
      object: 'chat.completion.chunk',
      created: 1700000000,
      model: 'gpt-4',
      choices: [{ index: 0, delta: { content: 'Hi' }, finish_reason: null }],
    });

    const response = createSSEResponse([
      `data: ${chunk1}\n\ndata: [DONE]\n\n`,
    ]);
    const stream = new SSEStream(response);
    const chunks = await stream.toArray();

    expect(chunks).toHaveLength(1);
    expect(chunks[0]!.choices[0]!.delta.content).toBe('Hi');
  });

  it('handles chunks split across reads', async () => {
    const data = JSON.stringify({
      id: 'chatcmpl-1',
      object: 'chat.completion.chunk',
      created: 1700000000,
      model: 'gpt-4',
      choices: [{ index: 0, delta: { content: 'Test' }, finish_reason: null }],
    });

    // Split the SSE data across two reads
    const fullText = `data: ${data}\n\n`;
    const splitPoint = Math.floor(fullText.length / 2);

    const response = createSSEResponse([
      fullText.slice(0, splitPoint),
      fullText.slice(splitPoint),
    ]);
    const stream = new SSEStream(response);
    const chunks = await stream.toArray();

    expect(chunks).toHaveLength(1);
    expect(chunks[0]!.choices[0]!.delta.content).toBe('Test');
  });

  it('toText() collects all content', async () => {
    const makeChunk = (content: string) =>
      JSON.stringify({
        id: 'chatcmpl-1',
        object: 'chat.completion.chunk',
        created: 1700000000,
        model: 'gpt-4',
        choices: [{ index: 0, delta: { content }, finish_reason: null }],
      });

    const response = createSSEResponse([
      `data: ${makeChunk('Hello')}\n\ndata: ${makeChunk(' ')}\n\ndata: ${makeChunk('world')}\n\ndata: [DONE]\n\n`,
    ]);
    const stream = new SSEStream(response);
    const text = await stream.toText();

    expect(text).toBe('Hello world');
  });

  it('handles empty body', async () => {
    const response = {
      ok: true,
      status: 200,
      headers: new Headers(),
      body: null,
    } as unknown as Response;

    const stream = new SSEStream(response);
    await expect(stream.toArray()).rejects.toThrow('Response body is null');
  });

  it('uses async iterator protocol', async () => {
    const data = JSON.stringify({
      id: 'chatcmpl-1',
      object: 'chat.completion.chunk',
      created: 1700000000,
      model: 'gpt-4',
      choices: [{ index: 0, delta: { content: 'Iter' }, finish_reason: null }],
    });

    const response = createSSEResponse([`data: ${data}\n\ndata: [DONE]\n\n`]);
    const stream = new SSEStream(response);

    const results: string[] = [];
    for await (const chunk of stream) {
      results.push(chunk.choices[0]?.delta?.content ?? '');
    }
    expect(results).toEqual(['Iter']);
  });
});

describe('parseSSEText', () => {
  it('parses simple SSE text', () => {
    const text = 'data: {"key":"value"}\n\n';
    const results = parseSSEText(text);
    expect(results).toEqual(['{"key":"value"}']);
  });

  it('ignores [DONE] marker', () => {
    const text = 'data: {"key":"value"}\n\ndata: [DONE]\n\n';
    const results = parseSSEText(text);
    expect(results).toEqual(['{"key":"value"}']);
  });

  it('handles multiple events', () => {
    const text = 'data: {"a":1}\n\ndata: {"b":2}\n\n';
    const results = parseSSEText(text);
    expect(results).toEqual(['{"a":1}', '{"b":2}']);
  });

  it('returns empty for empty input', () => {
    expect(parseSSEText('')).toEqual([]);
  });
});
