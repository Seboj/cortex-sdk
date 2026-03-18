"""API keys resource."""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import APIKey, APIKeyCreate, APIKeyList, DeleteResponse


class Keys:
    """Synchronous API keys resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> APIKeyList:
        data = self._http.request("GET", "/api/keys")
        return APIKeyList.model_validate(data)

    def create(
        self,
        *,
        name: str,
        scopes: Optional[List[str]] = None,
        expires_at: Optional[str] = None,
    ) -> APIKey:
        req = APIKeyCreate(name=name, scopes=scopes, expires_at=expires_at)
        data = self._http.request("POST", "/api/keys", json=req.model_dump(exclude_none=True))
        return APIKey.model_validate(data)

    def delete(self, key_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/api/keys/{key_id}")
        return DeleteResponse.model_validate(data)


class AsyncKeys:
    """Asynchronous API keys resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> APIKeyList:
        data = await self._http.request("GET", "/api/keys")
        return APIKeyList.model_validate(data)

    async def create(
        self,
        *,
        name: str,
        scopes: Optional[List[str]] = None,
        expires_at: Optional[str] = None,
    ) -> APIKey:
        req = APIKeyCreate(name=name, scopes=scopes, expires_at=expires_at)
        data = await self._http.request(
            "POST", "/api/keys", json=req.model_dump(exclude_none=True)
        )
        return APIKey.model_validate(data)

    async def delete(self, key_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/api/keys/{key_id}")
        return DeleteResponse.model_validate(data)
