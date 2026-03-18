"""Tests for teams resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import DeleteResponse, Team, TeamList, TeamMember


class TestTeamsSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/api/teams").mock(
            return_value=httpx.Response(
                200,
                json={"data": [{"id": "team-1", "name": "Engineering", "member_count": 5}]},
            )
        )

        result = sync_client.teams.list()
        assert isinstance(result, TeamList)
        assert len(result.data) == 1
        assert result.data[0].name == "Engineering"

    def test_create(self, sync_client, mock_admin):
        mock_admin.post("/api/teams").mock(
            return_value=httpx.Response(
                200, json={"id": "team-new", "name": "Platform", "description": "Platform team"}
            )
        )

        result = sync_client.teams.create(name="Platform", description="Platform team")
        assert isinstance(result, Team)
        assert result.id == "team-new"

    def test_get(self, sync_client, mock_admin):
        mock_admin.get("/api/teams/team-1").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "team-1",
                    "name": "Engineering",
                    "members": [
                        {"id": "m-1", "email": "alice@test.com", "role": "admin"}
                    ],
                },
            )
        )

        result = sync_client.teams.get("team-1")
        assert isinstance(result, Team)
        assert result.members is not None
        assert result.members[0].email == "alice@test.com"

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/api/teams/team-1").mock(
            return_value=httpx.Response(200, json={"id": "team-1", "deleted": True})
        )

        result = sync_client.teams.delete("team-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True

    def test_add_member(self, sync_client, mock_admin):
        mock_admin.post("/api/teams/team-1/members").mock(
            return_value=httpx.Response(
                200, json={"id": "m-new", "email": "bob@test.com", "role": "member"}
            )
        )

        result = sync_client.teams.add_member("team-1", email="bob@test.com")
        assert isinstance(result, TeamMember)
        assert result.email == "bob@test.com"

    def test_update_member(self, sync_client, mock_admin):
        mock_admin.patch("/api/teams/team-1/members/m-1").mock(
            return_value=httpx.Response(
                200, json={"id": "m-1", "email": "alice@test.com", "role": "admin"}
            )
        )

        result = sync_client.teams.update_member("team-1", "m-1", role="admin")
        assert isinstance(result, TeamMember)
        assert result.role == "admin"

    def test_remove_member(self, sync_client, mock_admin):
        mock_admin.delete("/api/teams/team-1/members/m-1").mock(
            return_value=httpx.Response(200, json={"id": "m-1", "deleted": True})
        )

        result = sync_client.teams.remove_member("team-1", "m-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True


class TestTeamsAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/api/teams").mock(
            return_value=httpx.Response(
                200, json={"data": [{"id": "team-1", "name": "Eng"}]}
            )
        )

        result = await async_client.teams.list()
        assert isinstance(result, TeamList)

    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_admin):
        mock_admin.post("/api/teams").mock(
            return_value=httpx.Response(200, json={"id": "team-new", "name": "New Team"})
        )

        result = await async_client.teams.create(name="New Team")
        assert isinstance(result, Team)

    @pytest.mark.asyncio
    async def test_add_member(self, async_client, mock_admin):
        mock_admin.post("/api/teams/team-1/members").mock(
            return_value=httpx.Response(
                200, json={"id": "m-1", "email": "test@test.com", "role": "member"}
            )
        )

        result = await async_client.teams.add_member("team-1", email="test@test.com")
        assert isinstance(result, TeamMember)
