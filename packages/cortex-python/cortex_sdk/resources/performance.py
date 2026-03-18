"""Performance metrics resource."""

from __future__ import annotations

from typing import Any, Dict, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import PerformanceMetrics


class Performance:
    """Synchronous performance resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def get(self, *, params: Optional[Dict[str, Any]] = None) -> PerformanceMetrics:
        data = self._http.request("GET", "/api/performance", params=params)
        return PerformanceMetrics.model_validate(data)


class AsyncPerformance:
    """Asynchronous performance resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def get(self, *, params: Optional[Dict[str, Any]] = None) -> PerformanceMetrics:
        data = await self._http.request("GET", "/api/performance", params=params)
        return PerformanceMetrics.model_validate(data)
