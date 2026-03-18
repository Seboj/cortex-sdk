"""Shared fixtures for the Cortex SDK test suite."""

from __future__ import annotations

import pytest
import respx

from cortex_sdk.client import AsyncCortexClient, CortexClient

TEST_API_KEY = "sk-cortex-test-key-12345"
TEST_LLM_BASE = "https://cortexapi.nfinitmonkeys.com/v1"
TEST_ADMIN_BASE = "https://admin.nfinitmonkeys.com"


@pytest.fixture()
def api_key() -> str:
    return TEST_API_KEY


@pytest.fixture()
def sync_client(api_key: str) -> CortexClient:
    return CortexClient(
        api_key=api_key,
        llm_base_url=TEST_LLM_BASE,
        admin_base_url=TEST_ADMIN_BASE,
        max_retries=0,
    )


@pytest.fixture()
def async_client(api_key: str) -> AsyncCortexClient:
    return AsyncCortexClient(
        api_key=api_key,
        llm_base_url=TEST_LLM_BASE,
        admin_base_url=TEST_ADMIN_BASE,
        max_retries=0,
    )


@pytest.fixture()
def mock_llm():
    """Mock LLM gateway HTTP calls."""
    with respx.mock(base_url=TEST_LLM_BASE, assert_all_called=False) as router:
        yield router


@pytest.fixture()
def mock_admin():
    """Mock admin API HTTP calls."""
    with respx.mock(base_url=TEST_ADMIN_BASE, assert_all_called=False) as router:
        yield router


# --- Common response factories ---


def chat_completion_response(
    content: str = "Hello!",
    model: str = "gpt-4",
    finish_reason: str = "stop",
) -> dict:
    return {
        "id": "chatcmpl-test123",
        "object": "chat.completion",
        "created": 1700000000,
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": content},
                "finish_reason": finish_reason,
            }
        ],
        "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
    }


def completion_response(text: str = "World", model: str = "gpt-4") -> dict:
    return {
        "id": "cmpl-test123",
        "object": "text_completion",
        "created": 1700000000,
        "model": model,
        "choices": [
            {
                "index": 0,
                "text": text,
                "finish_reason": "stop",
            }
        ],
        "usage": {"prompt_tokens": 5, "completion_tokens": 3, "total_tokens": 8},
    }


def embedding_response(dim: int = 3) -> dict:
    return {
        "object": "list",
        "data": [
            {"object": "embedding", "embedding": [0.1] * dim, "index": 0}
        ],
        "model": "text-embedding-ada-002",
        "usage": {"prompt_tokens": 5, "completion_tokens": 0, "total_tokens": 5},
    }


def models_response() -> dict:
    return {
        "object": "list",
        "data": [
            {"id": "gpt-4", "object": "model", "created": 1700000000, "owned_by": "openai"},
            {"id": "gpt-3.5-turbo", "object": "model", "created": 1700000000, "owned_by": "openai"},
        ],
    }


def sse_lines(chunks: list[dict]) -> str:
    """Build SSE text from a list of dicts."""
    lines = []
    for chunk in chunks:
        import json
        lines.append(f"data: {json.dumps(chunk)}\n\n")
    lines.append("data: [DONE]\n\n")
    return "".join(lines)
