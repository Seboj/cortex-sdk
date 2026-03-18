"""Tests for usage and performance resources."""

from __future__ import annotations

import httpx
import pytest

from cortex_sdk.types import PerformanceMetrics, UsageLimits, UsageStats


class TestUsageSync:
    def test_get(self, sync_client, mock_admin):
        mock_admin.get("/api/usage").mock(
            return_value=httpx.Response(
                200,
                json={
                    "data": [
                        {"date": "2024-01-01", "model": "gpt-4", "requests": 100, "tokens": 5000}
                    ],
                    "total_requests": 100,
                    "total_tokens": 5000,
                    "total_cost": 0.50,
                    "period": "2024-01",
                },
            )
        )

        result = sync_client.usage.get()
        assert isinstance(result, UsageStats)
        assert result.total_requests == 100
        assert len(result.data) == 1

    def test_get_with_params(self, sync_client, mock_admin):
        route = mock_admin.get("/api/usage").mock(
            return_value=httpx.Response(
                200, json={"data": [], "total_requests": 0}
            )
        )

        sync_client.usage.get(params={"start_date": "2024-01-01", "end_date": "2024-01-31"})
        request = route.calls.last.request
        assert "start_date" in str(request.url)

    def test_limits(self, sync_client, mock_admin):
        mock_admin.get("/api/usage/limits").mock(
            return_value=httpx.Response(
                200,
                json={
                    "requests_per_minute": 60,
                    "requests_per_day": 10000,
                    "tokens_per_minute": 100000,
                    "remaining_requests": 59,
                },
            )
        )

        result = sync_client.usage.limits()
        assert isinstance(result, UsageLimits)
        assert result.requests_per_minute == 60
        assert result.remaining_requests == 59


class TestUsageAsync:
    @pytest.mark.asyncio
    async def test_get(self, async_client, mock_admin):
        mock_admin.get("/api/usage").mock(
            return_value=httpx.Response(
                200,
                json={"data": [], "total_requests": 0, "total_tokens": 0},
            )
        )

        result = await async_client.usage.get()
        assert isinstance(result, UsageStats)

    @pytest.mark.asyncio
    async def test_limits(self, async_client, mock_admin):
        mock_admin.get("/api/usage/limits").mock(
            return_value=httpx.Response(
                200, json={"requests_per_minute": 60, "tokens_per_minute": 100000}
            )
        )

        result = await async_client.usage.limits()
        assert isinstance(result, UsageLimits)


class TestPerformanceSync:
    def test_get(self, sync_client, mock_admin):
        mock_admin.get("/api/performance").mock(
            return_value=httpx.Response(
                200,
                json={
                    "avg_latency_ms": 250.5,
                    "p95_latency_ms": 800.0,
                    "success_rate": 0.995,
                    "total_requests": 50000,
                },
            )
        )

        result = sync_client.performance.get()
        assert isinstance(result, PerformanceMetrics)
        assert result.avg_latency_ms == 250.5
        assert result.success_rate == 0.995


class TestPerformanceAsync:
    @pytest.mark.asyncio
    async def test_get(self, async_client, mock_admin):
        mock_admin.get("/api/performance").mock(
            return_value=httpx.Response(
                200,
                json={"avg_latency_ms": 200.0, "p95_latency_ms": 500.0},
            )
        )

        result = await async_client.performance.get()
        assert isinstance(result, PerformanceMetrics)
