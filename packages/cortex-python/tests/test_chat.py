"""Tests for chat completions resource."""

from __future__ import annotations

import httpx
import pytest
import respx

from cortex_sdk.types import ChatCompletion, ChatMessage
from tests.conftest import (
    TEST_LLM_BASE,
    chat_completion_response,
)


class TestChatCompletionsSync:
    def test_create(self, sync_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        result = sync_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
        )

        assert isinstance(result, ChatCompletion)
        assert result.id == "chatcmpl-test123"
        assert result.choices[0].message.content == "Hello!"
        assert result.usage is not None
        assert result.usage.total_tokens == 15

    def test_create_with_pydantic_messages(self, sync_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        result = sync_client.chat.completions.create(
            model="gpt-4",
            messages=[ChatMessage(role="user", content="Hello")],
        )

        assert isinstance(result, ChatCompletion)
        assert result.choices[0].message.content == "Hello!"

    def test_create_with_all_params(self, sync_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        result = sync_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
            temperature=0.7,
            top_p=0.9,
            n=1,
            max_tokens=100,
            presence_penalty=0.5,
            frequency_penalty=0.5,
            user="test-user",
            seed=42,
        )

        assert isinstance(result, ChatCompletion)

    def test_create_sends_correct_payload(self, sync_client, mock_llm):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        sync_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
            temperature=0.5,
        )

        request = route.calls.last.request
        import json

        body = json.loads(request.content)
        assert body["model"] == "gpt-4"
        assert body["messages"] == [{"role": "user", "content": "Hello"}]
        assert body["temperature"] == 0.5

    def test_auth_header_sent(self, sync_client, mock_llm, api_key):
        route = mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        sync_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
        )

        request = route.calls.last.request
        assert request.headers["authorization"] == f"Bearer {api_key}"


class TestChatCompletionsAsync:
    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        result = await async_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}],
        )

        assert isinstance(result, ChatCompletion)
        assert result.choices[0].message.content == "Hello!"

    @pytest.mark.asyncio
    async def test_create_with_tools(self, async_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(200, json=chat_completion_response())
        )

        result = await async_client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "What's the weather?"}],
            tools=[{
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Get weather",
                    "parameters": {"type": "object", "properties": {}},
                },
            }],
            tool_choice="auto",
        )

        assert isinstance(result, ChatCompletion)
