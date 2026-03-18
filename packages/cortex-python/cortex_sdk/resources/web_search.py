"""Web search resource."""

from __future__ import annotations

from typing import Any, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import WebSearchRequest, WebSearchResponse


class WebSearch:
    """Synchronous web search resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def search(
        self,
        *,
        query: str,
        num_results: Optional[int] = None,
        language: Optional[str] = None,
        region: Optional[str] = None,
    ) -> WebSearchResponse:
        req = WebSearchRequest(
            query=query, num_results=num_results, language=language, region=region
        )
        data = self._http.request(
            "POST", "/api/web/search", json=req.model_dump(exclude_none=True)
        )
        return WebSearchResponse.model_validate(data)


class AsyncWebSearch:
    """Asynchronous web search resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def search(
        self,
        *,
        query: str,
        num_results: Optional[int] = None,
        language: Optional[str] = None,
        region: Optional[str] = None,
    ) -> WebSearchResponse:
        req = WebSearchRequest(
            query=query, num_results=num_results, language=language, region=region
        )
        data = await self._http.request(
            "POST", "/api/web/search", json=req.model_dump(exclude_none=True)
        )
        return WebSearchResponse.model_validate(data)
