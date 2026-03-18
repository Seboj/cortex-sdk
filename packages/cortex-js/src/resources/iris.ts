import type { CortexClient } from '../client.js';
import type {
  IrisExtractionParams,
  IrisExtractionResult,
  IrisJob,
  IrisJobsListParams,
  IrisSchema,
  RequestOptions,
} from '../types.js';
import { ValidationError } from '../errors.js';

export class Iris {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Extract structured data from documents.
   */
  async extract(params: IrisExtractionParams, options?: RequestOptions): Promise<IrisExtractionResult> {
    if (!params.document) {
      throw new ValidationError('document is required', 'document');
    }
    if (!params.schema) {
      throw new ValidationError('schema is required', 'schema');
    }

    const url = `${this.client._adminBaseUrl}/api/iris/extract`;
    return this.client._request<IrisExtractionResult>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }

  /**
   * List extraction jobs.
   */
  async jobs(params?: IrisJobsListParams, options?: RequestOptions): Promise<IrisJob[]> {
    const url = `${this.client._adminBaseUrl}/api/iris/jobs`;
    return this.client._request<IrisJob[]>('GET', url, {
      query: params as Record<string, string | number | undefined>,
      requestOptions: options,
    });
  }

  /**
   * List extraction schemas.
   */
  async schemas(options?: RequestOptions): Promise<IrisSchema[]> {
    const url = `${this.client._adminBaseUrl}/api/iris/schemas`;
    return this.client._request<IrisSchema[]>('GET', url, {
      requestOptions: options,
    });
  }
}
