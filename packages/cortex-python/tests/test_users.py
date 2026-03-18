"""Tests for users resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import CortexUser, CortexUserList, DeleteResponse, PendingCount


class TestUsersSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/admin/users").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "u-1", "email": "alice@test.com", "role": "admin", "status": "active"},
                        {"id": "u-2", "email": "bob@test.com", "role": "user", "status": "pending"},
                    ]
                },
            )
        )

        result = sync_client.users.list()
        assert isinstance(result, CortexUserList)
        assert len(result.data) == 2
        assert result.data[0].email == "alice@test.com"

    def test_pending_count(self, sync_client, mock_admin):
        mock_admin.get("/admin/users/pending-count").mock(
            return_value=httpx.Response(200, json={"count": 3})
        )

        result = sync_client.users.pending_count()
        assert isinstance(result, PendingCount)
        assert result.count == 3

    def test_update(self, sync_client, mock_admin):
        mock_admin.patch("/admin/users/u-1").mock(
            return_value=httpx.Response(
                200,
                json={"id": "u-1", "email": "alice@test.com", "role": "admin", "name": "Alice"},
            )
        )

        result = sync_client.users.update("u-1", name="Alice", role="admin")
        assert isinstance(result, CortexUser)
        assert result.name == "Alice"

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/admin/users/u-2").mock(
            return_value=httpx.Response(200, json={"id": "u-2", "deleted": True})
        )

        result = sync_client.users.delete("u-2")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True

    def test_approve(self, sync_client, mock_admin):
        mock_admin.post("/admin/users/u-2/approve").mock(
            return_value=httpx.Response(
                200, json={"id": "u-2", "email": "bob@test.com", "status": "active"}
            )
        )

        result = sync_client.users.approve("u-2")
        assert isinstance(result, CortexUser)
        assert result.status == "active"

    def test_reject(self, sync_client, mock_admin):
        mock_admin.post("/admin/users/u-2/reject").mock(
            return_value=httpx.Response(
                200, json={"id": "u-2", "email": "bob@test.com", "status": "rejected"}
            )
        )

        result = sync_client.users.reject("u-2")
        assert isinstance(result, CortexUser)
        assert result.status == "rejected"

    def test_reset_password(self, sync_client, mock_admin):
        mock_admin.post("/admin/users/u-1/reset-password").mock(
            return_value=httpx.Response(
                200, json={"id": "u-1", "email": "alice@test.com", "status": "active"}
            )
        )

        result = sync_client.users.reset_password("u-1")
        assert isinstance(result, CortexUser)


class TestUsersAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/admin/users").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "u-1", "email": "alice@test.com"}]}
            )
        )

        result = await async_client.users.list()
        assert isinstance(result, CortexUserList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_pending_count(self, async_client, mock_admin):
        mock_admin.get("/admin/users/pending-count").mock(
            return_value=httpx.Response(200, json={"count": 5})
        )

        result = await async_client.users.pending_count()
        assert isinstance(result, PendingCount)
        assert result.count == 5

    @pytest.mark.asyncio
    async def test_approve(self, async_client, mock_admin):
        mock_admin.post("/admin/users/u-2/approve").mock(
            return_value=httpx.Response(
                200, json={"id": "u-2", "email": "bob@test.com", "status": "active"}
            )
        )

        result = await async_client.users.approve("u-2")
        assert isinstance(result, CortexUser)
        assert result.status == "active"
