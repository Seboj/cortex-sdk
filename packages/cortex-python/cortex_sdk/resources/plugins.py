"""Plugins resource."""

from __future__ import annotations

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import OptimizationSettings, PluginList


class Plugins:
    """Synchronous plugins resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> PluginList:
        data = self._http.request("GET", "/api/plugins")
        return PluginList.model_validate(data)


class AsyncPlugins:
    """Asynchronous plugins resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> PluginList:
        data = await self._http.request("GET", "/api/plugins")
        return PluginList.model_validate(data)


class Optimizations:
    """Synchronous optimizations resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def get(self) -> OptimizationSettings:
        data = self._http.request("GET", "/api/optimizations")
        return OptimizationSettings.model_validate(data)


class AsyncOptimizations:
    """Asynchronous optimizations resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def get(self) -> OptimizationSettings:
        data = await self._http.request("GET", "/api/optimizations")
        return OptimizationSettings.model_validate(data)
