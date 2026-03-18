"""Tests for SSE streaming."""

from __future__ import annotations

import json

import httpx
import pytest

from cortex_sdk.streaming import AsyncStream, Stream
from cortex_sdk.types import ChatCompletionChunk, CompletionChunk
from cortex_sdk.errors import StreamError


def _make_chat_chunk(content: str, index: int = 0, finish_reason: str | None = None) -> dict:
    return {
        "id": "chatcmpl-stream-test",
        "object": "chat.completion.chunk",
        "created": 1700000000,
        "model": "gpt-4",
        "choices": [
            {
                "index": index,
                "delta": {"content": content},
                "finish_reason": finish_reason,
            }
        ],
    }


def _build_sse(chunks: list[dict]) -> str:
    lines = []
    for chunk in chunks:
        lines.append(f"data: {json.dumps(chunk)}\n\n")
    lines.append("data: [DONE]\n\n")
    return "".join(lines)


class TestStreamParsing:
    def test_parse_line_data(self):
        chunk = _make_chat_chunk("Hello")
        stream = Stream.__new__(Stream)
        stream._model = ChatCompletionChunk
        result = stream._parse_line(f"data: {json.dumps(chunk)}")
        assert isinstance(result, ChatCompletionChunk)
        assert result.choices[0].delta.content == "Hello"

    def test_parse_line_done(self):
        stream = Stream.__new__(Stream)
        stream._model = ChatCompletionChunk
        result = stream._parse_line("data: [DONE]")
        assert result is None

    def test_parse_line_empty(self):
        stream = Stream.__new__(Stream)
        stream._model = ChatCompletionChunk
        result = stream._parse_line("")
        assert result is None

    def test_parse_line_comment(self):
        stream = Stream.__new__(Stream)
        stream._model = ChatCompletionChunk
        result = stream._parse_line(": this is a comment")
        assert result is None

    def test_parse_line_invalid_json(self):
        stream = Stream.__new__(Stream)
        stream._model = ChatCompletionChunk
        with pytest.raises(StreamError, match="Failed to parse"):
            stream._parse_line("data: {invalid json}")

    def test_sync_stream_iteration(self):
        """Test iterating a sync stream with a mock response."""
        chunks = [
            _make_chat_chunk("Hello"),
            _make_chat_chunk(" world"),
            _make_chat_chunk("!", finish_reason="stop"),
        ]
        sse_text = _build_sse(chunks)

        response = httpx.Response(
            200,
            content=sse_text.encode(),
            headers={"content-type": "text/event-stream"},
        )
        # Read the response so iter_lines works
        response.read()

        stream = Stream(response, ChatCompletionChunk)
        collected = list(stream)

        assert len(collected) == 3
        assert collected[0].choices[0].delta.content == "Hello"
        assert collected[1].choices[0].delta.content == " world"
        assert collected[2].choices[0].delta.content == "!"
        assert collected[2].choices[0].finish_reason == "stop"


class TestAsyncStreamParsing:
    def test_parse_line(self):
        chunk = _make_chat_chunk("Hi")
        stream = AsyncStream.__new__(AsyncStream)
        stream._model = ChatCompletionChunk
        result = stream._parse_line(f"data: {json.dumps(chunk)}")
        assert isinstance(result, ChatCompletionChunk)
        assert result.choices[0].delta.content == "Hi"

    def test_parse_line_done(self):
        stream = AsyncStream.__new__(AsyncStream)
        stream._model = ChatCompletionChunk
        assert stream._parse_line("data: [DONE]") is None
