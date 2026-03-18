import type { CortexClient } from '../client.js';
import type { EmbeddingCreateParams, EmbeddingResponse, RequestOptions } from '../types.js';
import { ValidationError } from '../errors.js';

export interface EmbeddingCreateOptions extends RequestOptions {
  /** Pool slug for routing this request. Overrides client-level defaultPool. */
  pool?: string;
}

export class Embeddings {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Create embeddings for the given input.
   */
  async create(params: EmbeddingCreateParams, options?: EmbeddingCreateOptions): Promise<EmbeddingResponse> {
    if (params.model !== undefined && params.model === '') {
      throw new ValidationError('model must not be empty when provided', 'model');
    }
    if (!params.input) {
      throw new ValidationError('input is required', 'input');
    }
    if (Array.isArray(params.input) && params.input.length === 0) {
      throw new ValidationError('input must not be empty', 'input');
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

    const url = `${this.client._llmBaseUrl}/embeddings`;
    return this.client._request<EmbeddingResponse>('POST', url, {
      body: params,
      requestOptions,
    });
  }
}
