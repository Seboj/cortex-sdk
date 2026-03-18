"""Tests for audit log resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import AuditLogList


class TestAuditLogSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/admin/audit-log").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {
                            "id": "log-1",
                            "action": "user.login",
                            "actor_id": "u-1",
                            "actor_email": "alice@test.com",
                            "created_at": "2024-01-01T00:00:00Z",
                        },
                        {
                            "id": "log-2",
                            "action": "key.created",
                            "actor_id": "u-1",
                            "resource_type": "api_key",
                            "resource_id": "key-1",
                            "created_at": "2024-01-01T01:00:00Z",
                        },
                    ]
                },
            )
        )

        result = sync_client.audit_log.list()
        assert isinstance(result, AuditLogList)
        assert len(result.data) == 2
        assert result.data[0].action == "user.login"

    def test_list_with_limit(self, sync_client, mock_admin):
        mock_admin.get("/admin/audit-log").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "log-1", "action": "user.login", "actor_id": "u-1"},
                    ]
                },
            )
        )

        result = sync_client.audit_log.list(limit=1)
        assert isinstance(result, AuditLogList)
        assert len(result.data) == 1


class TestAuditLogAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/admin/audit-log").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "log-1", "action": "user.login", "actor_id": "u-1"},
                    ]
                },
            )
        )

        result = await async_client.audit_log.list()
        assert isinstance(result, AuditLogList)
        assert len(result.data) == 1

    @pytest.mark.asyncio
    async def test_list_with_limit(self, async_client, mock_admin):
        mock_admin.get("/admin/audit-log").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "log-1", "action": "test"}]}
            )
        )

        result = await async_client.audit_log.list(limit=10)
        assert isinstance(result, AuditLogList)
