"""Teams resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import (
    DeleteResponse,
    Team,
    TeamCreate,
    TeamList,
    TeamMember,
    TeamMemberAdd,
    TeamMemberUpdate,
)


class Teams:
    """Synchronous teams resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self) -> TeamList:
        data = self._http.request("GET", "/api/teams")
        return TeamList.model_validate(data)

    def create(self, *, name: str, description: Optional[str] = None) -> Team:
        req = TeamCreate(name=name, description=description)
        data = self._http.request("POST", "/api/teams", json=req.model_dump(exclude_none=True))
        return Team.model_validate(data)

    def get(self, team_id: str) -> Team:
        data = self._http.request("GET", f"/api/teams/{team_id}")
        return Team.model_validate(data)

    def delete(self, team_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/api/teams/{team_id}")
        return DeleteResponse.model_validate(data)

    def add_member(
        self,
        team_id: str,
        *,
        email: str,
        role: Optional[str] = "member",
    ) -> TeamMember:
        req = TeamMemberAdd(email=email, role=role)
        data = self._http.request(
            "POST",
            f"/api/teams/{team_id}/members",
            json=req.model_dump(exclude_none=True),
        )
        return TeamMember.model_validate(data)

    def update_member(self, team_id: str, member_id: str, *, role: str) -> TeamMember:
        req = TeamMemberUpdate(role=role)
        data = self._http.request(
            "PATCH",
            f"/api/teams/{team_id}/members/{member_id}",
            json=req.model_dump(),
        )
        return TeamMember.model_validate(data)

    def remove_member(self, team_id: str, member_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/api/teams/{team_id}/members/{member_id}")
        return DeleteResponse.model_validate(data)


class AsyncTeams:
    """Asynchronous teams resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self) -> TeamList:
        data = await self._http.request("GET", "/api/teams")
        return TeamList.model_validate(data)

    async def create(self, *, name: str, description: Optional[str] = None) -> Team:
        req = TeamCreate(name=name, description=description)
        data = await self._http.request(
            "POST", "/api/teams", json=req.model_dump(exclude_none=True)
        )
        return Team.model_validate(data)

    async def get(self, team_id: str) -> Team:
        data = await self._http.request("GET", f"/api/teams/{team_id}")
        return Team.model_validate(data)

    async def delete(self, team_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/api/teams/{team_id}")
        return DeleteResponse.model_validate(data)

    async def add_member(
        self,
        team_id: str,
        *,
        email: str,
        role: Optional[str] = "member",
    ) -> TeamMember:
        req = TeamMemberAdd(email=email, role=role)
        data = await self._http.request(
            "POST",
            f"/api/teams/{team_id}/members",
            json=req.model_dump(exclude_none=True),
        )
        return TeamMember.model_validate(data)

    async def update_member(self, team_id: str, member_id: str, *, role: str) -> TeamMember:
        req = TeamMemberUpdate(role=role)
        data = await self._http.request(
            "PATCH",
            f"/api/teams/{team_id}/members/{member_id}",
            json=req.model_dump(),
        )
        return TeamMember.model_validate(data)

    async def remove_member(self, team_id: str, member_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/api/teams/{team_id}/members/{member_id}")
        return DeleteResponse.model_validate(data)
