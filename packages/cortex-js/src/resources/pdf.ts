import type { CortexClient } from '../client.js';
import type { PdfGenerateParams, PdfGenerateResponse, RequestOptions } from '../types.js';
import { ValidationError } from '../errors.js';

export class Pdf {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Generate a PDF document.
   */
  async generate(params: PdfGenerateParams, options?: RequestOptions): Promise<PdfGenerateResponse> {
    if (!params.content) {
      throw new ValidationError('content is required', 'content');
    }

    const url = `${this.client._adminBaseUrl}/api/pdf/generate`;
    return this.client._request<PdfGenerateResponse>('POST', url, {
      body: params,
      requestOptions: options,
    });
  }
}
