"""Usage limits resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import (
    DeleteResponse,
    UsageLimit,
    UsageLimitList,
    UsageLimitSet,
)


class UsageLimitsAdmin:
    """Synchronous usage limits resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> UsageLimitList:
        data = self._http.request("GET", "/admin/usage-limits")
        return UsageLimitList.model_validate(data)

    def set_user_limits(
        self,
        user_id: str,
        *,
        requests_per_minute: Optional[int] = None,
        requests_per_day: Optional[int] = None,
        tokens_per_minute: Optional[int] = None,
        tokens_per_day: Optional[int] = None,
    ) -> UsageLimit:
        req = UsageLimitSet(
            requests_per_minute=requests_per_minute,
            requests_per_day=requests_per_day,
            tokens_per_minute=tokens_per_minute,
            tokens_per_day=tokens_per_day,
        )
        data = self._http.request(
            "PUT",
            f"/admin/usage-limits/user/{user_id}",
            json=req.model_dump(exclude_none=True),
        )
        return UsageLimit.model_validate(data)

    def remove_user_limits(self, user_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/admin/usage-limits/user/{user_id}")
        return DeleteResponse.model_validate(data)

    def remove_team_limits(self, team_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/admin/usage-limits/team/{team_id}")
        return DeleteResponse.model_validate(data)


class AsyncUsageLimitsAdmin:
    """Asynchronous usage limits resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> UsageLimitList:
        data = await self._http.request("GET", "/admin/usage-limits")
        return UsageLimitList.model_validate(data)

    async def set_user_limits(
        self,
        user_id: str,
        *,
        requests_per_minute: Optional[int] = None,
        requests_per_day: Optional[int] = None,
        tokens_per_minute: Optional[int] = None,
        tokens_per_day: Optional[int] = None,
    ) -> UsageLimit:
        req = UsageLimitSet(
            requests_per_minute=requests_per_minute,
            requests_per_day=requests_per_day,
            tokens_per_minute=tokens_per_minute,
            tokens_per_day=tokens_per_day,
        )
        data = await self._http.request(
            "PUT",
            f"/admin/usage-limits/user/{user_id}",
            json=req.model_dump(exclude_none=True),
        )
        return UsageLimit.model_validate(data)

    async def remove_user_limits(self, user_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/admin/usage-limits/user/{user_id}")
        return DeleteResponse.model_validate(data)

    async def remove_team_limits(self, team_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/admin/usage-limits/team/{team_id}")
        return DeleteResponse.model_validate(data)
