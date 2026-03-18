import type { CortexClient } from '../client.js';
import type { ModelList, ModelsConfig, RequestOptions } from '../types.js';

export class Models {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * List available LLM models.
   */
  async list(options?: RequestOptions): Promise<ModelList> {
    const url = `${this.client._llmBaseUrl}/models`;
    return this.client._request<ModelList>('GET', url, {
      requestOptions: options,
    });
  }

  /**
   * Get models configuration from the admin API.
   */
  async config(options?: RequestOptions): Promise<ModelsConfig> {
    const url = `${this.client._adminBaseUrl}/api/models`;
    return this.client._request<ModelsConfig>('GET', url, {
      requestOptions: options,
    });
  }
}
