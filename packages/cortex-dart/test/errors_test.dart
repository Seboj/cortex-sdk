import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('CortexException', () {
    test('has message, code, and statusCode', () {
      const e = CortexException(
        message: 'Something went wrong',
        code: 'ERR_01',
        statusCode: 400,
      );
      expect(e.message, 'Something went wrong');
      expect(e.code, 'ERR_01');
      expect(e.statusCode, 400);
    });

    test('toString does not expose sensitive info', () {
      const e = CortexException(message: 'Bad request');
      expect(e.toString(), 'CortexException(Bad request)');
    });

    test('equality', () {
      const a = CortexException(message: 'error', statusCode: 400);
      const b = CortexException(message: 'error', statusCode: 400);
      const c = CortexException(message: 'different', statusCode: 400);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CortexAuthenticationException', () {
    test('defaults', () {
      const e = CortexAuthenticationException();
      expect(e.statusCode, 401);
      expect(e.message, contains('Authentication'));
      expect(e.toString(), contains('CortexAuthenticationException'));
    });

    test('custom message', () {
      const e = CortexAuthenticationException(message: 'Invalid token');
      expect(e.message, 'Invalid token');
    });
  });

  group('CortexForbiddenException', () {
    test('defaults', () {
      const e = CortexForbiddenException();
      expect(e.statusCode, 403);
    });
  });

  group('CortexNotFoundException', () {
    test('defaults', () {
      const e = CortexNotFoundException();
      expect(e.statusCode, 404);
    });
  });

  group('CortexRateLimitException', () {
    test('includes retry-after', () {
      const e = CortexRateLimitException(
        retryAfter: Duration(seconds: 30),
      );
      expect(e.statusCode, 429);
      expect(e.retryAfter, const Duration(seconds: 30));
    });

    test('equality includes retryAfter', () {
      const a = CortexRateLimitException(retryAfter: Duration(seconds: 30));
      const b = CortexRateLimitException(retryAfter: Duration(seconds: 30));
      const c = CortexRateLimitException(retryAfter: Duration(seconds: 60));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CortexServerException', () {
    test('defaults to 500', () {
      const e = CortexServerException();
      expect(e.statusCode, 500);
    });

    test('custom status code', () {
      const e = CortexServerException(statusCode: 503);
      expect(e.statusCode, 503);
    });
  });

  group('CortexValidationException', () {
    test('includes parameter name', () {
      const e = CortexValidationException(
        message: 'Must not be empty',
        parameter: 'model',
      );
      expect(e.parameter, 'model');
      expect(e.toString(), contains('model'));
      expect(e.toString(), contains('Must not be empty'));
    });

    test('equality includes parameter', () {
      const a = CortexValidationException(
        message: 'err',
        parameter: 'model',
      );
      const b = CortexValidationException(
        message: 'err',
        parameter: 'model',
      );
      const c = CortexValidationException(
        message: 'err',
        parameter: 'prompt',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CortexTimeoutException', () {
    test('defaults', () {
      const e = CortexTimeoutException();
      expect(e.message, contains('timed out'));
    });
  });

  group('CortexConnectionException', () {
    test('defaults', () {
      const e = CortexConnectionException();
      expect(e.message, contains('Connection'));
    });
  });

  group('CortexStreamException', () {
    test('defaults', () {
      const e = CortexStreamException();
      expect(e.message, contains('Stream'));
    });
  });

  group('exceptionFromStatusCode', () {
    test('maps 401 to CortexAuthenticationException', () {
      final e = exceptionFromStatusCode(401, 'Unauthorized');
      expect(e, isA<CortexAuthenticationException>());
      expect(e.message, 'Unauthorized');
    });

    test('maps 403 to CortexForbiddenException', () {
      final e = exceptionFromStatusCode(403, 'Forbidden');
      expect(e, isA<CortexForbiddenException>());
    });

    test('maps 404 to CortexNotFoundException', () {
      final e = exceptionFromStatusCode(404, 'Not found');
      expect(e, isA<CortexNotFoundException>());
    });

    test('maps 429 to CortexRateLimitException with retryAfter', () {
      final e = exceptionFromStatusCode(
        429,
        'Rate limited',
        retryAfter: const Duration(seconds: 10),
      );
      expect(e, isA<CortexRateLimitException>());
      expect((e as CortexRateLimitException).retryAfter,
          const Duration(seconds: 10));
    });

    test('maps 500 to CortexServerException', () {
      final e = exceptionFromStatusCode(500, 'Server error');
      expect(e, isA<CortexServerException>());
    });

    test('maps 502 to CortexServerException', () {
      final e = exceptionFromStatusCode(502, 'Bad gateway');
      expect(e, isA<CortexServerException>());
      expect(e.statusCode, 502);
    });

    test('maps unknown status to CortexException', () {
      final e = exceptionFromStatusCode(422, 'Unprocessable');
      expect(e, isA<CortexException>());
      expect(e, isNot(isA<CortexServerException>()));
      expect(e.statusCode, 422);
    });

    test('uses HTTP status as message when body is empty', () {
      final e = exceptionFromStatusCode(500, '');
      expect(e.message, 'HTTP 500');
    });
  });
}
