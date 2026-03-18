"""Internal HTTP transport with retry logic."""

from __future__ import annotations

import random
import re
import time
from typing import Any, Dict, Optional, Type, TypeVar

import httpx

from cortex_sdk.constants import (
    DEFAULT_MAX_RETRIES,
    DEFAULT_STREAMING_TIMEOUT,
    DEFAULT_TIMEOUT,
    RETRYABLE_STATUS_CODES,
)
from cortex_sdk.errors import (
    ConnectionError,
    TimeoutError,
    _raise_for_status,
)
from cortex_sdk.streaming import AsyncStream, Stream

T = TypeVar("T")

_UNSAFE_HEADER_RE = re.compile(r"[\r\n]")


def _validate_header_value(value: str) -> str:
    """Prevent header injection by rejecting CR/LF characters."""
    if _UNSAFE_HEADER_RE.search(value):
        raise ValueError("Header value contains unsafe characters (CR/LF)")
    return value


def _build_headers(api_key: str, extra: Optional[Dict[str, str]] = None) -> Dict[str, str]:
    _validate_header_value(api_key)
    headers: Dict[str, str] = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    if extra:
        for k, v in extra.items():
            _validate_header_value(v)
            headers[k] = v
    return headers


def _backoff_delay(attempt: int, retry_after: Optional[float] = None) -> float:
    """Exponential backoff with jitter, respecting Retry-After."""
    if retry_after is not None and retry_after > 0:
        return retry_after
    base = min(2 ** attempt, 60)
    jitter = random.uniform(0, base * 0.5)
    return base + jitter


class SyncHTTPClient:
    """Synchronous HTTP client with retry support."""

    def __init__(
        self,
        *,
        api_key: str,
        base_url: str,
        timeout: float = DEFAULT_TIMEOUT,
        streaming_timeout: float = DEFAULT_STREAMING_TIMEOUT,
        max_retries: int = DEFAULT_MAX_RETRIES,
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> None:
        if not base_url.startswith("https://"):
            if not base_url.startswith("http://localhost") and not base_url.startswith(
                "http://127.0.0.1"
            ):
                raise ValueError(
                    f"Base URL must use HTTPS: {base_url}"
                )
        self._api_key = api_key
        self._base_url = base_url.rstrip("/")
        self._timeout = timeout
        self._streaming_timeout = streaming_timeout
        self._max_retries = max_retries
        self._headers = _build_headers(api_key, extra_headers)
        self._client = httpx.Client(
            base_url=self._base_url,
            headers=self._headers,
            timeout=httpx.Timeout(timeout),
        )

    def request(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        params: Optional[Dict[str, Any]] = None,
        files: Optional[Any] = None,
        content: Optional[Any] = None,
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> Any:
        last_exc: Optional[Exception] = None
        for attempt in range(self._max_retries + 1):
            try:
                kwargs: Dict[str, Any] = {"params": params}
                if extra_headers:
                    kwargs["headers"] = extra_headers
                if files is not None:
                    kwargs["files"] = files
                    if content is not None:
                        kwargs["data"] = content
                else:
                    kwargs["json"] = json
                response = self._client.request(
                    method,
                    path,
                    **kwargs,
                )
                if response.status_code >= 400:
                    if (
                        response.status_code in RETRYABLE_STATUS_CODES
                        and attempt < self._max_retries
                    ):
                        retry_after_raw = response.headers.get("retry-after")
                        retry_after: Optional[float] = None
                        if retry_after_raw:
                            try:
                                retry_after = float(retry_after_raw)
                            except ValueError:
                                pass
                        time.sleep(_backoff_delay(attempt, retry_after))
                        continue
                    body = self._safe_json(response)
                    _raise_for_status(
                        response.status_code,
                        body,
                        dict(response.headers),
                    )
                return self._safe_json(response)
            except httpx.TimeoutException as exc:
                last_exc = exc
                if attempt < self._max_retries:
                    time.sleep(_backoff_delay(attempt))
                    continue
                raise TimeoutError(f"Request timed out: {exc}") from exc
            except httpx.ConnectError as exc:
                last_exc = exc
                if attempt < self._max_retries:
                    time.sleep(_backoff_delay(attempt))
                    continue
                raise ConnectionError(f"Connection failed: {exc}") from exc
        # Should not reach here, but just in case
        if last_exc:
            raise last_exc  # type: ignore[misc]

    def stream_request(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        model: Type[T],
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> Stream[T]:
        response = self._client.stream(
            method,
            path,
            json=json,
            headers=extra_headers,
            timeout=httpx.Timeout(self._streaming_timeout),
        )
        # Get the actual response object by entering the context manager
        response_cm = response.__enter__()
        if response_cm.status_code >= 400:
            body = self._safe_json(response_cm)
            response_cm.close()
            _raise_for_status(response_cm.status_code, body, dict(response_cm.headers))
        return Stream(response_cm, model)

    @staticmethod
    def _safe_json(response: httpx.Response) -> Any:
        try:
            return response.json()
        except Exception:
            return response.text or None

    def close(self) -> None:
        self._client.close()


class AsyncHTTPClient:
    """Asynchronous HTTP client with retry support."""

    def __init__(
        self,
        *,
        api_key: str,
        base_url: str,
        timeout: float = DEFAULT_TIMEOUT,
        streaming_timeout: float = DEFAULT_STREAMING_TIMEOUT,
        max_retries: int = DEFAULT_MAX_RETRIES,
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> None:
        if not base_url.startswith("https://"):
            if not base_url.startswith("http://localhost") and not base_url.startswith(
                "http://127.0.0.1"
            ):
                raise ValueError(
                    f"Base URL must use HTTPS: {base_url}"
                )
        self._api_key = api_key
        self._base_url = base_url.rstrip("/")
        self._timeout = timeout
        self._streaming_timeout = streaming_timeout
        self._max_retries = max_retries
        self._headers = _build_headers(api_key, extra_headers)
        self._client = httpx.AsyncClient(
            base_url=self._base_url,
            headers=self._headers,
            timeout=httpx.Timeout(timeout),
        )

    async def request(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        params: Optional[Dict[str, Any]] = None,
        files: Optional[Any] = None,
        content: Optional[Any] = None,
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> Any:
        import asyncio

        last_exc: Optional[Exception] = None
        for attempt in range(self._max_retries + 1):
            try:
                kwargs: Dict[str, Any] = {"params": params}
                if extra_headers:
                    kwargs["headers"] = extra_headers
                if files is not None:
                    kwargs["files"] = files
                    if content is not None:
                        kwargs["data"] = content
                else:
                    kwargs["json"] = json
                response = await self._client.request(
                    method,
                    path,
                    **kwargs,
                )
                if response.status_code >= 400:
                    if (
                        response.status_code in RETRYABLE_STATUS_CODES
                        and attempt < self._max_retries
                    ):
                        retry_after_raw = response.headers.get("retry-after")
                        retry_after: Optional[float] = None
                        if retry_after_raw:
                            try:
                                retry_after = float(retry_after_raw)
                            except ValueError:
                                pass
                        await asyncio.sleep(_backoff_delay(attempt, retry_after))
                        continue
                    body = self._safe_json(response)
                    _raise_for_status(
                        response.status_code,
                        body,
                        dict(response.headers),
                    )
                return self._safe_json(response)
            except httpx.TimeoutException as exc:
                last_exc = exc
                if attempt < self._max_retries:
                    await asyncio.sleep(_backoff_delay(attempt))
                    continue
                raise TimeoutError(f"Request timed out: {exc}") from exc
            except httpx.ConnectError as exc:
                last_exc = exc
                if attempt < self._max_retries:
                    await asyncio.sleep(_backoff_delay(attempt))
                    continue
                raise ConnectionError(f"Connection failed: {exc}") from exc
        if last_exc:
            raise last_exc  # type: ignore[misc]

    async def stream_request(
        self,
        method: str,
        path: str,
        *,
        json: Any = None,
        model: Type[T],
        extra_headers: Optional[Dict[str, str]] = None,
    ) -> AsyncStream[T]:
        response = await self._client.stream(
            method,
            path,
            json=json,
            headers=extra_headers,
            timeout=httpx.Timeout(self._streaming_timeout),
        ).__aenter__()
        if response.status_code >= 400:
            body = self._safe_json(response)
            await response.aclose()
            _raise_for_status(response.status_code, body, dict(response.headers))
        return AsyncStream(response, model)

    @staticmethod
    def _safe_json(response: httpx.Response) -> Any:
        try:
            return response.json()
        except Exception:
            return response.text or None

    async def close(self) -> None:
        await self._client.aclose()
