"""Tests for error handling and retry logic."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.errors import (
    APIError,
    AuthenticationError,
    InternalServerError,
    NotFoundError,
    PermissionDeniedError,
    RateLimitError,
    _raise_for_status,
)
from cortex_sdk.client import CortexClient
from cortex_sdk.types import ChatCompletion
from tests.conftest import TEST_LLM_BASE, chat_completion_response


class TestRaiseForStatus:
    def test_401(self):
        with pytest.raises(AuthenticationError) as exc_info:
            _raise_for_status(401, {"error": {"message": "Invalid key"}}, {})
        assert exc_info.value.status_code == 401
        assert "Invalid key" in exc_info.value.message

    def test_403(self):
        with pytest.raises(PermissionDeniedError) as exc_info:
            _raise_for_status(403, {"error": "Forbidden"}, {})
        assert exc_info.value.status_code == 403

    def test_404(self):
        with pytest.raises(NotFoundError) as exc_info:
            _raise_for_status(404, {"error": {"message": "Not found"}}, {})
        assert exc_info.value.status_code == 404

    def test_429_with_retry_after(self):
        with pytest.raises(RateLimitError) as exc_info:
            _raise_for_status(429, {"error": "Rate limited"}, {"retry-after": "30"})
        assert exc_info.value.status_code == 429
        assert exc_info.value.retry_after == 30.0

    def test_429_without_retry_after(self):
        with pytest.raises(RateLimitError) as exc_info:
            _raise_for_status(429, {"error": "Rate limited"}, {})
        assert exc_info.value.retry_after is None

    def test_500(self):
        with pytest.raises(InternalServerError) as exc_info:
            _raise_for_status(500, {"error": {"message": "Server error"}}, {})
        assert exc_info.value.status_code == 500

    def test_502(self):
        with pytest.raises(InternalServerError) as exc_info:
            _raise_for_status(502, "Bad Gateway", {})
        assert exc_info.value.status_code == 502

    def test_generic_4xx(self):
        with pytest.raises(APIError) as exc_info:
            _raise_for_status(422, {"error": {"message": "Unprocessable"}}, {})
        assert exc_info.value.status_code == 422

    def test_string_body(self):
        with pytest.raises(APIError) as exc_info:
            _raise_for_status(400, "Bad request body", {})
        assert "Bad request body" in exc_info.value.message

    def test_none_body(self):
        with pytest.raises(APIError):
            _raise_for_status(400, None, {})


class TestErrorResponseFromAPI:
    def test_401_response(self, sync_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(
                401, json={"error": {"message": "Invalid API key"}}
            )
        )

        with pytest.raises(AuthenticationError):
            sync_client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": "Hello"}],
            )

    def test_404_response(self, sync_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(
                404, json={"error": {"message": "Model not found"}}
            )
        )

        with pytest.raises(NotFoundError):
            sync_client.chat.completions.create(
                model="nonexistent",
                messages=[{"role": "user", "content": "Hello"}],
            )

    def test_500_response(self, sync_client, mock_llm):
        mock_llm.post("/chat/completions").mock(
            return_value=httpx.Response(
                500, json={"error": {"message": "Internal server error"}}
            )
        )

        with pytest.raises(InternalServerError):
            sync_client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": "Hello"}],
            )


class TestRetryLogic:
    def test_retries_on_429(self):
        """With retries enabled, a 429 followed by 200 should succeed."""
        client = CortexClient(
            api_key="sk-test",
            llm_base_url=TEST_LLM_BASE,
            max_retries=2,
        )

        call_count = 0

        def side_effect(request: httpx.Request) -> httpx.Response:
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return httpx.Response(
                    429,
                    json={"error": "Rate limited"},
                    headers={"retry-after": "0"},
                )
            return httpx.Response(200, json=chat_completion_response())

        import respx
        with respx.mock(base_url=TEST_LLM_BASE) as mock:
            mock.post("/chat/completions").mock(side_effect=side_effect)

            result = client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": "Hello"}],
            )

            assert isinstance(result, ChatCompletion)
            assert call_count == 2

        client.close()

    def test_retries_on_500(self):
        """With retries enabled, a 500 followed by 200 should succeed."""
        client = CortexClient(
            api_key="sk-test",
            llm_base_url=TEST_LLM_BASE,
            max_retries=2,
        )

        call_count = 0

        def side_effect(request: httpx.Request) -> httpx.Response:
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                return httpx.Response(500, json={"error": "Server error"})
            return httpx.Response(200, json=chat_completion_response())

        import respx
        with respx.mock(base_url=TEST_LLM_BASE) as mock:
            mock.post("/chat/completions").mock(side_effect=side_effect)

            result = client.chat.completions.create(
                model="gpt-4",
                messages=[{"role": "user", "content": "Hello"}],
            )

            assert isinstance(result, ChatCompletion)
            assert call_count == 2

        client.close()

    def test_no_retry_on_400(self):
        """Non-retryable errors should not be retried."""
        client = CortexClient(
            api_key="sk-test",
            llm_base_url=TEST_LLM_BASE,
            max_retries=3,
        )

        call_count = 0

        def side_effect(request: httpx.Request) -> httpx.Response:
            nonlocal call_count
            call_count += 1
            return httpx.Response(400, json={"error": {"message": "Bad request"}})

        import respx
        with respx.mock(base_url=TEST_LLM_BASE) as mock:
            mock.post("/chat/completions").mock(side_effect=side_effect)

            with pytest.raises(APIError):
                client.chat.completions.create(
                    model="gpt-4",
                    messages=[{"role": "user", "content": "Hello"}],
                )

            assert call_count == 1  # No retry

        client.close()


class TestErrorRepr:
    def test_api_error_repr(self):
        err = APIError("test error", status_code=400)
        assert "400" in repr(err)
        assert "test error" in repr(err)

    def test_error_preserves_body(self):
        body = {"error": {"message": "bad request", "code": "invalid_model"}}
        err = APIError("bad request", status_code=400, body=body)
        assert err.body == body

    def test_error_preserves_headers(self):
        headers = {"x-request-id": "req-123"}
        err = APIError("error", status_code=500, headers=headers)
        assert err.headers["x-request-id"] == "req-123"
