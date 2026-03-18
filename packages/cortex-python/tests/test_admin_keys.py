"""Tests for admin API keys resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import AdminApiKey, AdminApiKeyList, DeleteResponse


class TestAdminKeysSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/admin/api-keys").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "ak-1", "name": "Production Key", "status": "active"},
                        {"id": "ak-2", "name": "Staging Key", "status": "active"},
                    ]
                },
            )
        )

        result = sync_client.admin_keys.list()
        assert isinstance(result, AdminApiKeyList)
        assert len(result.data) == 2
        assert result.data[0].name == "Production Key"

    def test_create(self, sync_client, mock_admin):
        mock_admin.post("/admin/api-keys").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "ak-new",
                    "name": "New Admin Key",
                    "key": "sk-admin-xxx",
                    "status": "active",
                },
            )
        )

        result = sync_client.admin_keys.create(name="New Admin Key")
        assert isinstance(result, AdminApiKey)
        assert result.id == "ak-new"
        assert result.key == "sk-admin-xxx"

    def test_update(self, sync_client, mock_admin):
        mock_admin.patch("/admin/api-keys/ak-1").mock(
            return_value=httpx.Response(
                200,
                json={"id": "ak-1", "name": "Renamed Key", "status": "active"},
            )
        )

        result = sync_client.admin_keys.update("ak-1", name="Renamed Key")
        assert isinstance(result, AdminApiKey)
        assert result.name == "Renamed Key"

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/admin/api-keys/ak-1").mock(
            return_value=httpx.Response(200, json={"id": "ak-1", "deleted": True})
        )

        result = sync_client.admin_keys.delete("ak-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True

    def test_regenerate(self, sync_client, mock_admin):
        mock_admin.post("/admin/api-keys/ak-1/regenerate").mock(
            return_value=httpx.Response(
                200,
                json={"id": "ak-1", "name": "Production Key", "key": "sk-admin-new-xxx"},
            )
        )

        result = sync_client.admin_keys.regenerate("ak-1")
        assert isinstance(result, AdminApiKey)
        assert result.key == "sk-admin-new-xxx"


class TestAdminKeysAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/admin/api-keys").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "ak-1", "name": "Key"}]}
            )
        )

        result = await async_client.admin_keys.list()
        assert isinstance(result, AdminApiKeyList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_admin):
        mock_admin.post("/admin/api-keys").mock(
            return_value=httpx.Response(
                200, json={"id": "ak-new", "name": "New Key", "key": "sk-admin-yyy"}
            )
        )

        result = await async_client.admin_keys.create(name="New Key")
        assert isinstance(result, AdminApiKey)
        assert result.id == "ak-new"

    @pytest.mark.asyncio
    async def test_regenerate(self, async_client, mock_admin):
        mock_admin.post("/admin/api-keys/ak-1/regenerate").mock(
            return_value=httpx.Response(
                200, json={"id": "ak-1", "name": "Key", "key": "sk-admin-regen"}
            )
        )

        result = await async_client.admin_keys.regenerate("ak-1")
        assert isinstance(result, AdminApiKey)
        assert result.key == "sk-admin-regen"
