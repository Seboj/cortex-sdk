"""Tests for usage limits resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import DeleteResponse, UsageLimit, UsageLimitList


class TestUsageLimitsSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/admin/usage-limits").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "ul-1", "user_id": "u-1", "requests_per_day": 1000},
                        {"id": "ul-2", "team_id": "t-1", "tokens_per_day": 500000},
                    ]
                },
            )
        )

        result = sync_client.usage_limits.list()
        assert isinstance(result, UsageLimitList)
        assert len(result.data) == 2

    def test_set_user_limits(self, sync_client, mock_admin):
        mock_admin.put("/admin/usage-limits/user/u-1").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "ul-1",
                    "user_id": "u-1",
                    "requests_per_day": 500,
                    "tokens_per_day": 100000,
                },
            )
        )

        result = sync_client.usage_limits.set_user_limits(
            "u-1", requests_per_day=500, tokens_per_day=100000
        )
        assert isinstance(result, UsageLimit)
        assert result.requests_per_day == 500

    def test_remove_user_limits(self, sync_client, mock_admin):
        mock_admin.delete("/admin/usage-limits/user/u-1").mock(
            return_value=httpx.Response(200, json={"id": "ul-1", "deleted": True})
        )

        result = sync_client.usage_limits.remove_user_limits("u-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True

    def test_remove_team_limits(self, sync_client, mock_admin):
        mock_admin.delete("/admin/usage-limits/team/t-1").mock(
            return_value=httpx.Response(200, json={"id": "ul-2", "deleted": True})
        )

        result = sync_client.usage_limits.remove_team_limits("t-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True


class TestUsageLimitsAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/admin/usage-limits").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "ul-1", "user_id": "u-1"}]}
            )
        )

        result = await async_client.usage_limits.list()
        assert isinstance(result, UsageLimitList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_set_user_limits(self, async_client, mock_admin):
        mock_admin.put("/admin/usage-limits/user/u-1").mock(
            return_value=httpx.Response(
                200, json={"id": "ul-1", "user_id": "u-1", "requests_per_day": 200}
            )
        )

        result = await async_client.usage_limits.set_user_limits("u-1", requests_per_day=200)
        assert isinstance(result, UsageLimit)

    @pytest.mark.asyncio
    async def test_remove_user_limits(self, async_client, mock_admin):
        mock_admin.delete("/admin/usage-limits/user/u-1").mock(
            return_value=httpx.Response(200, json={"id": "ul-1", "deleted": True})
        )

        result = await async_client.usage_limits.remove_user_limits("u-1")
        assert result.deleted is True
