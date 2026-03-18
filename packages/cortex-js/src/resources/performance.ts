import type { CortexClient } from '../client.js';
import type { PerformanceMetrics, PerformanceGetParams, RequestOptions } from '../types.js';

export class Performance {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Get performance metrics.
   */
  async get(params?: PerformanceGetParams, options?: RequestOptions): Promise<PerformanceMetrics> {
    const url = `${this.client._adminBaseUrl}/api/performance`;
    return this.client._request<PerformanceMetrics>('GET', url, {
      query: params as Record<string, string | undefined>,
      requestOptions: options,
    });
  }
}
