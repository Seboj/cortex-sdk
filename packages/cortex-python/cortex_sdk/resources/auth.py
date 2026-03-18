"""Auth resource."""

from __future__ import annotations

from typing import Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import AuthProfile, AuthProfileUpdate, AuthTokenResponse


class Auth:
    """Synchronous auth resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def login(self, *, email: str, password: str) -> AuthTokenResponse:
        data = self._http.request(
            "POST", "/auth/login", json={"email": email, "password": password}
        )
        return AuthTokenResponse.model_validate(data)

    def signup(self, *, email: str, password: str, name: Optional[str] = None) -> AuthTokenResponse:
        body = {"email": email, "password": password}
        if name is not None:
            body["name"] = name
        data = self._http.request("POST", "/auth/signup", json=body)
        return AuthTokenResponse.model_validate(data)

    def me(self) -> AuthProfile:
        data = self._http.request("GET", "/auth/me")
        return AuthProfile.model_validate(data)

    def update_profile(
        self,
        *,
        name: Optional[str] = None,
        email: Optional[str] = None,
    ) -> AuthProfile:
        req = AuthProfileUpdate(name=name, email=email)
        data = self._http.request(
            "PATCH", "/auth/me", json=req.model_dump(exclude_none=True)
        )
        return AuthProfile.model_validate(data)

    def change_password(
        self, *, current_password: str, new_password: str
    ) -> AuthProfile:
        data = self._http.request(
            "POST",
            "/auth/change-password",
            json={
                "current_password": current_password,
                "new_password": new_password,
            },
        )
        return AuthProfile.model_validate(data)


class AsyncAuth:
    """Asynchronous auth resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def login(self, *, email: str, password: str) -> AuthTokenResponse:
        data = await self._http.request(
            "POST", "/auth/login", json={"email": email, "password": password}
        )
        return AuthTokenResponse.model_validate(data)

    async def signup(
        self, *, email: str, password: str, name: Optional[str] = None
    ) -> AuthTokenResponse:
        body = {"email": email, "password": password}
        if name is not None:
            body["name"] = name
        data = await self._http.request("POST", "/auth/signup", json=body)
        return AuthTokenResponse.model_validate(data)

    async def me(self) -> AuthProfile:
        data = await self._http.request("GET", "/auth/me")
        return AuthProfile.model_validate(data)

    async def update_profile(
        self,
        *,
        name: Optional[str] = None,
        email: Optional[str] = None,
    ) -> AuthProfile:
        req = AuthProfileUpdate(name=name, email=email)
        data = await self._http.request(
            "PATCH", "/auth/me", json=req.model_dump(exclude_none=True)
        )
        return AuthProfile.model_validate(data)

    async def change_password(
        self, *, current_password: str, new_password: str
    ) -> AuthProfile:
        data = await self._http.request(
            "POST",
            "/auth/change-password",
            json={
                "current_password": current_password,
                "new_password": new_password,
            },
        )
        return AuthProfile.model_validate(data)
