import type { CortexClient } from '../client.js';
import type {
  ChatCompletion,
  ChatCompletionCreateParamsNonStreaming,
  ChatCompletionCreateParamsStreaming,
  RequestOptions,
} from '../types.js';
import type { SSEStream } from '../streaming.js';
import { ValidationError } from '../errors.js';

export interface ChatCompletionCreateOptions extends RequestOptions {
  /** Pool slug for routing this request. Overrides client-level defaultPool. */
  pool?: string;
}

export class ChatCompletions {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Create a chat completion (non-streaming).
   */
  async create(
    params: ChatCompletionCreateParamsNonStreaming,
    options?: ChatCompletionCreateOptions,
  ): Promise<ChatCompletion>;

  /**
   * Create a chat completion (streaming).
   */
  async create(
    params: ChatCompletionCreateParamsStreaming,
    options?: ChatCompletionCreateOptions,
  ): Promise<SSEStream>;

  async create(
    params: ChatCompletionCreateParamsNonStreaming | ChatCompletionCreateParamsStreaming,
    options?: ChatCompletionCreateOptions,
  ): Promise<ChatCompletion | SSEStream> {
    // Input validation
    if (params.model !== undefined && params.model === '') {
      throw new ValidationError('model must not be empty when provided', 'model');
    }
    if (!Array.isArray(params.messages) || params.messages.length === 0) {
      throw new ValidationError('messages must be a non-empty array', 'messages');
    }
    for (const msg of params.messages) {
      if (!msg.role) {
        throw new ValidationError('Each message must have a role', 'messages.role');
      }
    }

    if (params.temperature !== undefined && (params.temperature < 0 || params.temperature > 2)) {
      throw new ValidationError('temperature must be between 0 and 2', 'temperature');
    }

    // Resolve pool: per-request > client default > none
    const pool = options?.pool ?? this.client._defaultPool;
    const poolHeaders: Record<string, string> = {};
    if (pool) {
      poolHeaders['x-cortex-pool'] = pool;
    }

    const requestOptions: RequestOptions = {
      ...options,
      headers: { ...poolHeaders, ...options?.headers },
    };

    const url = `${this.client._llmBaseUrl}/chat/completions`;

    if (params.stream) {
      return this.client._request<SSEStream>('POST', url, {
        body: params,
        stream: true,
        requestOptions,
      });
    }

    return this.client._request<ChatCompletion>('POST', url, {
      body: params,
      requestOptions,
    });
  }
}

export class Chat {
  readonly completions: ChatCompletions;

  constructor(client: CortexClient) {
    this.completions = new ChatCompletions(client);
  }
}
