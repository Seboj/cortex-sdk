"""SSE stream handling for the Cortex SDK."""

from __future__ import annotations

import json
from typing import Any, AsyncIterator, Generic, Iterator, Type, TypeVar

import httpx

from cortex_sdk.errors import StreamError

T = TypeVar("T")


class Stream(Generic[T]):
    """Synchronous SSE stream wrapper.

    Iterates over an ``httpx.Response`` with ``stream=True``, parsing each
    ``data:`` line into the given Pydantic model.
    """

    def __init__(self, response: httpx.Response, model: Type[T]) -> None:
        self._response = response
        self._model = model
        self._iterator: Iterator[str] | None = None

    def __iter__(self) -> Iterator[T]:
        return self._iter_events()

    def _iter_events(self) -> Iterator[T]:
        try:
            for line in self._response.iter_lines():
                parsed = self._parse_line(line)
                if parsed is not None:
                    yield parsed
        except httpx.StreamError as exc:
            raise StreamError(f"Stream connection error: {exc}") from exc
        finally:
            self._response.close()

    def _parse_line(self, line: str) -> T | None:
        line = line.strip()
        if not line:
            return None
        if line.startswith("data:"):
            data = line[len("data:"):].strip()
            if data == "[DONE]":
                return None
            try:
                payload = json.loads(data)
            except json.JSONDecodeError as exc:
                raise StreamError(f"Failed to parse SSE data: {exc}") from exc
            return self._model.model_validate(payload)  # type: ignore[union-attr]
        return None

    def close(self) -> None:
        self._response.close()

    def __enter__(self) -> Stream[T]:
        return self

    def __exit__(self, *args: Any) -> None:
        self.close()


class AsyncStream(Generic[T]):
    """Asynchronous SSE stream wrapper."""

    def __init__(self, response: httpx.Response, model: Type[T]) -> None:
        self._response = response
        self._model = model

    def __aiter__(self) -> AsyncIterator[T]:
        return self._iter_events()

    async def _iter_events(self) -> AsyncIterator[T]:
        try:
            async for line in self._response.aiter_lines():
                parsed = self._parse_line(line)
                if parsed is not None:
                    yield parsed
        except httpx.StreamError as exc:
            raise StreamError(f"Stream connection error: {exc}") from exc
        finally:
            await self._response.aclose()

    def _parse_line(self, line: str) -> T | None:
        line = line.strip()
        if not line:
            return None
        if line.startswith("data:"):
            data = line[len("data:"):].strip()
            if data == "[DONE]":
                return None
            try:
                payload = json.loads(data)
            except json.JSONDecodeError as exc:
                raise StreamError(f"Failed to parse SSE data: {exc}") from exc
            return self._model.model_validate(payload)  # type: ignore[union-attr]
        return None

    async def close(self) -> None:
        await self._response.aclose()

    async def __aenter__(self) -> AsyncStream[T]:
        return self

    async def __aexit__(self, *args: Any) -> None:
        await self.close()
