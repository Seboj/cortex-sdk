"""Tests for auth resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import AuthProfile, AuthTokenResponse


class TestAuthSync:
    def test_login(self, sync_client, mock_admin):
        mock_admin.post("/auth/login").mock(
            return_value=httpx.Response(
                200,
                json={
                    "token": "jwt-token-123",
                    "expires_at": "2024-12-31T23:59:59Z",
                    "user": {"id": "u-1", "email": "alice@test.com"},
                },
            )
        )

        result = sync_client.auth.login(email="alice@test.com", password="secret")
        assert isinstance(result, AuthTokenResponse)
        assert result.token == "jwt-token-123"

    def test_signup(self, sync_client, mock_admin):
        mock_admin.post("/auth/signup").mock(
            return_value=httpx.Response(
                200,
                json={
                    "token": "jwt-token-new",
                    "user": {"id": "u-new", "email": "bob@test.com"},
                },
            )
        )

        result = sync_client.auth.signup(
            email="bob@test.com", password="secret123", name="Bob"
        )
        assert isinstance(result, AuthTokenResponse)
        assert result.token == "jwt-token-new"

    def test_me(self, sync_client, mock_admin):
        mock_admin.get("/auth/me").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "u-1",
                    "email": "alice@test.com",
                    "name": "Alice",
                    "role": "admin",
                },
            )
        )

        result = sync_client.auth.me()
        assert isinstance(result, AuthProfile)
        assert result.email == "alice@test.com"
        assert result.name == "Alice"

    def test_update_profile(self, sync_client, mock_admin):
        mock_admin.patch("/auth/me").mock(
            return_value=httpx.Response(
                200,
                json={"id": "u-1", "email": "alice@test.com", "name": "Alice Updated"},
            )
        )

        result = sync_client.auth.update_profile(name="Alice Updated")
        assert isinstance(result, AuthProfile)
        assert result.name == "Alice Updated"

    def test_change_password(self, sync_client, mock_admin):
        mock_admin.post("/auth/change-password").mock(
            return_value=httpx.Response(
                200,
                json={"id": "u-1", "email": "alice@test.com", "name": "Alice"},
            )
        )

        result = sync_client.auth.change_password(
            current_password="old-pass", new_password="new-pass"
        )
        assert isinstance(result, AuthProfile)


class TestAuthAsync:
    @pytest.mark.asyncio
    async def test_login(self, async_client, mock_admin):
        mock_admin.post("/auth/login").mock(
            return_value=httpx.Response(
                200,
                json={"token": "jwt-async", "expires_at": "2024-12-31T23:59:59Z"},
            )
        )

        result = await async_client.auth.login(email="test@test.com", password="pass")
        assert isinstance(result, AuthTokenResponse)
        assert result.token == "jwt-async"

    @pytest.mark.asyncio
    async def test_signup(self, async_client, mock_admin):
        mock_admin.post("/auth/signup").mock(
            return_value=httpx.Response(200, json={"token": "jwt-signup"})
        )

        result = await async_client.auth.signup(email="new@test.com", password="pass")
        assert isinstance(result, AuthTokenResponse)

    @pytest.mark.asyncio
    async def test_me(self, async_client, mock_admin):
        mock_admin.get("/auth/me").mock(
            return_value=httpx.Response(
                200, json={"id": "u-1", "email": "alice@test.com", "name": "Alice"}
            )
        )

        result = await async_client.auth.me()
        assert isinstance(result, AuthProfile)
        assert result.email == "alice@test.com"

    @pytest.mark.asyncio
    async def test_change_password(self, async_client, mock_admin):
        mock_admin.post("/auth/change-password").mock(
            return_value=httpx.Response(
                200, json={"id": "u-1", "email": "alice@test.com"}
            )
        )

        result = await async_client.auth.change_password(
            current_password="old", new_password="new"
        )
        assert isinstance(result, AuthProfile)
