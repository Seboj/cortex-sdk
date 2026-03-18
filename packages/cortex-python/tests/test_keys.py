"""Tests for API keys resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import APIKey, APIKeyList, DeleteResponse


class TestKeysSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/api/keys").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "key-1", "name": "Test Key", "status": "active"},
                        {"id": "key-2", "name": "Other Key", "status": "revoked"},
                    ]
                },
            )
        )

        result = sync_client.keys.list()
        assert isinstance(result, APIKeyList)
        assert len(result.data) == 2
        assert result.data[0].id == "key-1"

    def test_create(self, sync_client, mock_admin):
        mock_admin.post("/api/keys").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "key-new",
                    "name": "My Key",
                    "key": "sk-cortex-new-key",
                    "status": "active",
                },
            )
        )

        result = sync_client.keys.create(name="My Key", scopes=["chat", "embeddings"])
        assert isinstance(result, APIKey)
        assert result.id == "key-new"
        assert result.name == "My Key"

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/api/keys/key-1").mock(
            return_value=httpx.Response(200, json={"id": "key-1", "deleted": True})
        )

        result = sync_client.keys.delete("key-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True


class TestKeysAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/api/keys").mock(
            return_value=httpx.Response(200, json={"data": [{"id": "key-1", "name": "Test"}]})
        )

        result = await async_client.keys.list()
        assert isinstance(result, APIKeyList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_admin):
        mock_admin.post("/api/keys").mock(
            return_value=httpx.Response(
                200, json={"id": "key-new", "name": "New Key", "key": "sk-cortex-xxx"}
            )
        )

        result = await async_client.keys.create(name="New Key")
        assert isinstance(result, APIKey)
        assert result.id == "key-new"

    @pytest.mark.asyncio
    async def test_delete(self, async_client, mock_admin):
        mock_admin.delete("/api/keys/key-1").mock(
            return_value=httpx.Response(200, json={"id": "key-1", "deleted": True})
        )

        result = await async_client.keys.delete("key-1")
        assert result.deleted is True
