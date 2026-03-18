"""Tests for Iris extraction resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import IrisJob, IrisJobList, IrisSchemaList


class TestIrisSync:
    def test_extract(self, sync_client, mock_admin):
        mock_admin.post("/api/iris/extract").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "job-1",
                    "status": "processing",
                    "document_url": "https://example.com/doc.pdf",
                },
            )
        )

        result = sync_client.iris.extract(
            document_url="https://example.com/doc.pdf",
            schema_id="schema-1",
        )
        assert isinstance(result, IrisJob)
        assert result.id == "job-1"
        assert result.status == "processing"

    def test_extract_with_schema(self, sync_client, mock_admin):
        route = mock_admin.post("/api/iris/extract").mock(
            return_value=httpx.Response(
                200, json={"id": "job-2", "status": "processing"}
            )
        )

        sync_client.iris.extract(
            document="Some document text",
            schema={"type": "object", "properties": {"name": {"type": "string"}}},
        )

        import json
        body = json.loads(route.calls.last.request.content)
        assert "schema" in body
        assert body["document"] == "Some document text"

    def test_list_jobs(self, sync_client, mock_admin):
        mock_admin.get("/api/iris/jobs").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "job-1", "status": "completed"},
                        {"id": "job-2", "status": "processing"},
                    ]
                },
            )
        )

        result = sync_client.iris.list_jobs()
        assert isinstance(result, IrisJobList)
        assert len(result.data) == 2

    def test_list_jobs_with_limit(self, sync_client, mock_admin):
        route = mock_admin.get("/api/iris/jobs").mock(
            return_value=httpx.Response(200, json={"data": [{"id": "job-1", "status": "done"}]})
        )

        sync_client.iris.list_jobs(limit=5)
        assert "limit=5" in str(route.calls.last.request.url)

    def test_list_schemas(self, sync_client, mock_admin):
        mock_admin.get("/api/iris/schemas").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "schema-1", "name": "Invoice", "description": "Invoice schema"}
                    ]
                },
            )
        )

        result = sync_client.iris.list_schemas()
        assert isinstance(result, IrisSchemaList)
        assert result.data[0].name == "Invoice"


class TestIrisAsync:
    @pytest.mark.asyncio
    async def test_extract(self, async_client, mock_admin):
        mock_admin.post("/api/iris/extract").mock(
            return_value=httpx.Response(200, json={"id": "job-1", "status": "processing"})
        )

        result = await async_client.iris.extract(document_url="https://example.com/doc.pdf")
        assert isinstance(result, IrisJob)

    @pytest.mark.asyncio
    async def test_list_jobs(self, async_client, mock_admin):
        mock_admin.get("/api/iris/jobs").mock(
            return_value=httpx.Response(200, json={"data": [{"id": "job-1", "status": "done"}]})
        )

        result = await async_client.iris.list_jobs()
        assert isinstance(result, IrisJobList)

    @pytest.mark.asyncio
    async def test_list_schemas(self, async_client, mock_admin):
        mock_admin.get("/api/iris/schemas").mock(
            return_value=httpx.Response(200, json={"data": []})
        )

        result = await async_client.iris.list_schemas()
        assert isinstance(result, IrisSchemaList)
