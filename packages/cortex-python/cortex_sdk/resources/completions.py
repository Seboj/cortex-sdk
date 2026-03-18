"""Text completions resource."""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Union

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.streaming import AsyncStream, Stream
from cortex_sdk.types import (
    Completion,
    CompletionChunk,
    CompletionRequest,
)


def _build_payload(
    model: Optional[str],
    prompt: Union[str, List[str]],
    *,
    stream: bool = False,
    max_tokens: Optional[int] = None,
    temperature: Optional[float] = None,
    top_p: Optional[float] = None,
    n: Optional[int] = None,
    logprobs: Optional[int] = None,
    echo: Optional[bool] = None,
    stop: Optional[Union[str, List[str]]] = None,
    presence_penalty: Optional[float] = None,
    frequency_penalty: Optional[float] = None,
    best_of: Optional[int] = None,
    logit_bias: Optional[Dict[str, float]] = None,
    user: Optional[str] = None,
    suffix: Optional[str] = None,
    seed: Optional[int] = None,
) -> Dict[str, Any]:
    req = CompletionRequest(
        model=model,
        prompt=prompt,
        stream=stream if stream else None,
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        n=n,
        logprobs=logprobs,
        echo=echo,
        stop=stop,
        presence_penalty=presence_penalty,
        frequency_penalty=frequency_penalty,
        best_of=best_of,
        logit_bias=logit_bias,
        user=user,
        suffix=suffix,
        seed=seed,
    )
    return req.model_dump(exclude_none=True)


class Completions:
    """Synchronous text completions."""

    def __init__(self, http: SyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    def create(
        self,
        *,
        model: Optional[str] = None,
        prompt: Union[str, List[str]],
        stream: bool = False,
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> Union[Completion, Stream[CompletionChunk]]:
        payload = _build_payload(model, prompt, stream=stream, **kwargs)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        if stream:
            return self._http.stream_request(
                "POST", "/completions", json=payload, model=CompletionChunk,
                extra_headers=extra_headers,
            )

        data = self._http.request("POST", "/completions", json=payload, extra_headers=extra_headers)
        return Completion.model_validate(data)


class AsyncCompletions:
    """Asynchronous text completions."""

    def __init__(self, http: AsyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    async def create(
        self,
        *,
        model: Optional[str] = None,
        prompt: Union[str, List[str]],
        stream: bool = False,
        pool: Optional[str] = None,
        **kwargs: Any,
    ) -> Union[Completion, AsyncStream[CompletionChunk]]:
        payload = _build_payload(model, prompt, stream=stream, **kwargs)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        if stream:
            return await self._http.stream_request(
                "POST", "/completions", json=payload, model=CompletionChunk,
                extra_headers=extra_headers,
            )

        data = await self._http.request("POST", "/completions", json=payload, extra_headers=extra_headers)
        return Completion.model_validate(data)
