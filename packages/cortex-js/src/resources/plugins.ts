import type { CortexClient } from '../client.js';
import type { PluginListResponse, RequestOptions } from '../types.js';

export class Plugins {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all plugins.
   */
  async list(options?: RequestOptions): Promise<PluginListResponse> {
    const url = `${this.client._adminBaseUrl}/api/plugins`;
    return this.client._request<PluginListResponse>('GET', url, {
      requestOptions: options,
    });
  }
}
