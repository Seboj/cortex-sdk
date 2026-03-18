import {
  DEFAULT_LLM_BASE_URL,
  DEFAULT_ADMIN_BASE_URL,
  DEFAULT_TIMEOUT_MS,
  DEFAULT_STREAM_TIMEOUT_MS,
  DEFAULT_MAX_RETRIES,
  RETRYABLE_STATUS_CODES,
  INITIAL_RETRY_DELAY_MS,
  MAX_RETRY_DELAY_MS,
  VERSION,
} from './constants.js';
import {
  CortexError,
  AuthenticationError,
  ValidationError,
  TimeoutError,
  ConnectionError,
  errorFromStatus,
} from './errors.js';
import { SSEStream } from './streaming.js';
import { Chat } from './resources/chat.js';
import { Completions } from './resources/completions.js';
import { Embeddings } from './resources/embeddings.js';
import { Models } from './resources/models.js';
import { Keys } from './resources/keys.js';
import { Teams } from './resources/teams.js';
import { Usage } from './resources/usage.js';
import { Performance } from './resources/performance.js';
import { Conversations } from './resources/conversations.js';
import { Iris } from './resources/iris.js';
import { Plugins } from './resources/plugins.js';
import { Pdf } from './resources/pdf.js';
import { WebSearch } from './resources/web-search.js';
import { Pools } from './resources/pools.js';
import { Backends } from './resources/backends.js';
import { Users } from './resources/users.js';
import { UsageLimitsResource } from './resources/usage-limits.js';
import { AdminKeys } from './resources/admin-keys.js';
import { AuditLog } from './resources/audit-log.js';
import { Auth } from './resources/auth.js';
import { Audio } from './resources/audio.js';
import type { CortexClientOptions, RequestOptions } from './types.js';

// Header injection prevention: reject values with newlines
function validateHeaderValue(key: string, value: string): void {
  if (/[\r\n]/.test(value)) {
    throw new ValidationError(`Header value for "${key}" contains invalid characters`);
  }
}

// Validate base URL to prevent SSRF
function validateBaseUrl(url: string, name: string): string {
  try {
    const parsed = new URL(url);
    if (!['https:', 'http:'].includes(parsed.protocol)) {
      throw new ValidationError(`${name} must use HTTP or HTTPS protocol`);
    }
    // Strip trailing slashes for consistency
    return parsed.origin + parsed.pathname.replace(/\/+$/, '');
  } catch (error) {
    if (error instanceof ValidationError) throw error;
    throw new ValidationError(`Invalid ${name}: ${url}`);
  }
}

export class CortexClient {
  /** @internal */
  readonly _apiKey: string;
  /** @internal */
  readonly _llmBaseUrl: string;
  /** @internal */
  readonly _adminBaseUrl: string;
  /** @internal */
  readonly _timeout: number;
  /** @internal */
  readonly _streamTimeout: number;
  /** @internal */
  readonly _maxRetries: number;
  /** @internal */
  readonly _fetch: typeof globalThis.fetch;
  /** @internal */
  readonly _defaultHeaders: Readonly<Record<string, string>>;
  /** @internal */
  readonly _defaultPool: string | undefined;

  // ── Resource namespaces ──────────────────────────────────────────────
  readonly chat: Chat;
  readonly completions: Completions;
  readonly embeddings: Embeddings;
  readonly models: Models;
  readonly keys: Keys;
  readonly teams: Teams;
  readonly usage: Usage;
  readonly performance: Performance;
  readonly conversations: Conversations;
  readonly iris: Iris;
  readonly plugins: Plugins;
  readonly pdf: Pdf;
  readonly webSearch: WebSearch;
  readonly pools: Pools;
  readonly backends: Backends;
  readonly users: Users;
  readonly usageLimits: UsageLimitsResource;
  readonly adminKeys: AdminKeys;
  readonly auditLog: AuditLog;
  readonly auth: Auth;
  readonly audio: Audio;

  constructor(options: CortexClientOptions) {
    // ── Validate required params ─────────────────────────────────────
    if (!options.apiKey) {
      throw new AuthenticationError('API key is required');
    }
    if (typeof options.apiKey !== 'string') {
      throw new ValidationError('API key must be a string');
    }

    this._apiKey = options.apiKey;
    this._llmBaseUrl = validateBaseUrl(
      options.llmBaseUrl ?? DEFAULT_LLM_BASE_URL,
      'llmBaseUrl',
    );
    this._adminBaseUrl = validateBaseUrl(
      options.adminBaseUrl ?? DEFAULT_ADMIN_BASE_URL,
      'adminBaseUrl',
    );
    this._timeout = options.timeout ?? DEFAULT_TIMEOUT_MS;
    this._streamTimeout = options.streamTimeout ?? DEFAULT_STREAM_TIMEOUT_MS;
    this._maxRetries = options.maxRetries ?? DEFAULT_MAX_RETRIES;
    this._fetch = options.fetch ?? globalThis.fetch.bind(globalThis);

    // Validate custom headers
    const defaultHeaders: Record<string, string> = {};
    if (options.defaultHeaders) {
      for (const [key, value] of Object.entries(options.defaultHeaders)) {
        validateHeaderValue(key, value);
        defaultHeaders[key] = value;
      }
    }
    this._defaultHeaders = Object.freeze(defaultHeaders);
    this._defaultPool = options.defaultPool;

    // ── Initialize resource namespaces ───────────────────────────────
    this.chat = new Chat(this);
    this.completions = new Completions(this);
    this.embeddings = new Embeddings(this);
    this.models = new Models(this);
    this.keys = new Keys(this);
    this.teams = new Teams(this);
    this.usage = new Usage(this);
    this.performance = new Performance(this);
    this.conversations = new Conversations(this);
    this.iris = new Iris(this);
    this.plugins = new Plugins(this);
    this.pdf = new Pdf(this);
    this.webSearch = new WebSearch(this);
    this.pools = new Pools(this);
    this.backends = new Backends(this);
    this.users = new Users(this);
    this.usageLimits = new UsageLimitsResource(this);
    this.adminKeys = new AdminKeys(this);
    this.auditLog = new AuditLog(this);
    this.auth = new Auth(this);
    this.audio = new Audio(this);

    // Freeze the client to prevent mutation after construction
    Object.freeze(this);
  }

  /**
   * Make an authenticated request to the API.
   * Handles retries, timeouts, and error mapping.
   * @internal
   */
  async _request<T>(
    method: string,
    url: string,
    options?: {
      body?: unknown;
      query?: Record<string, string | number | undefined>;
      stream?: boolean;
      requestOptions?: RequestOptions;
    },
  ): Promise<T> {
    const isStream = options?.stream === true;
    const timeoutMs = options?.requestOptions?.timeout
      ?? (isStream ? this._streamTimeout : this._timeout);

    // Build URL with query parameters
    let fullUrl = url;
    if (options?.query) {
      const params = new URLSearchParams();
      for (const [key, value] of Object.entries(options.query)) {
        if (value !== undefined) {
          params.set(key, String(value));
        }
      }
      const queryString = params.toString();
      if (queryString) {
        fullUrl += `?${queryString}`;
      }
    }

    // Build headers
    const headers: Record<string, string> = {
      ...this._defaultHeaders,
      ...options?.requestOptions?.headers,
      'Authorization': `Bearer ${this._apiKey}`,
      'User-Agent': `cortex-sdk-js/${VERSION}`,
    };

    if (options?.body !== undefined) {
      headers['Content-Type'] = 'application/json';
    }

    if (isStream) {
      headers['Accept'] = 'text/event-stream';
    }

    let lastError: CortexError | undefined;

    for (let attempt = 0; attempt <= this._maxRetries; attempt++) {
      // Set up abort controller for timeout
      const abortController = new AbortController();
      const externalSignal = options?.requestOptions?.signal;

      // Link external signal
      if (externalSignal?.aborted) {
        throw new CortexError('Request was aborted');
      }

      let externalAbortHandler: (() => void) | undefined;
      if (externalSignal) {
        externalAbortHandler = () => abortController.abort();
        externalSignal.addEventListener('abort', externalAbortHandler, { once: true });
      }

      const timeoutId = setTimeout(() => abortController.abort(), timeoutMs);

      try {
        const response = await this._fetch(fullUrl, {
          method,
          headers,
          body: options?.body !== undefined ? JSON.stringify(options.body) : undefined,
          signal: abortController.signal,
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          const requestId = response.headers.get('x-request-id') ?? undefined;
          let errorMessage: string;
          try {
            const errorBody = await response.json() as { error?: { message?: string }; message?: string };
            errorMessage = errorBody.error?.message ?? errorBody.message ?? `HTTP ${response.status}`;
          } catch {
            errorMessage = `HTTP ${response.status} ${response.statusText}`;
          }

          const error = errorFromStatus(response.status, errorMessage, response.headers, requestId);

          // Retry on retryable status codes
          if (RETRYABLE_STATUS_CODES.includes(response.status) && attempt < this._maxRetries) {
            lastError = error;
            await this._retryDelay(attempt, response.headers);
            continue;
          }

          throw error;
        }

        // Streaming response
        if (isStream) {
          return new SSEStream(response, abortController) as unknown as T;
        }

        // Regular JSON response
        const data = await response.json();
        return data as T;
      } catch (error) {
        clearTimeout(timeoutId);

        if (externalAbortHandler && externalSignal) {
          externalSignal.removeEventListener('abort', externalAbortHandler);
        }

        if (error instanceof CortexError) {
          throw error;
        }

        if (error instanceof DOMException && error.name === 'AbortError') {
          if (externalSignal?.aborted) {
            throw new CortexError('Request was aborted');
          }
          throw new TimeoutError(`Request timed out after ${timeoutMs}ms`);
        }

        if (attempt < this._maxRetries) {
          lastError = new ConnectionError(
            error instanceof Error ? error.message : 'Unknown error',
            error,
          );
          await this._retryDelay(attempt);
          continue;
        }

        throw new ConnectionError(
          error instanceof Error ? error.message : 'Unknown error',
          error,
        );
      }
    }

    throw lastError ?? new CortexError('Request failed after all retries');
  }

  /**
   * Make an authenticated multipart/form-data request to the API.
   * @internal
   */
  async _requestFormData<T>(
    method: string,
    url: string,
    formData: FormData,
    options?: { requestOptions?: RequestOptions },
  ): Promise<T> {
    const timeoutMs = options?.requestOptions?.timeout ?? this._timeout;

    const headers: Record<string, string> = {
      ...this._defaultHeaders,
      ...options?.requestOptions?.headers,
      'Authorization': `Bearer ${this._apiKey}`,
      'User-Agent': `cortex-sdk-js/${VERSION}`,
      // Note: Content-Type is intentionally NOT set — the fetch API
      // sets the correct multipart boundary automatically.
    };

    let lastError: CortexError | undefined;

    for (let attempt = 0; attempt <= this._maxRetries; attempt++) {
      const abortController = new AbortController();
      const externalSignal = options?.requestOptions?.signal;

      if (externalSignal?.aborted) {
        throw new CortexError('Request was aborted');
      }

      let externalAbortHandler: (() => void) | undefined;
      if (externalSignal) {
        externalAbortHandler = () => abortController.abort();
        externalSignal.addEventListener('abort', externalAbortHandler, { once: true });
      }

      const timeoutId = setTimeout(() => abortController.abort(), timeoutMs);

      try {
        const response = await this._fetch(url, {
          method,
          headers,
          body: formData,
          signal: abortController.signal,
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          const requestId = response.headers.get('x-request-id') ?? undefined;
          let errorMessage: string;
          try {
            const errorBody = await response.json() as { error?: { message?: string }; message?: string };
            errorMessage = errorBody.error?.message ?? errorBody.message ?? `HTTP ${response.status}`;
          } catch {
            errorMessage = `HTTP ${response.status} ${response.statusText}`;
          }

          const error = errorFromStatus(response.status, errorMessage, response.headers, requestId);

          if (RETRYABLE_STATUS_CODES.includes(response.status) && attempt < this._maxRetries) {
            lastError = error;
            await this._retryDelay(attempt, response.headers);
            continue;
          }

          throw error;
        }

        const data = await response.json();
        return data as T;
      } catch (error) {
        clearTimeout(timeoutId);

        if (externalAbortHandler && externalSignal) {
          externalSignal.removeEventListener('abort', externalAbortHandler);
        }

        if (error instanceof CortexError) {
          throw error;
        }

        if (error instanceof DOMException && error.name === 'AbortError') {
          if (externalSignal?.aborted) {
            throw new CortexError('Request was aborted');
          }
          throw new TimeoutError(`Request timed out after ${timeoutMs}ms`);
        }

        if (attempt < this._maxRetries) {
          lastError = new ConnectionError(
            error instanceof Error ? error.message : 'Unknown error',
            error,
          );
          await this._retryDelay(attempt);
          continue;
        }

        throw new ConnectionError(
          error instanceof Error ? error.message : 'Unknown error',
          error,
        );
      }
    }

    throw lastError ?? new CortexError('Request failed after all retries');
  }

  /**
   * Calculate and wait for retry delay with exponential backoff + jitter.
   * @internal
   */
  private async _retryDelay(attempt: number, headers?: Headers): Promise<void> {
    // Respect Retry-After header if present
    const retryAfter = headers?.get('retry-after');
    if (retryAfter) {
      const retryAfterMs = parseInt(retryAfter, 10) * 1000;
      if (!isNaN(retryAfterMs) && retryAfterMs > 0) {
        await sleep(Math.min(retryAfterMs, MAX_RETRY_DELAY_MS));
        return;
      }
    }

    // Exponential backoff with jitter
    const baseDelay = INITIAL_RETRY_DELAY_MS * Math.pow(2, attempt);
    const jitter = Math.random() * baseDelay * 0.5;
    const delay = Math.min(baseDelay + jitter, MAX_RETRY_DELAY_MS);
    await sleep(delay);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
