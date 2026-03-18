import type { CortexClient } from '../client.js';
import type {
  Pool,
  PoolCreateParams,
  PoolUpdateParams,
  PoolListResponse,
  PoolBackend,
  PoolAddBackendParams,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class Pools {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all pools.
   */
  async list(options?: RequestOptions): Promise<PoolListResponse> {
    const url = `${this.client._adminBaseUrl}/admin/pools`;
    return this.client._request<PoolListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Create a new pool.
   */
  async create(params: PoolCreateParams, options?: RequestOptions): Promise<Pool> {
    if (!params.name || typeof params.name !== 'string') {
      throw new ValidationError('name is required and must be a string', 'name');
    }

    const url = `${this.client._adminBaseUrl}/admin/pools`;
    return this.client._request<Pool>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Update a pool by ID.
   */
  async update(id: string, params: PoolUpdateParams, options?: RequestOptions): Promise<Pool> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/pools/${encodeURIComponent(id)}`;
    return this.client._request<Pool>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Delete a pool by ID.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/pools/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }

  /**
   * Add a backend to a pool.
   */
  async addBackend(
    poolId: string,
    params: PoolAddBackendParams,
    options?: RequestOptions,
  ): Promise<PoolBackend> {
    if (!poolId) throw new ValidationError('poolId is required', 'poolId');
    if (!params.backendId) throw new ValidationError('backendId is required', 'backendId');

    const url = `${this.client._adminBaseUrl}/admin/pools/${encodeURIComponent(poolId)}/backends`;
    return this.client._request<PoolBackend>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Remove a backend from a pool.
   */
  async removeBackend(
    poolId: string,
    backendId: string,
    options?: RequestOptions,
  ): Promise<DeleteResponse> {
    if (!poolId) throw new ValidationError('poolId is required', 'poolId');
    if (!backendId) throw new ValidationError('backendId is required', 'backendId');

    const url = `${this.client._adminBaseUrl}/admin/pools/${encodeURIComponent(poolId)}/backends/${encodeURIComponent(backendId)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }
}
