import type { CortexClient } from '../client.js';
import type {
  AdminApiKey,
  AdminApiKeyCreateParams,
  AdminApiKeyUpdateParams,
  AdminApiKeyListResponse,
  AdminApiKeyRegenerateResponse,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class AdminKeys {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all admin API keys.
   */
  async list(options?: RequestOptions): Promise<AdminApiKeyListResponse> {
    const url = `${this.client._adminBaseUrl}/admin/api-keys`;
    return this.client._request<AdminApiKeyListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Create a new admin API key.
   */
  async create(params: AdminApiKeyCreateParams, options?: RequestOptions): Promise<AdminApiKey> {
    if (!params.name || typeof params.name !== 'string') {
      throw new ValidationError('name is required and must be a string', 'name');
    }

    const url = `${this.client._adminBaseUrl}/admin/api-keys`;
    return this.client._request<AdminApiKey>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Update an admin API key.
   */
  async update(
    id: string,
    params: AdminApiKeyUpdateParams,
    options?: RequestOptions,
  ): Promise<AdminApiKey> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/api-keys/${encodeURIComponent(id)}`;
    return this.client._request<AdminApiKey>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Revoke (delete) an admin API key.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/api-keys/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }

  /**
   * Regenerate an admin API key.
   */
  async regenerate(id: string, options?: RequestOptions): Promise<AdminApiKeyRegenerateResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/api-keys/${encodeURIComponent(id)}/regenerate`;
    return this.client._request<AdminApiKeyRegenerateResponse>('POST', url, {
      requestOptions: options,
    });
  }
}
