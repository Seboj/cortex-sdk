import type { CortexClient } from '../client.js';
import type { ApiKey, ApiKeyCreateParams, ApiKeyListResponse, DeleteResponse, RequestOptions } from '../types.js';
import { ValidationError } from '../errors.js';

export class Keys {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all API keys.
   */
  async list(options?: RequestOptions): Promise<ApiKeyListResponse> {
    const url = `${this.client._adminBaseUrl}/api/keys`;
    return this.client._request<ApiKeyListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Create a new API key.
   */
  async create(params: ApiKeyCreateParams, options?: RequestOptions): Promise<ApiKey> {
    if (!params.name || typeof params.name !== 'string') {
      throw new ValidationError('name is required and must be a string', 'name');
    }

    const url = `${this.client._adminBaseUrl}/api/keys`;
    return this.client._request<ApiKey>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Revoke (delete) an API key by ID.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id || typeof id !== 'string') {
      throw new ValidationError('id is required and must be a string', 'id');
    }

    const url = `${this.client._adminBaseUrl}/api/keys/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }
}
