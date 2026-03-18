import type { CortexClient } from '../client.js';
import type {
  Backend,
  BackendCreateParams,
  BackendUpdateParams,
  BackendListResponse,
  BackendDiscoverResponse,
  BackendModel,
  BackendModelUpdateParams,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class Backends {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all backends.
   */
  async list(options?: RequestOptions): Promise<BackendListResponse> {
    const url = `${this.client._adminBaseUrl}/admin/backends`;
    return this.client._request<BackendListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Register a new backend.
   */
  async create(params: BackendCreateParams, options?: RequestOptions): Promise<Backend> {
    if (!params.name || typeof params.name !== 'string') {
      throw new ValidationError('name is required and must be a string', 'name');
    }
    if (!params.url || typeof params.url !== 'string') {
      throw new ValidationError('url is required and must be a string', 'url');
    }

    const url = `${this.client._adminBaseUrl}/admin/backends`;
    return this.client._request<Backend>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Update a backend by ID.
   */
  async update(id: string, params: BackendUpdateParams, options?: RequestOptions): Promise<Backend> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/backends/${encodeURIComponent(id)}`;
    return this.client._request<Backend>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Remove a backend by ID.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/backends/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }

  /**
   * Discover models on a backend.
   */
  async discover(id: string, options?: RequestOptions): Promise<BackendDiscoverResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/backends/${encodeURIComponent(id)}/discover`;
    return this.client._request<BackendDiscoverResponse>('POST', url, {
      requestOptions: options,
    });
  }

  /**
   * Update a model's display name on a backend.
   */
  async updateModel(
    backendId: string,
    modelId: string,
    params: BackendModelUpdateParams,
    options?: RequestOptions,
  ): Promise<BackendModel> {
    if (!backendId) throw new ValidationError('backendId is required', 'backendId');
    if (!modelId) throw new ValidationError('modelId is required', 'modelId');
    if (!params.displayName || typeof params.displayName !== 'string') {
      throw new ValidationError('displayName is required and must be a string', 'displayName');
    }

    const url = `${this.client._adminBaseUrl}/admin/backends/${encodeURIComponent(backendId)}/models/${encodeURIComponent(modelId)}`;
    return this.client._request<BackendModel>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }
}
