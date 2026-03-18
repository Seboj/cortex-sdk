import type { CortexClient } from '../client.js';
import type {
  UsageLimit,
  UsageLimitSetParams,
  UsageLimitListResponse,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class UsageLimitsResource {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all usage limits.
   */
  async list(options?: RequestOptions): Promise<UsageLimitListResponse> {
    const url = `${this.client._adminBaseUrl}/admin/usage-limits`;
    return this.client._request<UsageLimitListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Set usage limits for a user.
   */
  async setForUser(
    userId: string,
    params: UsageLimitSetParams,
    options?: RequestOptions,
  ): Promise<UsageLimit> {
    if (!userId) throw new ValidationError('userId is required', 'userId');

    const url = `${this.client._adminBaseUrl}/admin/usage-limits/user/${encodeURIComponent(userId)}`;
    return this.client._request<UsageLimit>('PUT', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Remove usage limits for a user.
   */
  async removeForUser(userId: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!userId) throw new ValidationError('userId is required', 'userId');

    const url = `${this.client._adminBaseUrl}/admin/usage-limits/user/${encodeURIComponent(userId)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }

  /**
   * Remove usage limits for a team.
   */
  async removeForTeam(teamId: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!teamId) throw new ValidationError('teamId is required', 'teamId');

    const url = `${this.client._adminBaseUrl}/admin/usage-limits/team/${encodeURIComponent(teamId)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }
}
