import { describe, it, expect } from 'vitest';
import { ValidationError } from '../../src/errors.js';
import { mockFetch, createClient } from '../helpers.js';

describe('teams', () => {
  describe('list', () => {
    it('lists teams', async () => {
      const fetch = mockFetch({ teams: [{ id: 't-1', name: 'Eng', createdAt: '2024-01-01', updatedAt: '2024-01-01' }] });
      const client = createClient(fetch);

      const result = await client.teams.list();
      expect(result.teams).toHaveLength(1);
      expect(result.teams[0]!.name).toBe('Eng');

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/teams');
      expect(opts.method).toBe('GET');
    });
  });

  describe('create', () => {
    it('creates a team', async () => {
      const fetch = mockFetch({ id: 't-2', name: 'Product', createdAt: '2024-01-01', updatedAt: '2024-01-01' });
      const client = createClient(fetch);

      const result = await client.teams.create({ name: 'Product' });
      expect(result.name).toBe('Product');

      const body = JSON.parse((fetch.mock.calls[0] as [string, RequestInit])[1].body as string);
      expect(body.name).toBe('Product');
    });

    it('throws ValidationError when name is missing', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.teams.create({ name: '' })).rejects.toThrow(ValidationError);
    });
  });

  describe('get', () => {
    it('gets a team by id', async () => {
      const fetch = mockFetch({ id: 't-1', name: 'Eng', createdAt: '2024-01-01', updatedAt: '2024-01-01' });
      const client = createClient(fetch);

      const result = await client.teams.get('t-1');
      expect(result.id).toBe('t-1');

      const [url] = fetch.mock.calls[0] as [string];
      expect(url).toBe('https://admin.test.com/api/teams/t-1');
    });

    it('throws ValidationError when id is empty', async () => {
      const client = createClient(mockFetch({}));
      await expect(client.teams.get('')).rejects.toThrow(ValidationError);
    });
  });

  describe('delete', () => {
    it('deletes a team', async () => {
      const fetch = mockFetch({ id: 't-1', deleted: true });
      const client = createClient(fetch);

      const result = await client.teams.delete('t-1');
      expect(result.deleted).toBe(true);

      const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
      expect(url).toBe('https://admin.test.com/api/teams/t-1');
      expect(opts.method).toBe('DELETE');
    });
  });

  describe('members', () => {
    describe('add', () => {
      it('adds a member', async () => {
        const fetch = mockFetch({ id: 'm-1', userId: 'u-1', role: 'member', joinedAt: '2024-01-01' });
        const client = createClient(fetch);

        const result = await client.teams.members.add('t-1', {
          userId: 'u-1',
          role: 'member',
        });
        expect(result.userId).toBe('u-1');

        const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
        expect(url).toBe('https://admin.test.com/api/teams/t-1/members');
        expect(opts.method).toBe('POST');
      });

      it('throws ValidationError when teamId is missing', async () => {
        const client = createClient(mockFetch({}));
        await expect(client.teams.members.add('', { userId: 'u-1', role: 'member' })).rejects.toThrow(ValidationError);
      });

      it('throws ValidationError when role is missing', async () => {
        const client = createClient(mockFetch({}));
        await expect(client.teams.members.add('t-1', { userId: 'u-1', role: '' as 'member' })).rejects.toThrow(ValidationError);
      });
    });

    describe('update', () => {
      it('updates a member role', async () => {
        const fetch = mockFetch({ id: 'm-1', userId: 'u-1', role: 'admin', joinedAt: '2024-01-01' });
        const client = createClient(fetch);

        const result = await client.teams.members.update('t-1', 'm-1', { role: 'admin' });
        expect(result.role).toBe('admin');

        const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
        expect(url).toBe('https://admin.test.com/api/teams/t-1/members/m-1');
        expect(opts.method).toBe('PATCH');
      });

      it('throws ValidationError when memberId is missing', async () => {
        const client = createClient(mockFetch({}));
        await expect(client.teams.members.update('t-1', '', { role: 'admin' })).rejects.toThrow(ValidationError);
      });
    });

    describe('remove', () => {
      it('removes a member', async () => {
        const fetch = mockFetch({ id: 'm-1', deleted: true });
        const client = createClient(fetch);

        const result = await client.teams.members.remove('t-1', 'm-1');
        expect(result.deleted).toBe(true);

        const [url, opts] = fetch.mock.calls[0] as [string, RequestInit];
        expect(url).toBe('https://admin.test.com/api/teams/t-1/members/m-1');
        expect(opts.method).toBe('DELETE');
      });
    });
  });
});
