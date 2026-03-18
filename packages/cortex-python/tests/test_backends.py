"""Tests for backends resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import (
    Backend,
    BackendList,
    BackendModel,
    DeleteResponse,
    DiscoverModelsResponse,
)


class TestBackendsSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/admin/backends").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "be-1", "name": "OpenAI", "provider": "openai", "enabled": True},
                        {"id": "be-2", "name": "Anthropic", "provider": "anthropic", "enabled": True},
                    ]
                },
            )
        )

        result = sync_client.backends.list()
        assert isinstance(result, BackendList)
        assert len(result.data) == 2
        assert result.data[0].provider == "openai"

    def test_create(self, sync_client, mock_admin):
        mock_admin.post("/admin/backends").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "be-new",
                    "name": "New Backend",
                    "base_url": "https://api.example.com",
                    "provider": "custom",
                },
            )
        )

        result = sync_client.backends.create(
            name="New Backend", base_url="https://api.example.com", provider="custom"
        )
        assert isinstance(result, Backend)
        assert result.id == "be-new"

    def test_update(self, sync_client, mock_admin):
        mock_admin.patch("/admin/backends/be-1").mock(
            return_value=httpx.Response(
                200,
                json={"id": "be-1", "name": "Updated", "enabled": False},
            )
        )

        result = sync_client.backends.update("be-1", enabled=False)
        assert isinstance(result, Backend)
        assert result.enabled is False

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/admin/backends/be-1").mock(
            return_value=httpx.Response(200, json={"id": "be-1", "deleted": True})
        )

        result = sync_client.backends.delete("be-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True

    def test_discover(self, sync_client, mock_admin):
        mock_admin.post("/admin/backends/be-1/discover").mock(
            return_value=httpx.Response(
                200,
                json={
                    "models": [
                        {"id": "gpt-4", "name": "gpt-4"},
                        {"id": "gpt-3.5-turbo", "name": "gpt-3.5-turbo"},
                    ]
                },
            )
        )

        result = sync_client.backends.discover("be-1")
        assert isinstance(result, DiscoverModelsResponse)
        assert len(result.models) == 2

    def test_update_model(self, sync_client, mock_admin):
        mock_admin.patch("/admin/backends/be-1/models/gpt-4").mock(
            return_value=httpx.Response(
                200,
                json={"id": "gpt-4", "name": "gpt-4", "display_name": "GPT-4 Turbo"},
            )
        )

        result = sync_client.backends.update_model("be-1", "gpt-4", display_name="GPT-4 Turbo")
        assert isinstance(result, BackendModel)
        assert result.display_name == "GPT-4 Turbo"


class TestBackendsAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/admin/backends").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "be-1", "name": "OpenAI"}]}
            )
        )

        result = await async_client.backends.list()
        assert isinstance(result, BackendList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_admin):
        mock_admin.post("/admin/backends").mock(
            return_value=httpx.Response(
                200, json={"id": "be-new", "name": "New", "base_url": "https://example.com"}
            )
        )

        result = await async_client.backends.create(name="New", base_url="https://example.com")
        assert isinstance(result, Backend)

    @pytest.mark.asyncio
    async def test_discover(self, async_client, mock_admin):
        mock_admin.post("/admin/backends/be-1/discover").mock(
            return_value=httpx.Response(
                200, json={"models": [{"id": "m-1", "name": "model-1"}]}
            )
        )

        result = await async_client.backends.discover("be-1")
        assert isinstance(result, DiscoverModelsResponse)
        assert len(result.models) == 1
