export const VERSION = '1.0.0' as const;

export const DEFAULT_LLM_BASE_URL = 'https://cortexapi.nfinitmonkeys.com/v1' as const;
export const DEFAULT_ADMIN_BASE_URL = 'https://admin.nfinitmonkeys.com' as const;

export const DEFAULT_TIMEOUT_MS = 30_000 as const;
export const DEFAULT_STREAM_TIMEOUT_MS = 300_000 as const;
export const DEFAULT_MAX_RETRIES = 3 as const;

export const RETRYABLE_STATUS_CODES = Object.freeze([429, 500, 502, 503, 504]);

export const INITIAL_RETRY_DELAY_MS = 500 as const;
export const MAX_RETRY_DELAY_MS = 30_000 as const;

export const DEFAULTS = Object.freeze({
  version: VERSION,
  llmBaseUrl: DEFAULT_LLM_BASE_URL,
  adminBaseUrl: DEFAULT_ADMIN_BASE_URL,
  timeoutMs: DEFAULT_TIMEOUT_MS,
  streamTimeoutMs: DEFAULT_STREAM_TIMEOUT_MS,
  maxRetries: DEFAULT_MAX_RETRIES,
  retryableStatusCodes: RETRYABLE_STATUS_CODES,
  initialRetryDelayMs: INITIAL_RETRY_DELAY_MS,
  maxRetryDelayMs: MAX_RETRY_DELAY_MS,
});
