"""Default constants for the Cortex SDK."""

from __future__ import annotations

DEFAULT_LLM_BASE_URL = "https://cortexapi.nfinitmonkeys.com/v1"
DEFAULT_ADMIN_BASE_URL = "https://admin.nfinitmonkeys.com"
DEFAULT_TIMEOUT = 30.0
DEFAULT_STREAMING_TIMEOUT = 300.0
DEFAULT_MAX_RETRIES = 3
RETRYABLE_STATUS_CODES = frozenset({429, 500, 502, 503, 504})
