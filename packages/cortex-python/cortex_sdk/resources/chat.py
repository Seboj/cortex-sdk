"""Chat completions resource."""

from __future__ import annotations

from typing import Any, Dict, List, Literal, Optional, Union, overload

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.streaming import AsyncStream, Stream
from cortex_sdk.types import (
    ChatCompletion,
    ChatCompletionChunk,
    ChatCompletionRequest,
    ChatMessage,
    FunctionDefinition,
    ResponseFormat,
    ToolDefinition,
)


class _CompletionsBase:
    """Shared logic for sync/async chat completions."""

    @staticmethod
    def _build_payload(
        model: Optional[str],
        messages: List[Union[ChatMessage, Dict[str, Any]]],
        *,
        stream: bool = False,
        temperature: Optional[float] = None,
        top_p: Optional[float] = None,
        n: Optional[int] = None,
        stop: Optional[Union[str, List[str]]] = None,
        max_tokens: Optional[int] = None,
        presence_penalty: Optional[float] = None,
        frequency_penalty: Optional[float] = None,
        logit_bias: Optional[Dict[str, float]] = None,
        user: Optional[str] = None,
        functions: Optional[List[Union[FunctionDefinition, Dict[str, Any]]]] = None,
        function_call: Optional[Union[str, Dict[str, str]]] = None,
        tools: Optional[List[Union[ToolDefinition, Dict[str, Any]]]] = None,
        tool_choice: Optional[Union[str, Dict[str, Any]]] = None,
        response_format: Optional[Union[ResponseFormat, Dict[str, Any]]] = None,
        seed: Optional[int] = None,
    ) -> Dict[str, Any]:
        msg_dicts = []
        for m in messages:
            if isinstance(m, ChatMessage):
                msg_dicts.append(m.model_dump(exclude_none=True))
            else:
                msg_dicts.append(m)

        req = ChatCompletionRequest(
            model=model,
            messages=[ChatMessage.model_validate(d) for d in msg_dicts],
            stream=stream if stream else None,
            temperature=temperature,
            top_p=top_p,
            n=n,
            stop=stop,
            max_tokens=max_tokens,
            presence_penalty=presence_penalty,
            frequency_penalty=frequency_penalty,
            logit_bias=logit_bias,
            user=user,
            seed=seed,
        )
        payload = req.model_dump(exclude_none=True)

        # Handle complex nested types that may be dicts or models
        if functions is not None:
            payload["functions"] = [
                f.model_dump(exclude_none=True) if isinstance(f, FunctionDefinition) else f
                for f in functions
            ]
        if function_call is not None:
            payload["function_call"] = function_call
        if tools is not None:
            payload["tools"] = [
                t.model_dump(exclude_none=True) if isinstance(t, ToolDefinition) else t
                for t in tools
            ]
        if tool_choice is not None:
            payload["tool_choice"] = tool_choice
        if response_format is not None:
            if isinstance(response_format, ResponseFormat):
                payload["response_format"] = response_format.model_dump(exclude_none=True)
            else:
                payload["response_format"] = response_format

        return payload


class Completions(_CompletionsBase):
    """Synchronous chat completions."""

    def __init__(self, http: SyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    @overload
    def create(
        self,
        *,
        model: Optional[str] = None,
        messages: List[Union[ChatMessage, Dict[str, Any]]],
        stream: Literal[False] = ...,
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> ChatCompletion: ...

    @overload
    def create(
        self,
        *,
        model: Optional[str] = None,
        messages: List[Union[ChatMessage, Dict[str, Any]]],
        stream: Literal[True],
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> Stream[ChatCompletionChunk]: ...

    def create(
        self,
        *,
        model: Optional[str] = None,
        messages: List[Union[ChatMessage, Dict[str, Any]]],
        stream: bool = False,
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> Union[ChatCompletion, Stream[ChatCompletionChunk]]:
        payload = self._build_payload(model, messages, stream=stream, **kwargs)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        if stream:
            return self._http.stream_request(
                "POST",
                "/chat/completions",
                json=payload,
                model=ChatCompletionChunk,
                extra_headers=extra_headers,
            )

        data = self._http.request("POST", "/chat/completions", json=payload, extra_headers=extra_headers)
        return ChatCompletion.model_validate(data)


class AsyncCompletions(_CompletionsBase):
    """Asynchronous chat completions."""

    def __init__(self, http: AsyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    async def create(
        self,
        *,
        model: Optional[str] = None,
        messages: List[Union[ChatMessage, Dict[str, Any]]],
        stream: bool = False,
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> Union[ChatCompletion, AsyncStream[ChatCompletionChunk]]:
        payload = self._build_payload(model, messages, stream=stream, **kwargs)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        if stream:
            return await self._http.stream_request(
                "POST",
                "/chat/completions",
                json=payload,
                model=ChatCompletionChunk,
                extra_headers=extra_headers,
            )

        data = await self._http.request("POST", "/chat/completions", json=payload, extra_headers=extra_headers)
        return ChatCompletion.model_validate(data)


class Chat:
    """Sync chat resource — provides ``chat.completions``."""

    def __init__(self, http: SyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self.completions = Completions(http, default_pool=default_pool)


class AsyncChat:
    """Async chat resource — provides ``chat.completions``."""

    def __init__(self, http: AsyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self.completions = AsyncCompletions(http, default_pool=default_pool)
