"""Tests for audio resource."""

from __future__ import annotations

import io

import httpx
import pytest

from cortex_sdk.types import AudioTranscription


class TestAudioSync:
    def test_transcribe(self, sync_client, mock_llm):
        mock_llm.post("/v1/audio/transcriptions").mock(
            return_value=httpx.Response(
                200,
                json={
                    "text": "Hello, world!",
                    "language": "en",
                    "duration": 2.5,
                },
            )
        )

        audio_file = io.BytesIO(b"fake-audio-data")
        result = sync_client.audio.transcribe(file=audio_file, model="whisper-1")
        assert isinstance(result, AudioTranscription)
        assert result.text == "Hello, world!"
        assert result.language == "en"
        assert result.duration == 2.5

    def test_transcribe_with_options(self, sync_client, mock_llm):
        mock_llm.post("/v1/audio/transcriptions").mock(
            return_value=httpx.Response(
                200,
                json={"text": "Bonjour le monde!", "language": "fr", "duration": 3.0},
            )
        )

        audio_file = io.BytesIO(b"fake-audio-data")
        result = sync_client.audio.transcribe(
            file=audio_file, model="whisper-1", language="fr", prompt="French audio"
        )
        assert isinstance(result, AudioTranscription)
        assert result.text == "Bonjour le monde!"
        assert result.language == "fr"


class TestAudioAsync:
    @pytest.mark.asyncio
    async def test_transcribe(self, async_client, mock_llm):
        mock_llm.post("/v1/audio/transcriptions").mock(
            return_value=httpx.Response(
                200,
                json={"text": "Hello async!", "language": "en", "duration": 1.5},
            )
        )

        audio_file = io.BytesIO(b"fake-audio-data")
        result = await async_client.audio.transcribe(file=audio_file, model="whisper-1")
        assert isinstance(result, AudioTranscription)
        assert result.text == "Hello async!"

    @pytest.mark.asyncio
    async def test_transcribe_with_language(self, async_client, mock_llm):
        mock_llm.post("/v1/audio/transcriptions").mock(
            return_value=httpx.Response(
                200,
                json={"text": "Hola mundo!", "language": "es"},
            )
        )

        audio_file = io.BytesIO(b"fake-audio")
        result = await async_client.audio.transcribe(
            file=audio_file, model="whisper-1", language="es"
        )
        assert isinstance(result, AudioTranscription)
        assert result.language == "es"
