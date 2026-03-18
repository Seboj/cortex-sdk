"""Audit log resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import AuditLogList


class AuditLog:
    """Synchronous audit log resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self, *, limit: Optional[int] = None) -> AuditLogList:
        params = {}
        if limit is not None:
            params["limit"] = limit
        data = self._http.request("GET", "/admin/audit-log", params=params or None)
        return AuditLogList.model_validate(data)


class AsyncAuditLog:
    """Asynchronous audit log resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self, *, limit: Optional[int] = None) -> AuditLogList:
        params = {}
        if limit is not None:
            params["limit"] = limit
        data = await self._http.request("GET", "/admin/audit-log", params=params or None)
        return AuditLogList.model_validate(data)
