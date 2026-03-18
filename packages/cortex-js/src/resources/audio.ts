import type { CortexClient } from '../client.js';
import type { AudioTranscriptionParams, AudioTranscription, RequestOptions } from '../types.js';
import { ValidationError } from '../errors.js';

export interface AudioTranscribeOptions extends RequestOptions {
  /** Pool slug for routing this request. Overrides client-level defaultPool. */
  pool?: string;
}

export class Audio {
  private client: CortexClient;

  constructor(client: CortexClient) {
    this.client = client;
  }

  /**
   * Transcribe an audio file.
   */
  async transcribe(
    params: AudioTranscriptionParams,
    options?: AudioTranscribeOptions,
  ): Promise<AudioTranscription> {
    if (!params.file) {
      throw new ValidationError('file is required', 'file');
    }
    if (params.model !== undefined && params.model === '') {
      throw new ValidationError('model must not be empty when provided', 'model');
    }

    const formData = new FormData();
    formData.append('file', params.file);
    if (params.model) {
      formData.append('model', params.model);
    }

    if (params.language !== undefined) {
      formData.append('language', params.language);
    }
    if (params.prompt !== undefined) {
      formData.append('prompt', params.prompt);
    }
    if (params.response_format !== undefined) {
      formData.append('response_format', params.response_format);
    }
    if (params.temperature !== undefined) {
      formData.append('temperature', String(params.temperature));
    }

    // Resolve pool: per-request > client default > none
    const pool = options?.pool ?? this.client._defaultPool;
    const poolHeaders: Record<string, string> = {};
    if (pool) {
      poolHeaders['x-cortex-pool'] = pool;
    }

    const requestOptions: RequestOptions = {
      ...options,
      headers: { ...poolHeaders, ...options?.headers },
    };

    const url = `${this.client._llmBaseUrl}/audio/transcriptions`;
    return this.client._requestFormData<AudioTranscription>('POST', url, formData, {
      requestOptions,
    });
  }
}
