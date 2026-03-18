"""Conversations resource."""

from __future__ import annotations

from typing import Any, Dict, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.streaming import AsyncStream, Stream
from cortex_sdk.types import (
    Conversation,
    ConversationCreate,
    ConversationList,
    ConversationMessage,
    ConversationUpdate,
    DeleteResponse,
)


class Conversations:
    """Synchronous conversations resource."""

    def __init__(self, http: SyncHTTPClient) -> None:
        self._http = http

    def list(self, *, params: Optional[Dict[str, Any]] = None) -> ConversationList:
        data = self._http.request("GET", "/api/conversations", params=params)
        return ConversationList.model_validate(data)

    def create(
        self,
        *,
        title: Optional[str] = None,
        model: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Conversation:
        req = ConversationCreate(title=title, model=model, metadata=metadata)
        data = self._http.request(
            "POST", "/api/conversations", json=req.model_dump(exclude_none=True)
        )
        return Conversation.model_validate(data)

    def get(self, conversation_id: str) -> Conversation:
        data = self._http.request("GET", f"/api/conversations/{conversation_id}")
        return Conversation.model_validate(data)

    def update(
        self,
        conversation_id: str,
        *,
        title: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Conversation:
        req = ConversationUpdate(title=title, metadata=metadata)
        data = self._http.request(
            "PATCH",
            f"/api/conversations/{conversation_id}",
            json=req.model_dump(exclude_none=True),
        )
        return Conversation.model_validate(data)

    def delete(self, conversation_id: str) -> DeleteResponse:
        data = self._http.request("DELETE", f"/api/conversations/{conversation_id}")
        return DeleteResponse.model_validate(data)

    def messages(self, conversation_id: str) -> Stream[ConversationMessage]:
        return self._http.stream_request(
            "GET",
            f"/api/conversations/{conversation_id}/messages",
            model=ConversationMessage,
        )


class AsyncConversations:
    """Asynchronous conversations resource."""

    def __init__(self, http: AsyncHTTPClient) -> None:
        self._http = http

    async def list(self, *, params: Optional[Dict[str, Any]] = None) -> ConversationList:
        data = await self._http.request("GET", "/api/conversations", params=params)
        return ConversationList.model_validate(data)

    async def create(
        self,
        *,
        title: Optional[str] = None,
        model: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Conversation:
        req = ConversationCreate(title=title, model=model, metadata=metadata)
        data = await self._http.request(
            "POST", "/api/conversations", json=req.model_dump(exclude_none=True)
        )
        return Conversation.model_validate(data)

    async def get(self, conversation_id: str) -> Conversation:
        data = await self._http.request("GET", f"/api/conversations/{conversation_id}")
        return Conversation.model_validate(data)

    async def update(
        self,
        conversation_id: str,
        *,
        title: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Conversation:
        req = ConversationUpdate(title=title, metadata=metadata)
        data = await self._http.request(
            "PATCH",
            f"/api/conversations/{conversation_id}",
            json=req.model_dump(exclude_none=True),
        )
        return Conversation.model_validate(data)

    async def delete(self, conversation_id: str) -> DeleteResponse:
        data = await self._http.request("DELETE", f"/api/conversations/{conversation_id}")
        return DeleteResponse.model_validate(data)

    async def messages(self, conversation_id: str) -> AsyncStream[ConversationMessage]:
        return await self._http.stream_request(
            "GET",
            f"/api/conversations/{conversation_id}/messages",
            model=ConversationMessage,
        )
