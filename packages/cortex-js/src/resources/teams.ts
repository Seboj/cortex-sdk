import type { CortexClient } from '../client.js';
import type {
  Team,
  TeamCreateParams,
  TeamListResponse,
  TeamMember,
  TeamMemberAddParams,
  TeamMemberUpdateParams,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class TeamMembers {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Add a member to a team.
   */
  async add(teamId: string, params: TeamMemberAddParams, options?: RequestOptions): Promise<TeamMember> {
    if (!teamId) throw new ValidationError('teamId is required', 'teamId');
    if (!params.userId && !params.email) {
      throw new ValidationError('userId or email is required', 'userId');
    }
    if (!params.role) {
      throw new ValidationError('role is required', 'role');
    }

    const url = `${this.client._adminBaseUrl}/api/teams/${encodeURIComponent(teamId)}/members`;
    return this.client._request<TeamMember>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Update a team member's role.
   */
  async update(
    teamId: string,
    memberId: string,
    params: TeamMemberUpdateParams,
    options?: RequestOptions,
  ): Promise<TeamMember> {
    if (!teamId) throw new ValidationError('teamId is required', 'teamId');
    if (!memberId) throw new ValidationError('memberId is required', 'memberId');
    if (!params.role) throw new ValidationError('role is required', 'role');

    const url = `${this.client._adminBaseUrl}/api/teams/${encodeURIComponent(teamId)}/members/${encodeURIComponent(memberId)}`;
    return this.client._request<TeamMember>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Remove a member from a team.
   */
  async remove(teamId: string, memberId: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!teamId) throw new ValidationError('teamId is required', 'teamId');
    if (!memberId) throw new ValidationError('memberId is required', 'memberId');

    const url = `${this.client._adminBaseUrl}/api/teams/${encodeURIComponent(teamId)}/members/${encodeURIComponent(memberId)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }
}

export class Teams {
  private client: CortexClient;
  readonly members: TeamMembers;

  constructor(client: CortexClient) {
    this.client = client;
    this.members = new TeamMembers(client);
  }

  /**
   * List all teams.
   */
  async list(options?: RequestOptions): Promise<TeamListResponse> {
    const url = `${this.client._adminBaseUrl}/api/teams`;
    return this.client._request<TeamListResponse>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Create a new team.
   */
  async create(params: TeamCreateParams, options?: RequestOptions): Promise<Team> {
    if (!params.name || typeof params.name !== 'string') {
      throw new ValidationError('name is required and must be a string', 'name');
    }

    const url = `${this.client._adminBaseUrl}/api/teams`;
    return this.client._request<Team>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Get a team by ID.
   */
  async get(id: string, options?: RequestOptions): Promise<Team> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/api/teams/${encodeURIComponent(id)}`;
    return this.client._request<Team>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Delete a team by ID.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/api/teams/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }
}
