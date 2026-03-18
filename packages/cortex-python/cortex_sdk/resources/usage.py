"""Usage resource."""

from __future__ import annotations

from typing import Any, Dict, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import UsageLimits, UsageStats


class Usage:
    """Synchronous usage resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def get(self, *, params: Optional[Dict[str, Any]] = None) -> UsageStats:
        data = self._http.request("GET", "/api/usage", params=params)
        return UsageStats.model_validate(data)

    def limits(self) -> UsageLimits:
        data = self._http.request("GET", "/api/usage/limits")
        return UsageLimits.model_validate(data)


class AsyncUsage:
    """Asynchronous usage resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def get(self, *, params: Optional[Dict[str, Any]] = None) -> UsageStats:
        data = await self._http.request("GET", "/api/usage", params=params)
        return UsageStats.model_validate(data)

    async def limits(self) -> UsageLimits:
        data = await self._http.request("GET", "/api/usage/limits")
        return UsageLimits.model_validate(data)
