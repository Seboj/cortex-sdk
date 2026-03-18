"""Exception hierarchy for the Cortex SDK."""

from __future__ import annotations

from typing import Any, Optional


class CortexError(Exception):
    """Base exception for all Cortex SDK errors."""

    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(message)


class APIError(CortexError):
    """Error returned by the Cortex API."""

    def __init__(
        self,
        message: str,
        *,
        status_code: int,
        body: Any = None,
        headers: Optional[dict[str, str]] = None,
    ) -> None:
        self.status_code = status_code
        self.body = body
        self.headers = headers or {}
        super().__init__(message)

    def __repr__(self) -> str:
        return f"APIError(status_code={self.status_code}, message={self.message!r})"


class AuthenticationError(APIError):
    """Raised on 401 responses."""

    def __init__(self, message: str = "Invalid API key", **kwargs: Any) -> None:
        super().__init__(message, status_code=401, **kwargs)


class PermissionDeniedError(APIError):
    """Raised on 403 responses."""

    def __init__(self, message: str = "Permission denied", **kwargs: Any) -> None:
        super().__init__(message, status_code=403, **kwargs)


class NotFoundError(APIError):
    """Raised on 404 responses."""

    def __init__(self, message: str = "Resource not found", **kwargs: Any) -> None:
        super().__init__(message, status_code=404, **kwargs)


class RateLimitError(APIError):
    """Raised on 429 responses."""

    retry_after: Optional[float]

    def __init__(
        self,
        message: str = "Rate limit exceeded",
        *,
        retry_after: Optional[float] = None,
        **kwargs: Any,
    ) -> None:
        self.retry_after = retry_after
        super().__init__(message, status_code=429, **kwargs)


class InternalServerError(APIError):
    """Raised on 5xx responses."""

    pass


class ConnectionError(CortexError):
    """Raised when the SDK cannot connect to the API."""

    pass


class TimeoutError(CortexError):
    """Raised when a request times out."""

    pass


class StreamError(CortexError):
    """Raised when a streaming response encounters an error."""

    pass


class ValidationError(CortexError):
    """Raised when request validation fails."""

    pass


def _raise_for_status(status_code: int, body: Any, headers: dict[str, str]) -> None:
    """Raise the appropriate exception for an HTTP error status code."""
    message = ""
    if isinstance(body, dict):
        error = body.get("error", {})
        if isinstance(error, dict):
            message = error.get("message", str(body))
        elif isinstance(error, str):
            message = error
        else:
            message = str(body)
    elif isinstance(body, str):
        message = body
    else:
        message = f"HTTP {status_code}"

    if status_code == 401:
        raise AuthenticationError(message, body=body, headers=headers)
    elif status_code == 403:
        raise PermissionDeniedError(message, body=body, headers=headers)
    elif status_code == 404:
        raise NotFoundError(message, body=body, headers=headers)
    elif status_code == 429:
        retry_after_raw = headers.get("retry-after")
        retry_after: Optional[float] = None
        if retry_after_raw is not None:
            try:
                retry_after = float(retry_after_raw)
            except ValueError:
                pass
        raise RateLimitError(message, retry_after=retry_after, body=body, headers=headers)
    elif status_code >= 500:
        raise InternalServerError(message, status_code=status_code, body=body, headers=headers)
    else:
        raise APIError(message, status_code=status_code, body=body, headers=headers)
