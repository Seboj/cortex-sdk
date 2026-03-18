import type { CortexClient } from '../client.js';
import type {
  User,
  UserUpdateParams,
  UserListResponse,
  PendingCountResponse,
  UserApproveResponse,
  UserRejectResponse,
  UserResetPasswordResponse,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class Users {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List all users.
   */
  async list(options?: RequestOptions): Promise<UserListResponse> {
    const url = `${this.client._adminBaseUrl}/admin/users`;
    return this.client._request<UserListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Get pending approval count.
   */
  async pendingCount(options?: RequestOptions): Promise<PendingCountResponse> {
    const url = `${this.client._adminBaseUrl}/admin/users/pending-count`;
    return this.client._request<PendingCountResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Update a user by ID.
   */
  async update(id: string, params: UserUpdateParams, options?: RequestOptions): Promise<User> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/users/${encodeURIComponent(id)}`;
    return this.client._request<User>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Delete a user by ID.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/users/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }

  /**
   * Approve a pending user.
   */
  async approve(id: string, options?: RequestOptions): Promise<UserApproveResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/users/${encodeURIComponent(id)}/approve`;
    return this.client._request<UserApproveResponse>('POST', url, {
      requestOptions: options,
    });
  }

  /**
   * Reject a pending user.
   */
  async reject(id: string, options?: RequestOptions): Promise<UserRejectResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/users/${encodeURIComponent(id)}/reject`;
    return this.client._request<UserRejectResponse>('POST', url, {
      requestOptions: options,
    });
  }

  /**
   * Reset a user's password.
   */
  async resetPassword(id: string, options?: RequestOptions): Promise<UserResetPasswordResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/admin/users/${encodeURIComponent(id)}/reset-password`;
    return this.client._request<UserResetPasswordResponse>('POST', url, {
      requestOptions: options,
    });
  }
}
