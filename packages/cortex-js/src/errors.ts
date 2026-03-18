/**
 * Base error class for all Cortex SDK errors.
 * Never exposes API keys in error messages or stack traces.
 */
export class CortexError extends Error {
  public readonly status: number | undefined;
  public readonly code: string | undefined;
  public readonly requestId: string | undefined;

  constructor(
    message: string,
    options?: {
      status?: number;
      code?: string;
      requestId?: string;
      cause?: unknown;
    },
  ) {
    super(CortexError.sanitizeMessage(message), { cause: options?.cause });
    this.name = 'CortexError';
    this.status = options?.status;
    this.code = options?.code;
    this.requestId = options?.requestId;
  }

  /**
   * Strip anything that looks like an API key from error messages.
   */
  private static sanitizeMessage(message: string): string {
    return message.replace(/sk-cortex-[a-zA-Z0-9_-]+/g, 'sk-cortex-***REDACTED***');
  }
}

export class AuthenticationError extends CortexError {
  constructor(message = 'Invalid or missing API key', requestId?: string) {
    super(message, { status: 401, code: 'authentication_error', requestId });
    this.name = 'AuthenticationError';
  }
}

export class PermissionDeniedError extends CortexError {
  constructor(message = 'Permission denied', requestId?: string) {
    super(message, { status: 403, code: 'permission_denied', requestId });
    this.name = 'PermissionDeniedError';
  }
}

export class NotFoundError extends CortexError {
  constructor(message = 'Resource not found', requestId?: string) {
    super(message, { status: 404, code: 'not_found', requestId });
    this.name = 'NotFoundError';
  }
}

export class RateLimitError extends CortexError {
  public readonly retryAfter: number | undefined;

  constructor(message = 'Rate limit exceeded', retryAfter?: number, requestId?: string) {
    super(message, { status: 429, code: 'rate_limit_exceeded', requestId });
    this.name = 'RateLimitError';
    this.retryAfter = retryAfter;
  }
}

export class ValidationError extends CortexError {
  public readonly field: string | undefined;

  constructor(message: string, field?: string) {
    super(message, { code: 'validation_error' });
    this.name = 'ValidationError';
    this.field = field;
  }
}

export class TimeoutError extends CortexError {
  constructor(message = 'Request timed out') {
    super(message, { code: 'timeout' });
    this.name = 'TimeoutError';
  }
}

export class ConnectionError extends CortexError {
  constructor(message = 'Connection failed', cause?: unknown) {
    super(message, { code: 'connection_error', cause });
    this.name = 'ConnectionError';
  }
}

export class ServerError extends CortexError {
  constructor(message: string, status: number, requestId?: string) {
    super(message, { status, code: 'server_error', requestId });
    this.name = 'ServerError';
  }
}

/**
 * Maps HTTP status codes to appropriate error classes.
 */
export function errorFromStatus(
  status: number,
  message: string,
  headers?: Headers,
  requestId?: string,
): CortexError {
  switch (status) {
    case 401:
      return new AuthenticationError(message, requestId);
    case 403:
      return new PermissionDeniedError(message, requestId);
    case 404:
      return new NotFoundError(message, requestId);
    case 429: {
      const retryAfter = headers?.get('retry-after');
      return new RateLimitError(
        message,
        retryAfter ? parseInt(retryAfter, 10) : undefined,
        requestId,
      );
    }
    default:
      if (status >= 500) {
        return new ServerError(message, status, requestId);
      }
      return new CortexError(message, { status, requestId });
  }
}
