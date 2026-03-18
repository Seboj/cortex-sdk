"""Cortex SDK clients — sync and async."""

from __future__ import annotations

from typing import Dict, Optional

from cortex_sdk._http import AsyncHTTPClient, SyncHTTPClient
from cortex_sdk.constants import (
    DEFAULT_ADMIN_BASE_URL,
    DEFAULT_LLM_BASE_URL,
    DEFAULT_MAX_RETRIES,
    DEFAULT_STREAMING_TIMEOUT,
    DEFAULT_TIMEOUT,
)
from cortex_sdk.resources.admin_keys import AdminKeys as AdminKeysResource
from cortex_sdk.resources.admin_keys import AsyncAdminKeys as AsyncAdminKeysResource
from cortex_sdk.resources.audio import AsyncAudio, Audio
from cortex_sdk.resources.audit_log import AsyncAuditLog, AuditLog
from cortex_sdk.resources.auth import AsyncAuth, Auth
from cortex_sdk.resources.backends import AsyncBackends, Backends
from cortex_sdk.resources.chat import AsyncChat, Chat
from cortex_sdk.resources.completions import AsyncCompletions, Completions
from cortex_sdk.resources.conversations import AsyncConversations, Conversations
from cortex_sdk.resources.embeddings import AsyncEmbeddings, Embeddings
from cortex_sdk.resources.iris import AsyncIris, Iris
from cortex_sdk.resources.keys import AsyncKeys, Keys
from cortex_sdk.resources.models import AdminModels, AsyncAdminModels, AsyncModels, Models
from cortex_sdk.resources.pdf import AsyncPDF, PDF
from cortex_sdk.resources.performance import AsyncPerformance, Performance
from cortex_sdk.resources.plugins import (
    AsyncOptimizations,
    AsyncPlugins,
    Optimizations,
    Plugins,
)
from cortex_sdk.resources.pools import AsyncPools, Pools
from cortex_sdk.resources.teams import AsyncTeams, Teams
from cortex_sdk.resources.usage import AsyncUsage, Usage
from cortex_sdk.resources.usage_limits import AsyncUsageLimitsAdmin, UsageLimitsAdmin
from cortex_sdk.resources.users import AsyncUsers, Users
from cortex_sdk.resources.web_search import AsyncWebSearch, WebSearch


class CortexClient:
    """Synchronous Cortex SDK client.

    Provides access to both the LLM Gateway API and the Admin/Platform API.

    Usage::

        client = CortexClient(api_key="sk-cortex-...")
        response = client.chat.completions.create(
            model="default",
            messages=[{"role": "user", "content": "Hello!"}],
        )
        print(response.choices[0].message.content)
        client.close()
    """

    def __init__(
        self,
        *,
        api_key: str,
        llm_base_url: str = DEFAULT_LLM_BASE_URL,
        admin_base_url: str = DEFAULT_ADMIN_BASE_URL,
        timeout: float = DEFAULT_TIMEOUT,
        streaming_timeout: float = DEFAULT_STREAMING_TIMEOUT,
        max_retries: int = DEFAULT_MAX_RETRIES,
        extra_headers: Optional[Dict[str, str]] = None,
        default_pool: Optional[str] = None,
    ) -> None:
        if not api_key:
            raise ValueError("api_key must be provided and non-empty")

        self._api_key = api_key
        self._default_pool = default_pool

        # LLM gateway HTTP client
        self._llm_http = SyncHTTPClient(
            api_key=api_key,
            base_url=llm_base_url,
            timeout=timeout,
            streaming_timeout=streaming_timeout,
            max_retries=max_retries,
            extra_headers=extra_headers,
        )

        # Admin HTTP client
        self._admin_http = SyncHTTPClient(
            api_key=api_key,
            base_url=admin_base_url,
            timeout=timeout,
            streaming_timeout=streaming_timeout,
            max_retries=max_retries,
            extra_headers=extra_headers,
        )

        # LLM Gateway resources
        self.chat = Chat(self._llm_http, default_pool=default_pool)
        self.completions = Completions(self._llm_http, default_pool=default_pool)
        self.embeddings = Embeddings(self._llm_http, default_pool=default_pool)
        self.models = Models(self._llm_http)
        self.audio = Audio(self._llm_http, default_pool=default_pool)

        # Admin resources
        self.keys = Keys(self._admin_http)
        self.teams = Teams(self._admin_http)
        self.usage = Usage(self._admin_http)
        self.performance = Performance(self._admin_http)
        self.conversations = Conversations(self._admin_http)
        self.iris = Iris(self._admin_http)
        self.plugins = Plugins(self._admin_http)
        self.optimizations = Optimizations(self._admin_http)
        self.admin_models = AdminModels(self._admin_http)
        self.pdf = PDF(self._admin_http)
        self.web_search = WebSearch(self._admin_http)
        self.pools = Pools(self._admin_http)
        self.backends = Backends(self._admin_http)
        self.users = Users(self._admin_http)
        self.usage_limits = UsageLimitsAdmin(self._admin_http)
        self.admin_keys = AdminKeysResource(self._admin_http)
        self.audit_log = AuditLog(self._admin_http)
        self.auth = Auth(self._admin_http)

    def close(self) -> None:
        """Close underlying HTTP connections."""
        self._llm_http.close()
        self._admin_http.close()

    def __enter__(self) -> CortexClient:
        return self

    def __exit__(self, *args: object) -> None:
        self.close()

    def __repr__(self) -> str:
        return f"CortexClient(api_key='sk-***')"


class AsyncCortexClient:
    """Asynchronous Cortex SDK client.

    Usage::

        async with AsyncCortexClient(api_key="sk-cortex-...") as client:
            response = await client.chat.completions.create(
                model="default",
                messages=[{"role": "user", "content": "Hello!"}],
            )
            print(response.choices[0].message.content)
    """

    def __init__(
        self,
        *,
        api_key: str,
        llm_base_url: str = DEFAULT_LLM_BASE_URL,
        admin_base_url: str = DEFAULT_ADMIN_BASE_URL,
        timeout: float = DEFAULT_TIMEOUT,
        streaming_timeout: float = DEFAULT_STREAMING_TIMEOUT,
        max_retries: int = DEFAULT_MAX_RETRIES,
        extra_headers: Optional[Dict[str, str]] = None,
        default_pool: Optional[str] = None,
    ) -> None:
        if not api_key:
            raise ValueError("api_key must be provided and non-empty")

        self._api_key = api_key
        self._default_pool = default_pool

        self._llm_http = AsyncHTTPClient(
            api_key=api_key,
            base_url=llm_base_url,
            timeout=timeout,
            streaming_timeout=streaming_timeout,
            max_retries=max_retries,
            extra_headers=extra_headers,
        )

        self._admin_http = AsyncHTTPClient(
            api_key=api_key,
            base_url=admin_base_url,
            timeout=timeout,
            streaming_timeout=streaming_timeout,
            max_retries=max_retries,
            extra_headers=extra_headers,
        )

        # LLM Gateway resources
        self.chat = AsyncChat(self._llm_http, default_pool=default_pool)
        self.completions = AsyncCompletions(self._llm_http, default_pool=default_pool)
        self.embeddings = AsyncEmbeddings(self._llm_http, default_pool=default_pool)
        self.models = AsyncModels(self._llm_http)
        self.audio = AsyncAudio(self._llm_http, default_pool=default_pool)

        # Admin resources
        self.keys = AsyncKeys(self._admin_http)
        self.teams = AsyncTeams(self._admin_http)
        self.usage = AsyncUsage(self._admin_http)
        self.performance = AsyncPerformance(self._admin_http)
        self.conversations = AsyncConversations(self._admin_http)
        self.iris = AsyncIris(self._admin_http)
        self.plugins = AsyncPlugins(self._admin_http)
        self.optimizations = AsyncOptimizations(self._admin_http)
        self.admin_models = AsyncAdminModels(self._admin_http)
        self.pdf = AsyncPDF(self._admin_http)
        self.web_search = AsyncWebSearch(self._admin_http)
        self.pools = AsyncPools(self._admin_http)
        self.backends = AsyncBackends(self._admin_http)
        self.users = AsyncUsers(self._admin_http)
        self.usage_limits = AsyncUsageLimitsAdmin(self._admin_http)
        self.admin_keys = AsyncAdminKeysResource(self._admin_http)
        self.audit_log = AsyncAuditLog(self._admin_http)
        self.auth = AsyncAuth(self._admin_http)

    async def close(self) -> None:
        """Close underlying HTTP connections."""
        await self._llm_http.close()
        await self._admin_http.close()

    async def __aenter__(self) -> AsyncCortexClient:
        return self

    async def __aexit__(self, *args: object) -> None:
        await self.close()

    def __repr__(self) -> str:
        return f"AsyncCortexClient(api_key='sk-***')"
