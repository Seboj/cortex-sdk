"""Users resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import (
    CortexUser,
    CortexUserList,
    CortexUserUpdate,
    DeleteResponse,
    PendingCount,
)


class Users:
    """Synchronous users resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> CortexUserList:
        data = self._http.request("GET", "/admin/users")
        return CortexUserList.model_validate(data)

    def pending_count(self) -> PendingCount:
        data = self._http.request("GET", "/admin/users/pending-count")
        return PendingCount.model_validate(data)

    def update(
        self,
        user_id: str,
        *,
        name: Optional[str] = None,
        role: Optional[str] = None,
        status: Optional[str] = None,
    ) -> CortexUser:
        req = CortexUserUpdate(name=name, role=role, status=status)
        data = self._http.request(
            "PATCH",
            f"/admin/users/{user_id}",
            json=req.model_dump(exclude_none=True),
        )
        return CortexUser.model_validate(data)

    def delete(self, user_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/admin/users/{user_id}")
        return DeleteResponse.model_validate(data)

    def approve(self, user_id: str) -> CortexUser:
        data = self._http.request("POST", f"/admin/users/{user_id}/approve")
        return CortexUser.model_validate(data)

    def reject(self, user_id: str) -> CortexUser:
        data = self._http.request("POST", f"/admin/users/{user_id}/reject")
        return CortexUser.model_validate(data)

    def reset_password(self, user_id: str) -> CortexUser:
        data = self._http.request("POST", f"/admin/users/{user_id}/reset-password")
        return CortexUser.model_validate(data)


class AsyncUsers:
    """Asynchronous users resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> CortexUserList:
        data = await self._http.request("GET", "/admin/users")
        return CortexUserList.model_validate(data)

    async def pending_count(self) -> PendingCount:
        data = await self._http.request("GET", "/admin/users/pending-count")
        return PendingCount.model_validate(data)

    async def update(
        self,
        user_id: str,
        *,
        name: Optional[str] = None,
        role: Optional[str] = None,
        status: Optional[str] = None,
    ) -> CortexUser:
        req = CortexUserUpdate(name=name, role=role, status=status)
        data = await self._http.request(
            "PATCH",
            f"/admin/users/{user_id}",
            json=req.model_dump(exclude_none=True),
        )
        return CortexUser.model_validate(data)

    async def delete(self, user_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/admin/users/{user_id}")
        return DeleteResponse.model_validate(data)

    async def approve(self, user_id: str) -> CortexUser:
        data = await self._http.request("POST", f"/admin/users/{user_id}/approve")
        return CortexUser.model_validate(data)

    async def reject(self, user_id: str) -> CortexUser:
        data = await self._http.request("POST", f"/admin/users/{user_id}/reject")
        return CortexUser.model_validate(data)

    async def reset_password(self, user_id: str) -> CortexUser:
        data = await self._http.request("POST", f"/admin/users/{user_id}/reset-password")
        return CortexUser.model_validate(data)
