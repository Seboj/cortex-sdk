"""Tests for x-cortex-pool header support."""

from __future__ import annotations

import json

import httpx
import pytest
import respx

from cortex_sdk.client import AsyncCortexClient, CortexClient
from cortex_sdk.types import ChatCompletion, Completion, EmbeddingResponse
from tests.conftest import (
    TEST_API_KEY,
    TEST_ADMIN_BASE,
    TEST_LLM_BASE,
    chat_completion_response,
    completion_response,
    embedding_response,
)


# ── Fixtures ────────────────────────────────────────────────────────────────


@pytest.fixture()
def sync_client_with_pool() -> CortexClient:
    return CortexClient(
        api_key=TEST_API_KEY,
        llm_base_url=TEST_LLM_BASE,
        admin_base_url=TEST_ADMIN_BASE,
        max_retries=0,
        default_pool="cortex-stt",
    )


@pytest.fixture()
def async_client_with_pool() -> AsyncCortexClient:
    return AsyncCortexClient(
        api_key=TEST_API_KEY,
        llm_base_url=TEST_LLM_BASE,
        admin_base_url=TEST_ADMIN_BASE,
        max_retries=0,
        default_pool="cortexvlm",
    )


# ── Sync tests ──────────────────────────────────────────────────────────────


class TestPoolHeaderSync:
    def test_chat_per_request_pool(self, sync_client, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        sync_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
            pool="cortexvlm",
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "cortexvlm"

    def test_chat_default_pool(self, sync_client_with_pool, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        sync_client_with_pool.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "cortex-stt"

    def test_chat_per_request_overrides_default(self, sync_client_with_pool, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        sync_client_with_pool.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
            pool="cortexvlm",
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "cortexvlm"

    def test_chat_no_pool_no_header(self, sync_client, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        sync_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
        )

        request = route.calls.last.request
        assert "x-cortex-pool" not in request.headers

    def test_completions_pool(self, sync_client, mock_llm):
        route = mock_llm.post("/completions").mock(
            return_value=httpx.Response(200, json=completion_response())
        )

        sync_client.completions.create(
            model="gpt-4",
            prompt="Hello",
            pool="cortex-stt",
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "cortex-stt"

    def test_embeddings_pool(self, sync_client, mock_llm):
        route = mock_llm.post("/embeddings").mock(
            return_value=httpx.Response(200, json=embedding_response())
        )

        sync_client.embeddings.create(
            model="text-embedding-ada-002",
            input="Hello",
            pool="default",
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "default"


class TestModelOptionalSync:
    def test_chat_without_model(self, sync_client_with_pool, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        result = sync_client_with_pool.chat.completions.create(
            messages=[{"role": "user", "content": "Hello"}],
        )

        assert isinstance(result, ChatCompletion)
        request = route.calls.last.request
        body = json.loads(request.content)
        assert "model" not in body
        assert request.headers.get("x-cortex-pool") == "cortex-stt"

    def test_completions_without_model(self, sync_client, mock_llm):
        route = mock_llm.post("/completions").mock(
            return_value=httpx.Response(200, json=completion_response())
        )

        result = sync_client.completions.create(
            prompt="Hello",
            pool="default",
        )

        assert isinstance(result, Completion)
        request = route.calls.last.request
        body = json.loads(request.content)
        assert "model" not in body

    def test_embeddings_without_model(self, sync_client, mock_llm):
        route = mock_llm.post("/embeddings").mock(
            return_value=httpx.Response(200, json=embedding_response())
        )

        result = sync_client.embeddings.create(
            input="Hello",
            pool="default",
        )

        assert isinstance(result, EmbeddingResponse)
        request = route.calls.last.request
        body = json.loads(request.content)
        assert "model" not in body


# ── Async tests ─────────────────────────────────────────────────────────────


class TestPoolHeaderAsync:
    @pytest.mark.asyncio
    async def test_chat_per_request_pool(self, async_client, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        await async_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
            pool="cortex-stt-diarize",
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "cortex-stt-diarize"

    @pytest.mark.asyncio
    async def test_chat_default_pool(self, async_client_with_pool, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        await async_client_with_pool.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
        )

        request = route.calls.last.request
        assert request.headers.get("x-cortex-pool") == "cortexvlm"
