"""Backends resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import (
    Backend,
    BackendCreate,
    BackendList,
    BackendModel,
    BackendUpdate,
    DeleteResponse,
    DiscoverModelsResponse,
)


class Backends:
    """Synchronous backends resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> BackendList:
        data = self._http.request("GET", "/admin/backends")
        return BackendList.model_validate(data)

    def create(
        self,
        *,
        name: str,
        base_url: str,
        provider: Optional[str] = None,
        enabled: Optional[bool] = None,
    ) -> Backend:
        req = BackendCreate(name=name, base_url=base_url, provider=provider, enabled=enabled)
        data = self._http.request(
            "POST", "/admin/backends", json=req.model_dump(exclude_none=True)
        )
        return Backend.model_validate(data)

    def update(
        self,
        backend_id: str,
        *,
        name: Optional[str] = None,
        base_url: Optional[str] = None,
        provider: Optional[str] = None,
        enabled: Optional[bool] = None,
    ) -> Backend:
        req = BackendUpdate(name=name, base_url=base_url, provider=provider, enabled=enabled)
        data = self._http.request(
            "PATCH",
            f"/admin/backends/{backend_id}",
            json=req.model_dump(exclude_none=True),
        )
        return Backend.model_validate(data)

    def delete(self, backend_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/admin/backends/{backend_id}")
        return DeleteResponse.model_validate(data)

    def discover(self, backend_id: str) -> DiscoverModelsResponse:
        data = self._http.request("POST", f"/admin/backends/{backend_id}/discover")
        return DiscoverModelsResponse.model_validate(data)

    def update_model(
        self, backend_id: str, model_id: str, *, display_name: str
    ) -> BackendModel:
        data = self._http.request(
            "PATCH",
            f"/admin/backends/{backend_id}/models/{model_id}",
            json={"display_name": display_name},
        )
        return BackendModel.model_validate(data)


class AsyncBackends:
    """Asynchronous backends resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> BackendList:
        data = await self._http.request("GET", "/admin/backends")
        return BackendList.model_validate(data)

    async def create(
        self,
        *,
        name: str,
        base_url: str,
        provider: Optional[str] = None,
        enabled: Optional[bool] = None,
    ) -> Backend:
        req = BackendCreate(name=name, base_url=base_url, provider=provider, enabled=enabled)
        data = await self._http.request(
            "POST", "/admin/backends", json=req.model_dump(exclude_none=True)
        )
        return Backend.model_validate(data)

    async def update(
        self,
        backend_id: str,
        *,
        name: Optional[str] = None,
        base_url: Optional[str] = None,
        provider: Optional[str] = None,
        enabled: Optional[bool] = None,
    ) -> Backend:
        req = BackendUpdate(name=name, base_url=base_url, provider=provider, enabled=enabled)
        data = await self._http.request(
            "PATCH",
            f"/admin/backends/{backend_id}",
            json=req.model_dump(exclude_none=True),
        )
        return Backend.model_validate(data)

    async def delete(self, backend_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/admin/backends/{backend_id}")
        return DeleteResponse.model_validate(data)

    async def discover(self, backend_id: str) -> DiscoverModelsResponse:
        data = await self._http.request("POST", f"/admin/backends/{backend_id}/discover")
        return DiscoverModelsResponse.model_validate(data)

    async def update_model(
        self, backend_id: str, model_id: str, *, display_name: str
    ) -> BackendModel:
        data = await self._http.request(
            "PATCH",
            f"/admin/backends/{backend_id}/models/{model_id}",
            json={"display_name": display_name},
        )
        return BackendModel.model_validate(data)
