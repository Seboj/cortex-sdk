"""Models resource."""

from __future__ import annotations

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import ModelConfigList, ModelList


class Models:
    """Synchronous models resource (LLM gateway)."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> ModelList:
        data = self._http.request("GET", "/models")
        return ModelList.model_validate(data)


class AsyncModels:
    """Asynchronous models resource (LLM gateway)."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> ModelList:
        data = await self._http.request("GET", "/models")
        return ModelList.model_validate(data)


class AdminModels:
    """Synchronous admin models config resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> ModelConfigList:
        data = self._http.request("GET", "/api/models")
        return ModelConfigList.model_validate(data)


class AsyncAdminModels:
    """Asynchronous admin models config resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> ModelConfigList:
        data = await self._http.request("GET", "/api/models")
        return ModelConfigList.model_validate(data)
