import type { CortexClient } from '../client.js';
import type { UsageStats, UsageLimits, UsageGetParams, RequestOptions } from '../types.js';

export class Usage {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Get usage statistics.
   */
  async get(params?: UsageGetParams, options?: RequestOptions): Promise<UsageStats> {
    const url = `${this.client._adminBaseUrl}/api/usage`;
    return this.client._request<UsageStats>('GET', url, {
      query: params as Record<string, string | undefined>,
      requestOptions: options,
    });
  }

  /**
   * Get current rate and usage limits.
   */
  async limits(options?: RequestOptions): Promise<UsageLimits> {
    const url = `${this.client._adminBaseUrl}/api/usage/limits`;
    return this.client._request<UsageLimits>('GET', url, {
      requestOptions: options,
    });
  }
}
