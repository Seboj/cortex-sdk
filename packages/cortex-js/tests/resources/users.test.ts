import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('users', () => {
  describe('list', () => {
    it('lists users', async () => {
      const mockResponse = {
        users: [{ id: 'u-1', email: 'test@example.com', createdAt: '2024-01-01', updatedAt: '2024-01-01' }],
      };
      const fetch = mockFetch(mockResponse);
      const client = createClient(fetch);

      const result = await client.users.list();

      expect(result.users).toHaveLength(1);
      expect(result.users[0]!.email).toBe('test@example.com');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users');
      expect(opts.method).toBe('GET');
    });
  });

  describe('pendingCount', () => {
    it('gets pending approval count', async () => {
      const fetch = mockFetch({ count: 5 });
      const client = createClient(fetch);

      const result = await client.users.pendingCount();

      expect(result.count).toBe(5);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users/pending-count');
      expect(opts.method).toBe('GET');
    });
  });

  describe('update', () => {
    it('updates a user', async () => {
      const fetch = mockFetch({ id: 'u-1', email: 'test@example.com', role: 'admin', createdAt: '2024-01-01', updatedAt: '2024-01-02' });
      const client = createClient(fetch);

      const result = await client.users.update('u-1', { role: 'admin' });

      expect(result.role).toBe('admin');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users/u-1');
      expect(opts.method).toBe('PATCH');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.users.update('', { role: 'admin' })).rejects.toThrow(ValidationError);
    });
  });

  describe('delete', () => {
    it('deletes a user', async () => {
      const fetch = mockFetch({ id: 'u-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.users.delete('u-1');

      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users/u-1');
      expect(opts.method).toBe('DELETE');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.users.delete('')).rejects.toThrow(ValidationError);
    });
  });

  describe('approve', () => {
    it('approves a pending user', async () => {
      const fetch = mockFetch({ id: 'u-1', status: 'approved' });
      const client = createClient(fetch);

      const result = await client.users.approve('u-1');

      expect(result.status).toBe('approved');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users/u-1/approve');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.users.approve('')).rejects.toThrow(ValidationError);
    });
  });

  describe('reject', () => {
    it('rejects a pending user', async () => {
      const fetch = mockFetch({ id: 'u-1', status: 'rejected' });
      const client = createClient(fetch);

      const result = await client.users.reject('u-1');

      expect(result.status).toBe('rejected');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users/u-1/reject');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.users.reject('')).rejects.toThrow(ValidationError);
    });
  });

  describe('resetPassword', () => {
    it('resets a user password', async () => {
      const fetch = mockFetch({ id: 'u-1', temporaryPassword: 'tmp123' });
      const client = createClient(fetch);

      const result = await client.users.resetPassword('u-1');

      expect(result.temporaryPassword).toBe('tmp123');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/admin/users/u-1/reset-password');
      expect(opts.method).toBe('POST');
    });

    it('throws ValidationError when id is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.users.resetPassword('')).rejects.toThrow(ValidationError);
    });
  });
});
