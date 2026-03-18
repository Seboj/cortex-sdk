"""PDF generation resource."""

from __future__ import annotations

from typing import Any, Dict, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import PDFGenerateRequest, PDFGenerateResponse


class PDF:
    """Synchronous PDF resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def generate(
        self,
        *,
        content: Optional[str] = None,
        template: Optional[str] = None,
        data: Optional[Dict[str, Any]] = None,
        options: Optional[Dict[str, Any]] = None,
    ) -> PDFGenerateResponse:
        req = PDFGenerateRequest(content=content, template=template, data=data, options=options)
        resp = self._http.request(
            "POST", "/api/pdf/generate", json=req.model_dump(exclude_none=True)
        )
        return PDFGenerateResponse.model_validate(resp)


class AsyncPDF:
    """Asynchronous PDF resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def generate(
        self,
        *,
        content: Optional[str] = None,
        template: Optional[str] = None,
        data: Optional[Dict[str, Any]] = None,
        options: Optional[Dict[str, Any]] = None,
    ) -> PDFGenerateResponse:
        req = PDFGenerateRequest(content=content, template=template, data=data, options=options)
        resp = await self._http.request(
            "POST", "/api/pdf/generate", json=req.model_dump(exclude_none=True)
        )
        return PDFGenerateResponse.model_validate(resp)
