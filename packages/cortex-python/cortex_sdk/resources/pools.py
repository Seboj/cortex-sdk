"""Pools resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import (
    DeleteResponse,
    Pool,
    PoolBackend,
    PoolCreate,
    PoolList,
    PoolUpdate,
)


class Pools:
    """Synchronous pools resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> PoolList:
        data = self._http.request("GET", "/admin/pools")
        return PoolList.model_validate(data)

    def create(
        self,
        *,
        name: str,
        description: Optional[str] = None,
        strategy: Optional[str] = None,
    ) -> Pool:
        req = PoolCreate(name=name, description=description, strategy=strategy)
        data = self._http.request("POST", "/admin/pools", json=req.model_dump(exclude_none=True))
        return Pool.model_validate(data)

    def update(
        self,
        pool_id: str,
        *,
        name: Optional[str] = None,
        description: Optional[str] = None,
        strategy: Optional[str] = None,
    ) -> Pool:
        req = PoolUpdate(name=name, description=description, strategy=strategy)
        data = self._http.request(
            "PATCH",
            f"/admin/pools/{pool_id}",
            json=req.model_dump(exclude_none=True),
        )
        return Pool.model_validate(data)

    def delete(self, pool_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/admin/pools/{pool_id}")
        return DeleteResponse.model_validate(data)

    def add_backend(self, pool_id: str, *, backend_id: str) -> PoolBackend:
        data = self._http.request(
            "POST",
            f"/admin/pools/{pool_id}/backends",
            json={"backend_id": backend_id},
        )
        return PoolBackend.model_validate(data)

    def remove_backend(self, pool_id: str, backend_id: str) -> DeleteResponse:
        data = self._http.request(
            "DELETE", f"/admin/pools/{pool_id}/backends/{backend_id}"
        )
        return DeleteResponse.model_validate(data)


class AsyncPools:
    """Asynchronous pools resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> PoolList:
        data = await self._http.request("GET", "/admin/pools")
        return PoolList.model_validate(data)

    async def create(
        self,
        *,
        name: str,
        description: Optional[str] = None,
        strategy: Optional[str] = None,
    ) -> Pool:
        req = PoolCreate(name=name, description=description, strategy=strategy)
        data = await self._http.request(
            "POST", "/admin/pools", json=req.model_dump(exclude_none=True)
        )
        return Pool.model_validate(data)

    async def update(
        self,
        pool_id: str,
        *,
        name: Optional[str] = None,
        description: Optional[str] = None,
        strategy: Optional[str] = None,
    ) -> Pool:
        req = PoolUpdate(name=name, description=description, strategy=strategy)
        data = await self._http.request(
            "PATCH",
            f"/admin/pools/{pool_id}",
            json=req.model_dump(exclude_none=True),
        )
        return Pool.model_validate(data)

    async def delete(self, pool_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/admin/pools/{pool_id}")
        return DeleteResponse.model_validate(data)

    async def add_backend(self, pool_id: str, *, backend_id: str) -> PoolBackend:
        data = await self._http.request(
            "POST",
            f"/admin/pools/{pool_id}/backends",
            json={"backend_id": backend_id},
        )
        return PoolBackend.model_validate(data)

    async def remove_backend(self, pool_id: str, backend_id: str) -> DeleteResponse:
        data = await self._http.request(
            "DELETE", f"/admin/pools/{pool_id}/backends/{backend_id}"
        )
        return DeleteResponse.model_validate(data)
