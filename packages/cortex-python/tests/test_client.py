"""Tests for the CortexClient and AsyncCortexClient."""

from __future__ import annotations

import pytest

from cortex_sdk.client import AsyncCortexClient, CortexClient


class TestCortexClientInit:
    def test_requires_api_key(self):
        with pytest.raises(ValueError, match="api_key must be provided"):
            CortexClient(api_key="")

    def test_repr_hides_key(self):
        client = CortexClient(api_key="sk-cortex-secret-key")
        assert "secret" not in repr(client)
        assert "sk-***" in repr(client)

    def test_rejects_http_base_url(self):
        with pytest.raises(ValueError, match="HTTPS"):
            CortexClient(api_key="sk-test", llm_base_url="http://evil.com/v1")

    def test_allows_localhost_http(self):
        client = CortexClient(
            api_key="sk-test",
            llm_base_url="http://localhost:8000/v1",
            admin_base_url="http://localhost:3000",
        )
        assert client is not None
        client.close()

    def test_context_manager(self):
        with CortexClient(api_key="sk-test") as client:
            assert client is not None

    def test_has_all_resources(self):
        client = CortexClient(api_key="sk-test")
        assert hasattr(client, "chat")
        assert hasattr(client, "completions")
        assert hasattr(client, "embeddings")
        assert hasattr(client, "models")
        assert hasattr(client, "keys")
        assert hasattr(client, "teams")
        assert hasattr(client, "usage")
        assert hasattr(client, "performance")
        assert hasattr(client, "conversations")
        assert hasattr(client, "iris")
        assert hasattr(client, "plugins")
        assert hasattr(client, "optimizations")
        assert hasattr(client, "admin_models")
        assert hasattr(client, "pdf")
        assert hasattr(client, "web_search")
        client.close()


class TestAsyncCortexClientInit:
    def test_requires_api_key(self):
        with pytest.raises(ValueError, match="api_key must be provided"):
            AsyncCortexClient(api_key="")

    def test_repr_hides_key(self):
        client = AsyncCortexClient(api_key="sk-cortex-secret-key")
        assert "secret" not in repr(client)
        assert "sk-***" in repr(client)

    def test_has_all_resources(self):
        client = AsyncCortexClient(api_key="sk-test")
        assert hasattr(client, "chat")
        assert hasattr(client, "completions")
        assert hasattr(client, "embeddings")
        assert hasattr(client, "models")
        assert hasattr(client, "keys")
        assert hasattr(client, "teams")
        assert hasattr(client, "usage")
        assert hasattr(client, "performance")
        assert hasattr(client, "conversations")
        assert hasattr(client, "iris")
        assert hasattr(client, "plugins")
        assert hasattr(client, "optimizations")
        assert hasattr(client, "admin_models")
        assert hasattr(client, "pdf")
        assert hasattr(client, "web_search")


class TestHeaderInjection:
    def test_rejects_crlf_in_api_key(self):
        with pytest.raises(ValueError, match="unsafe characters"):
            CortexClient(api_key="sk-test\r\nEvil: header")

    def test_rejects_newline_in_extra_headers(self):
        with pytest.raises(ValueError, match="unsafe characters"):
            CortexClient(api_key="sk-test", extra_headers={"X-Bad": "val\nEvil: yes"})
