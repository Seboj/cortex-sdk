import type { CortexClient } from '../client.js';
import type { AuditLogListParams, AuditLogListResponse, RequestOptions } from '../types.js';

export class AuditLog {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Get audit log entries.
   */
  async list(params?: AuditLogListParams, options?: RequestOptions): Promise<AuditLogListResponse> {
    const url = `${this.client._adminBaseUrl}/admin/audit-log`;
    return this.client._request<AuditLogListResponse>('GET', url, {
      query: params as Record<string, string | number | undefined>,
      requestOptions: options,
    });
  }
}
