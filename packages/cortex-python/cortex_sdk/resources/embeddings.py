"""Embeddings resource."""

from __future__ import annotations

from typing import Any, Dict, List, Literal, Optional, Union

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import EmbeddingRequest, EmbeddingResponse


def _build_payload(
    model: Optional[str],
    input: Union[str, List[str]],
    *,
    encoding_format: Optional[Literal["float", "base64"]] = None,
    user: Optional[str] = None,
    dimensions: Optional[int] = None,
) -> Dict[str, Any]:
    req = EmbeddingRequest(
        model=model,
        input=input,
        encoding_format=encoding_format,
        user=user,
        dimensions=dimensions,
    )
    return req.model_dump(exclude_none=True)


class Embeddings:
    """Synchronous embeddings."""

    def __init__(self, http: SyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    def create(
        self,
        *,
        model: Optional[str] = None,
        input: Union[str, List[str]],
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> EmbeddingResponse:
        payload = _build_payload(model, input, **kwargs)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        data = self._http.request("POST", "/embeddings", json=payload, extra_headers=extra_headers)
        return EmbeddingResponse.model_validate(data)


class AsyncEmbeddings:
    """Asynchronous embeddings."""

    def __init__(self, http: AsyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    async def create(
        self,
        *,
        model: Optional[str] = None,
        input: Union[str, List[str]],
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> EmbeddingResponse:
        payload = _build_payload(model, input, **kwargs)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        data = await self._http.request("POST", "/embeddings", json=payload, extra_headers=extra_headers)
        return EmbeddingResponse.model_validate(data)
