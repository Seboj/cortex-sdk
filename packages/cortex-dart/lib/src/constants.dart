/// Default configuration constants for the Cortex SDK.
library;

/// SDK version string.
const String sdkVersion = '1.0.0';

/// Default base URL for the LLM Gateway API.
const String defaultGatewayBaseUrl = 'https://cortexapi.nfinitmonkeys.com/v1';

/// Default base URL for the Admin/Platform API.
const String defaultAdminBaseUrl = 'https://admin.nfinitmonkeys.com';

/// Default request timeout in seconds.
const int defaultTimeoutSeconds = 30;

/// Default streaming request timeout in seconds.
const int defaultStreamingTimeoutSeconds = 300;

/// Default maximum number of retries.
const int defaultMaxRetries = 3;

/// Default base delay for exponential backoff in milliseconds.
const int defaultRetryBaseDelayMs = 500;

/// Default maximum delay for exponential backoff in milliseconds.
const int defaultRetryMaxDelayMs = 30000;

/// HTTP status codes that trigger automatic retry.
const Set<int> retryableStatusCodes = {429, 500, 502, 503, 504};

/// User-Agent header value.
const String userAgent = 'cortex-dart-sdk/$sdkVersion';
