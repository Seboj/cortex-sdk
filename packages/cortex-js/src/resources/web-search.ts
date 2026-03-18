import type { CortexClient } from '../client.js';
import type { WebSearchParams, WebSearchResponse, RequestOptions } from '../types.js';
import { ValidationError } from '../errors.js';

export class WebSearch {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Perform a web search.
   */
  async search(params: WebSearchParams, options?: RequestOptions): Promise<WebSearchResponse> {
    if (!params.query || typeof params.query !== 'string') {
      throw new ValidationError('query is required and must be a string', 'query');
    }

    const url = `${this.client._adminBaseUrl}/api/web/search`;
    return this.client._request<WebSearchResponse>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }
}
