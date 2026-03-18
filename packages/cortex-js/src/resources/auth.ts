import type { CortexClient } from '../client.js';
import type {
  AuthLoginParams,
  AuthLoginResponse,
  AuthSignupParams,
  AuthSignupResponse,
  AuthUser,
  AuthUpdateProfileParams,
  AuthChangePasswordParams,
  AuthChangePasswordResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class Auth {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Log in with email and password.
   */
  async login(params: AuthLoginParams, options?: RequestOptions): Promise<AuthLoginResponse> {
    if (!params.email || typeof params.email !== 'string') {
      throw new ValidationError('email is required and must be a string', 'email');
    }
    if (!params.password || typeof params.password !== 'string') {
      throw new ValidationError('password is required and must be a string', 'password');
    }

    const url = `${this.client._adminBaseUrl}/auth/login`;
    return this.client._request<AuthLoginResponse>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Sign up a new account.
   */
  async signup(params: AuthSignupParams, options?: RequestOptions): Promise<AuthSignupResponse> {
    if (!params.email || typeof params.email !== 'string') {
      throw new ValidationError('email is required and must be a string', 'email');
    }
    if (!params.password || typeof params.password !== 'string') {
      throw new ValidationError('password is required and must be a string', 'password');
    }

    const url = `${this.client._adminBaseUrl}/auth/signup`;
    return this.client._request<AuthSignupResponse>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Get current user profile.
   */
  async me(options?: RequestOptions): Promise<AuthUser> {
    const url = `${this.client._adminBaseUrl}/auth/me`;
    return this.client._request<AuthUser>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Update current user profile.
   */
  async updateProfile(params: AuthUpdateProfileParams, options?: RequestOptions): Promise<AuthUser> {
    const url = `${this.client._adminBaseUrl}/auth/me`;
    return this.client._request<AuthUser>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Change password.
   */
  async changePassword(
    params: AuthChangePasswordParams,
    options?: RequestOptions,
  ): Promise<AuthChangePasswordResponse> {
    if (!params.currentPassword || typeof params.currentPassword !== 'string') {
      throw new ValidationError('currentPassword is required and must be a string', 'currentPassword');
    }
    if (!params.newPassword || typeof params.newPassword !== 'string') {
      throw new ValidationError('newPassword is required and must be a string', 'newPassword');
    }

    const url = `${this.client._adminBaseUrl}/auth/change-password`;
    return this.client._request<AuthChangePasswordResponse>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }
}
