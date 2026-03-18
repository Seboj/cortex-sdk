import { describe, it, expect } from 'vitest';
import {
  CortexError,
  AuthenticationError,
  PermissionDeniedError,
  NotFoundError,
  RateLimitError,
  ValidationError,
  TimeoutError,
  ConnectionError,
  ServerError,
  errorFromStatus,
} from '../src/errors.js';

describe('Errors', () => {
  describe('CortexError', () => {
    it('creates an error with message', () => {
      const error = new CortexError('Something went wrong');
      expect(error.message).toBe('Something went wrong');
      expect(error.name).toBe('CortexError');
      expect(error).toBeInstanceOf(Error);
    });

    it('includes status and code', () => {
      const error = new CortexError('Bad request', { status: 400, code: 'bad_request' });
      expect(error.status).toBe(400);
      expect(error.code).toBe('bad_request');
    });

    it('includes requestId', () => {
      const error = new CortexError('Error', { requestId: 'req-123' });
      expect(error.requestId).toBe('req-123');
    });

    it('sanitizes API keys from messages', () => {
      const error = new CortexError(
        'Failed with key sk-cortex-abc123def456 in request',
      );
      expect(error.message).not.toContain('sk-cortex-abc123def456');
      expect(error.message).toContain('sk-cortex-***REDACTED***');
    });

    it('sanitizes multiple API keys', () => {
      const error = new CortexError(
        'Keys: sk-cortex-first and sk-cortex-second',
      );
      expect(error.message).not.toContain('sk-cortex-first');
      expect(error.message).not.toContain('sk-cortex-second');
      expect(error.message).toMatch(/sk-cortex-\*\*\*REDACTED\*\*\*.*sk-cortex-\*\*\*REDACTED\*\*\*/);
    });
  });

  describe('AuthenticationError', () => {
    it('has correct defaults', () => {
      const error = new AuthenticationError();
      expect(error.message).toBe('Invalid or missing API key');
      expect(error.status).toBe(401);
      expect(error.code).toBe('authentication_error');
      expect(error.name).toBe('AuthenticationError');
    });

    it('is instanceof CortexError', () => {
      expect(new AuthenticationError()).toBeInstanceOf(CortexError);
    });
  });

  describe('PermissionDeniedError', () => {
    it('has correct defaults', () => {
      const error = new PermissionDeniedError();
      expect(error.status).toBe(403);
      expect(error.name).toBe('PermissionDeniedError');
    });
  });

  describe('NotFoundError', () => {
    it('has correct defaults', () => {
      const error = new NotFoundError();
      expect(error.status).toBe(404);
      expect(error.name).toBe('NotFoundError');
    });
  });

  describe('RateLimitError', () => {
    it('has correct defaults', () => {
      const error = new RateLimitError();
      expect(error.status).toBe(429);
      expect(error.code).toBe('rate_limit_exceeded');
      expect(error.name).toBe('RateLimitError');
    });

    it('includes retryAfter', () => {
      const error = new RateLimitError('Too many requests', 30);
      expect(error.retryAfter).toBe(30);
    });
  });

  describe('ValidationError', () => {
    it('includes field name', () => {
      const error = new ValidationError('Invalid model', 'model');
      expect(error.field).toBe('model');
      expect(error.code).toBe('validation_error');
      expect(error.name).toBe('ValidationError');
    });
  });

  describe('TimeoutError', () => {
    it('has correct defaults', () => {
      const error = new TimeoutError();
      expect(error.message).toBe('Request timed out');
      expect(error.code).toBe('timeout');
      expect(error.name).toBe('TimeoutError');
    });
  });

  describe('ConnectionError', () => {
    it('preserves cause', () => {
      const cause = new TypeError('fetch failed');
      const error = new ConnectionError('Connection failed', cause);
      expect(error.cause).toBe(cause);
      expect(error.name).toBe('ConnectionError');
    });
  });

  describe('ServerError', () => {
    it('has correct status', () => {
      const error = new ServerError('Internal server error', 502, 'req-456');
      expect(error.status).toBe(502);
      expect(error.requestId).toBe('req-456');
      expect(error.name).toBe('ServerError');
    });
  });

  describe('errorFromStatus', () => {
    it('maps 401 to AuthenticationError', () => {
      expect(errorFromStatus(401, 'Unauthorized')).toBeInstanceOf(AuthenticationError);
    });

    it('maps 403 to PermissionDeniedError', () => {
      expect(errorFromStatus(403, 'Forbidden')).toBeInstanceOf(PermissionDeniedError);
    });

    it('maps 404 to NotFoundError', () => {
      expect(errorFromStatus(404, 'Not found')).toBeInstanceOf(NotFoundError);
    });

    it('maps 429 to RateLimitError', () => {
      const headers = new Headers({ 'retry-after': '10' });
      const error = errorFromStatus(429, 'Rate limited', headers);
      expect(error).toBeInstanceOf(RateLimitError);
      expect((error as RateLimitError).retryAfter).toBe(10);
    });

    it('maps 500+ to ServerError', () => {
      expect(errorFromStatus(500, 'Internal')).toBeInstanceOf(ServerError);
      expect(errorFromStatus(502, 'Bad Gateway')).toBeInstanceOf(ServerError);
      expect(errorFromStatus(503, 'Unavailable')).toBeInstanceOf(ServerError);
    });

    it('maps unknown status to CortexError', () => {
      const error = errorFromStatus(418, 'Teapot');
      expect(error).toBeInstanceOf(CortexError);
      expect(error.status).toBe(418);
    });
  });
});
