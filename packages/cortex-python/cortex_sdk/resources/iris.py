"""Iris extraction resource."""

from __future__ import annotations

from typing import Any, Dict, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import IrisExtractionRequest, IrisJob, IrisJobList, IrisSchemaList


class Iris:
    """Synchronous Iris resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def extract(
        self,
        *,
        document: Optional[str] = None,
        document_url: Optional[str] = None,
        schema_id: Optional[str] = None,
        schema: Optional[Dict[str, Any]] = None,
        options: Optional[Dict[str, Any]] = None,
    ) -> IrisJob:
        req = IrisExtractionRequest(
            document=document,
            document_url=document_url,
            schema_id=schema_id,
            schema_def=schema,
            options=options,
        )
        data = self._http.request(
            "POST", "/api/iris/extract", json=req.model_dump(exclude_none=True, by_alias=True)
        )
        return IrisJob.model_validate(data)

    def list_jobs(self, *, limit: Optional[int] = None) -> IrisJobList:
        params: Optional[Dict[str, Any]] = None
        if limit is not None:
            params = {"limit": limit}
        data = self._http.request("GET", "/api/iris/jobs", params=params)
        return IrisJobList.model_validate(data)

    def list_schemas(self) -> IrisSchemaList:
        data = self._http.request("GET", "/api/iris/schemas")
        return IrisSchemaList.model_validate(data)


class AsyncIris:
    """Asynchronous Iris resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def extract(
        self,
        *,
        document: Optional[str] = None,
        document_url: Optional[str] = None,
        schema_id: Optional[str] = None,
        schema: Optional[Dict[str, Any]] = None,
        options: Optional[Dict[str, Any]] = None,
    ) -> IrisJob:
        req = IrisExtractionRequest(
            document=document,
            document_url=document_url,
            schema_id=schema_id,
            schema_def=schema,
            options=options,
        )
        data = await self._http.request(
            "POST", "/api/iris/extract", json=req.model_dump(exclude_none=True, by_alias=True)
        )
        return IrisJob.model_validate(data)

    async def list_jobs(self, *, limit: Optional[int] = None) -> IrisJobList:
        params: Optional[Dict[str, Any]] = None
        if limit is not None:
            params = {"limit": limit}
        data = await self._http.request("GET", "/api/iris/jobs", params=params)
        return IrisJobList.model_validate(data)

    async def list_schemas(self) -> IrisSchemaList:
        data = await self._http.request("GET", "/api/iris/schemas")
        return IrisSchemaList.model_validate(data)
