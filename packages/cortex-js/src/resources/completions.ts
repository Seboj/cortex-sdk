import type { CortexClient } from '../client.js';
import type { Completion, CompletionCreateParams, RequestOptions } from '../types.js';
import { ValidationError } from '../errors.js';

export interface CompletionCreateOptions extends RequestOptions {
  /** Pool slug for routing this request. Overrides client-level defaultPool. */
  pool?: string;
}

export class Completions {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Create a text completion.
   */
  async create(params: CompletionCreateParams, options?: CompletionCreateOptions): Promise<Completion> {
    if (params.model !== undefined && params.model === '') {
      throw new ValidationError('model must not be empty when provided', 'model');
    }
    if (!params.prompt) {
      throw new ValidationError('prompt is required', 'prompt');
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

    const url = `${this.client._llmBaseUrl}/completions`;
    return this.client._request<Completion>('POST', url, {
      body: params,
      requestOptions,
    });
  }
}
