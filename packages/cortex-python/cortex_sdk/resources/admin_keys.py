"""Admin API keys resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import (
    AdminApiKey,
    AdminApiKeyCreate,
    AdminApiKeyList,
    AdminApiKeyUpdate,
    DeleteResponse,
)


class AdminKeys:
    """Synchronous admin API keys resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> AdminApiKeyList:
        data = self._http.request("GET", "/admin/api-keys")
        return AdminApiKeyList.model_validate(data)

    def create(
        self,
        *,
        name: str,
        expires_at: Optional[str] = None,
    ) -> AdminApiKey:
        req = AdminApiKeyCreate(name=name, expires_at=expires_at)
        data = self._http.request(
            "POST", "/admin/api-keys", json=req.model_dump(exclude_none=True)
        )
        return AdminApiKey.model_validate(data)

    def update(
        self,
        key_id: str,
        *,
        name: Optional[str] = None,
        expires_at: Optional[str] = None,
    ) -> AdminApiKey:
        req = AdminApiKeyUpdate(name=name, expires_at=expires_at)
        data = self._http.request(
            "PATCH",
            f"/admin/api-keys/{key_id}",
            json=req.model_dump(exclude_none=True),
        )
        return AdminApiKey.model_validate(data)

    def delete(self, key_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/admin/api-keys/{key_id}")
        return DeleteResponse.model_validate(data)

    def regenerate(self, key_id: str) -> AdminApiKey:
        data = self._http.request("POST", f"/admin/api-keys/{key_id}/regenerate")
        return AdminApiKey.model_validate(data)


class AsyncAdminKeys:
    """Asynchronous admin API keys resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> AdminApiKeyList:
        data = await self._http.request("GET", "/admin/api-keys")
        return AdminApiKeyList.model_validate(data)

    async def create(
        self,
        *,
        name: str,
        expires_at: Optional[str] = None,
    ) -> AdminApiKey:
        req = AdminApiKeyCreate(name=name, expires_at=expires_at)
        data = await self._http.request(
            "POST", "/admin/api-keys", json=req.model_dump(exclude_none=True)
        )
        return AdminApiKey.model_validate(data)

    async def update(
        self,
        key_id: str,
        *,
        name: Optional[str] = None,
        expires_at: Optional[str] = None,
    ) -> AdminApiKey:
        req = AdminApiKeyUpdate(name=name, expires_at=expires_at)
        data = await self._http.request(
            "PATCH",
            f"/admin/api-keys/{key_id}",
            json=req.model_dump(exclude_none=True),
        )
        return AdminApiKey.model_validate(data)

    async def delete(self, key_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/admin/api-keys/{key_id}")
        return DeleteResponse.model_validate(data)

    async def regenerate(self, key_id: str) -> AdminApiKey:
        data = await self._http.request("POST", f"/admin/api-keys/{key_id}/regenerate")
        return AdminApiKey.model_validate(data)
