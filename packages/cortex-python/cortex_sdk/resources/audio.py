"""Audio resource."""

from __future__ import annotations

from typing import Any, BinaryIO, Dict, Optional, Union

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.types import AudioTranscription


class Audio:
    """Synchronous audio resource."""

    def __init__(self, http: SyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    def transcribe(
        self,
        *,
        file: Union[BinaryIO, bytes],
        model: Optional[str] = None,
        language: Optional[str] = None,
        prompt: Optional[str] = None,
        response_format: Optional[str] = None,
        temperature: Optional[float] = None,
        pool: Optional[str] = None,
    ) -> AudioTranscription:
        files: dict[str, Any] = {"file": file}
        form_data: dict[str, Any] = {}
        if model is not None:
            form_data["model"] = model
        if language is not None:
            form_data["language"] = language
        if prompt is not None:
            form_data["prompt"] = prompt
        if response_format is not None:
            form_data["response_format"] = response_format
        if temperature is not None:
            form_data["temperature"] = str(temperature)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        data = self._http.request(
            "POST",
            "/v1/audio/transcriptions",
            files=files,
            content=form_data,
            extra_headers=extra_headers,
        )
        return AudioTranscription.model_validate(data)


class AsyncAudio:
    """Asynchronous audio resource."""

    def __init__(self, http: AsyncHTTPClient, *, default_pool: Optional[str] = None) -> None:
        self._http = http
        self._default_pool = default_pool

    async def transcribe(
        self,
        *,
        file: Union[BinaryIO, bytes],
        model: Optional[str] = None,
        language: Optional[str] = None,
        prompt: Optional[str] = None,
        response_format: Optional[str] = None,
        temperature: Optional[float] = None,
        pool: Optional[str] = None,
    ) -> AudioTranscription:
        files: dict[str, Any] = {"file": file}
        form_data: dict[str, Any] = {}
        if model is not None:
            form_data["model"] = model
        if language is not None:
            form_data["language"] = language
        if prompt is not None:
            form_data["prompt"] = prompt
        if response_format is not None:
            form_data["response_format"] = response_format
        if temperature is not None:
            form_data["temperature"] = str(temperature)

        # Resolve pool: per-request > client default > none
        resolved_pool = pool or self._default_pool
        extra_headers: Optional[Dict[str, str]] = None
        if resolved_pool:
            extra_headers = {"x-cortex-pool": resolved_pool}

        data = await self._http.request(
            "POST",
            "/v1/audio/transcriptions",
            files=files,
            content=form_data,
            extra_headers=extra_headers,
        )
        return AudioTranscription.model_validate(data)
