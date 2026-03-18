"""Tests for conversations resource."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import Conversation, ConversationList, DeleteResponse


class TestConversationsSync:
    def test_list(self, sync_client, mock_admin):
        mock_admin.get("/api/conversations").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"id": "conv-1", "title": "First convo", "message_count": 10},
                        {"id": "conv-2", "title": "Second convo", "message_count": 5},
                    ]
                },
            )
        )

        result = sync_client.conversations.list()
        assert isinstance(result, ConversationList)
        assert len(result.data) == 2

    def test_create(self, sync_client, mock_admin):
        mock_admin.post("/api/conversations").mock(
            return_value=httpx.Response(
                200,
                json={"id": "conv-new", "title": "My Chat", "model": "gpt-4"},
            )
        )

        result = sync_client.conversations.create(title="My Chat", model="gpt-4")
        assert isinstance(result, Conversation)
        assert result.id == "conv-new"
        assert result.title == "My Chat"

    def test_get(self, sync_client, mock_admin):
        mock_admin.get("/api/conversations/conv-1").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "conv-1",
                    "title": "Chat",
                    "messages": [
                        {"id": "msg-1", "role": "user", "content": "Hello"},
                        {"id": "msg-2", "role": "assistant", "content": "Hi!"},
                    ],
                },
            )
        )

        result = sync_client.conversations.get("conv-1")
        assert isinstance(result, Conversation)
        assert result.messages is not None
        assert len(result.messages) == 2

    def test_update(self, sync_client, mock_admin):
        mock_admin.patch("/api/conversations/conv-1").mock(
            return_value=httpx.Response(
                200, json={"id": "conv-1", "title": "Updated Title"}
            )
        )

        result = sync_client.conversations.update("conv-1", title="Updated Title")
        assert isinstance(result, Conversation)
        assert result.title == "Updated Title"

    def test_delete(self, sync_client, mock_admin):
        mock_admin.delete("/api/conversations/conv-1").mock(
            return_value=httpx.Response(200, json={"id": "conv-1", "deleted": True})
        )

        result = sync_client.conversations.delete("conv-1")
        assert isinstance(result, DeleteResponse)
        assert result.deleted is True


class TestConversationsAsync:
    @pytest.mark.asyncio
    async def test_list(self, async_client, mock_admin):
        mock_admin.get("/api/conversations").mock(
            return_value=httpx.Response(200, json={"data": [{"id": "conv-1", "title": "Chat"}]})
        )

        result = await async_client.conversations.list()
        assert isinstance(result, ConversationList)

    @pytest.mark.asyncio
    async def test_create(self, async_client, mock_admin):
        mock_admin.post("/api/conversations").mock(
            return_value=httpx.Response(200, json={"id": "conv-new", "title": "Test"})
        )

        result = await async_client.conversations.create(title="Test")
        assert isinstance(result, Conversation)

    @pytest.mark.asyncio
    async def test_update(self, async_client, mock_admin):
        mock_admin.patch("/api/conversations/conv-1").mock(
            return_value=httpx.Response(200, json={"id": "conv-1", "title": "New"})
        )

        result = await async_client.conversations.update("conv-1", title="New")
        assert result.title == "New"

    @pytest.mark.asyncio
    async def test_delete(self, async_client, mock_admin):
        mock_admin.delete("/api/conversations/conv-1").mock(
            return_value=httpx.Response(200, json={"id": "conv-1", "deleted": True})
        )

        result = await async_client.conversations.delete("conv-1")
        assert result.deleted is True
