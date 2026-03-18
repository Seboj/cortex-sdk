import type { CortexClient } from '../client.js';
import type {
  Conversation,
  ConversationCreateParams,
  ConversationUpdateParams,
  ConversationListParams,
  ConversationListResponse,
  DeleteResponse,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';
import { SSEStream } from '../streaming.js';

export class Conversations {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List conversations.
   */
  async list(params?: ConversationListParams, options?: RequestOptions): Promise<ConversationListResponse> {
    const url = `${this.client._adminBaseUrl}/api/conversations`;
    return this.client._request<ConversationListResponse>('GET', url, {
      query: params as Record<string, string | number | undefined>,
      requestOptions: options,
    });
  }

  /**
   * Create a new conversation.
   */
  async create(params: ConversationCreateParams, options?: RequestOptions): Promise<Conversation> {
    const url = `${this.client._adminBaseUrl}/api/conversations`;
    return this.client._request<Conversation>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Get a conversation by ID.
   */
  async get(id: string, options?: RequestOptions): Promise<Conversation> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/api/conversations/${encodeURIComponent(id)}`;
    return this.client._request<Conversation>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Update a conversation.
   */
  async update(
    id: string,
    params: ConversationUpdateParams,
    options?: RequestOptions,
  ): Promise<Conversation> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/api/conversations/${encodeURIComponent(id)}`;
    return this.client._request<Conversation>('PATCH', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * Delete a conversation.
   */
  async delete(id: string, options?: RequestOptions): Promise<DeleteResponse> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/api/conversations/${encodeURIComponent(id)}`;
    return this.client._request<DeleteResponse>('DELETE', url, {
      requestOptions: options,
    });
  }

  /**
   * Stream messages for a conversation (SSE).
   */
  async messages(id: string, options?: RequestOptions): Promise<SSEStream> {
    if (!id) throw new ValidationError('id is required', 'id');

    const url = `${this.client._adminBaseUrl}/api/conversations/${encodeURIComponent(id)}/messages`;
    return this.client._request<SSEStream>('GET', url, {
      stream: true,
      requestOptions: options,
    });
  }
}
