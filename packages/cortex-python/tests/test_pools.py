"""Tests for pools resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import DeleteResponse, Pool, PoolBackend, PoolList


class TestPoolsSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/admin/pools").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "pool-1", "name": "Default Pool", "strategy": "round-robin"},
                        {"id": "pool-2", "name": "Fast Pool", "strategy": "least-latency"},
                    ]
                },
            )
        )

        result = sync_client.pools.list()
        assert isinstance(result, PoolList)
        assert len(result.data) == 2
        assert result.data[0].id == "pool-1"
        assert result.data[0].strategy == "round-robin"

    def test_create(self, sync_client, mock_admin):
        mock_admin.post("/admin/pools").mock(
            return_value=httpx.Response(
                200,
                json={"id": "pool-new", "name": "My Pool", "strategy": "round-robin"},
            )
        )

        result = sync_client.pools.create(name="My Pool", strategy="round-robin")
        assert isinstance(result, Pool)
        assert result.id == "pool-new"
        assert result.name == "My Pool"

    def test_update(self, sync_client, mock_admin):
        mock_admin.patch("/admin/pools/pool-1").mock(
            return_value=httpx.Response(
                200,
                json={"id": "pool-1", "name": "Updated Pool", "strategy": "least-latency"},
            )
        )

        result = sync_client.pools.update("pool-1", name="Updated Pool")
        assert isinstance(result, Pool)
        assert result.name == "Updated Pool"

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/admin/pools/pool-1").mock(
            return_value=httpx.Response(200, json={"id": "pool-1", "deleted": True})
        )

        result = sync_client.pools.delete("pool-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True

    def test_add_backend(self, sync_client, mock_admin):
        mock_admin.post("/admin/pools/pool-1/backends").mock(
            return_value=httpx.Response(
                200,
                json={"id": "be-1", "name": "OpenAI", "base_url": "https://api.openai.com"},
            )
        )

        result = sync_client.pools.add_backend("pool-1", backend_id="be-1")
        assert isinstance(result, PoolBackend)
        assert result.id == "be-1"

    def test_remove_backend(self, sync_client, mock_admin):
        mock_admin.delete("/admin/pools/pool-1/backends/be-1").mock(
            return_value=httpx.Response(200, json={"id": "be-1", "deleted": True})
        )

        result = sync_client.pools.remove_backend("pool-1", "be-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True


class TestPoolsAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/admin/pools").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "pool-1", "name": "Default"}]}
            )
        )

        result = await async_client.pools.list()
        assert isinstance(result, PoolList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_admin):
        mock_admin.post("/admin/pools").mock(
            return_value=httpx.Response(200, json={"id": "pool-new", "name": "New Pool"})
        )

        result = await async_client.pools.create(name="New Pool")
        assert isinstance(result, Pool)
        assert result.id == "pool-new"

    @pytest.mark.asyncio
    async def test_delete(self, async_client, mock_admin):
        mock_admin.delete("/admin/pools/pool-1").mock(
            return_value=httpx.Response(200, json={"id": "pool-1", "deleted": True})
        )

        result = await async_client.pools.delete("pool-1")
        assert result.deleted is True
