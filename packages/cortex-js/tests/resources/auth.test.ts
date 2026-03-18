import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('auth', () => {
  describe('login', () => {
    it('logs in with email and password', async () => {
      const mockResponse = {
        token: 'jwt-token-123',
        user: { id: 'u-1', email: 'test@example.com', createdAt: '2024-01-01' },
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.auth.login({ email: 'test@example.com', password: 'secret' });

      expect(result.token).toBe('jwt-token-123');
      expect(result.user.email).toBe('test@example.com');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/auth/login');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when email is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.auth.login({ email: '', password: 'secret' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when password is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.auth.login({ email: 'test@example.com', password: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('signup', () => {
    it('signs up a new account', async () => {
      const mockResponse = {
        token: 'jwt-token-456',
        user: { id: 'u-2', email: 'new@example.com', createdAt: '2024-01-01' },
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.auth.signup({ email: 'new@example.com', password: 'secret', name: 'New User' });

      expect(result.token).toBe('jwt-token-456');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/auth/signup');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when email is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.auth.signup({ email: '', password: 'secret' })).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when password is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.auth.signup({ email: 'test@example.com', password: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('me', () => {
    it('gets current user profile', async () => {
      const mockResponse = { id: 'u-1', email: 'test@example.com', name: 'Test', createdAt: '2024-01-01' };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.auth.me();

      expect(result.email).toBe('test@example.com');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/auth/me');
      expect(opts.method).toBe('GET');
    });
  });

  describe('updateProfile', () => {
    it('updates current user profile', async () => {
      const mockResponse = { id: 'u-1', email: 'test@example.com', name: 'Updated', createdAt: '2024-01-01' };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.auth.updateProfile({ name: 'Updated' });

      expect(result.name).toBe('Updated');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/auth/me');
      expect(opts.method).toBe('PATCH');
    });
  });

  describe('changePassword', () => {
    it('changes password', async () => {
      const fetch = mockFetch({ success: true });
      const client = createClient(fetch);

      const result = await client.auth.changePassword({
        currentPassword: 'old',
        newPassword: 'new',
      });

      expect(result.success).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/auth/change-password');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when currentPassword is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(
        client.auth.changePassword({ currentPassword: '', newPassword: 'new' }),
      ).rejects.toThrow(ValidationError);
    });

    it('throws ValidationError when newPassword is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(
        client.auth.changePassword({ currentPassword: 'old', newPassword: '' }),
      ).rejects.toThrow(ValidationError);
    });
  });
});
