"""Pydantic models for the Cortex SDK."""

from __future__ import annotations

from typing import Any, Dict, List, Literal, Optional, Union

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Chat / Completions shared types
# ---------------------------------------------------------------------------


class ChatMessage(BaseModel):
    """A single message in a chat conversation."""

    role: Literal["system", "user", "assistant", "function", "tool"]
    content: Optional[str] = None
    name: Optional[str] = None
    function_call: Optional[Dict[str, Any]] = None
    tool_calls: Optional[List[Dict[str, Any]]] = None
    tool_call_id: Optional[str] = None


class FunctionDefinition(BaseModel):
    name: str
    description: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None


class ToolDefinition(BaseModel):
    type: Literal["function"] = "function"
    function: FunctionDefinition


class ResponseFormat(BaseModel):
    type: Literal["text", "json_object"] = "text"


# ---------------------------------------------------------------------------
# Chat Completion Request
# ---------------------------------------------------------------------------


class ChatCompletionRequest(BaseModel):
    model: Optional[str] = None
    messages: List[ChatMessage]
    temperature: Optional[float] = None
    top_p: Optional[float] = None
    n: Optional[int] = None
    stream: Optional[bool] = None
    stop: Optional[Union[str, List[str]]] = None
    max_tokens: Optional[int] = None
    presence_penalty: Optional[float] = None
    frequency_penalty: Optional[float] = None
    logit_bias: Optional[Dict[str, float]] = None
    user: Optional[str] = None
    functions: Optional[List[FunctionDefinition]] = None
    function_call: Optional[Union[str, Dict[str, str]]] = None
    tools: Optional[List[ToolDefinition]] = None
    tool_choice: Optional[Union[str, Dict[str, Any]]] = None
    response_format: Optional[ResponseFormat] = None
    seed: Optional[int] = None


# ---------------------------------------------------------------------------
# Chat Completion Response
# ---------------------------------------------------------------------------


class ChoiceDelta(BaseModel):
    model_config = ConfigDict(frozen=True)

    role: Optional[str] = None
    content: Optional[str] = None
    function_call: Optional[Dict[str, Any]] = None
    tool_calls: Optional[List[Dict[str, Any]]] = None


class ChoiceMessage(BaseModel):
    model_config = ConfigDict(frozen=True)

    role: str
    content: Optional[str] = None
    function_call: Optional[Dict[str, Any]] = None
    tool_calls: Optional[List[Dict[str, Any]]] = None


class Choice(BaseModel):
    model_config = ConfigDict(frozen=True)

    index: int
    message: ChoiceMessage
    finish_reason: Optional[str] = None


class StreamChoice(BaseModel):
    model_config = ConfigDict(frozen=True)

    index: int
    delta: ChoiceDelta
    finish_reason: Optional[str] = None


class Usage(BaseModel):
    model_config = ConfigDict(frozen=True)

    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0


class ChatCompletion(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    object: str = "chat.completion"
    created: int
    model: str
    choices: List[Choice]
    usage: Optional[Usage] = None
    system_fingerprint: Optional[str] = None


class ChatCompletionChunk(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    object: str = "chat.completion.chunk"
    created: int
    model: str
    choices: List[StreamChoice]
    system_fingerprint: Optional[str] = None


# ---------------------------------------------------------------------------
# Text Completion
# ---------------------------------------------------------------------------


class CompletionRequest(BaseModel):
    model: Optional[str] = None
    prompt: Union[str, List[str]]
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None
    top_p: Optional[float] = None
    n: Optional[int] = None
    stream: Optional[bool] = None
    logprobs: Optional[int] = None
    echo: Optional[bool] = None
    stop: Optional[Union[str, List[str]]] = None
    presence_penalty: Optional[float] = None
    frequency_penalty: Optional[float] = None
    best_of: Optional[int] = None
    logit_bias: Optional[Dict[str, float]] = None
    user: Optional[str] = None
    suffix: Optional[str] = None
    seed: Optional[int] = None


class CompletionChoice(BaseModel):
    model_config = ConfigDict(frozen=True)

    index: int
    text: str
    logprobs: Optional[Any] = None
    finish_reason: Optional[str] = None


class Completion(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    object: str = "text_completion"
    created: int
    model: str
    choices: List[CompletionChoice]
    usage: Optional[Usage] = None
    system_fingerprint: Optional[str] = None


class CompletionChunk(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    object: str = "text_completion"
    created: int
    model: str
    choices: List[CompletionChoice]
    system_fingerprint: Optional[str] = None


# ---------------------------------------------------------------------------
# Embeddings
# ---------------------------------------------------------------------------


class EmbeddingRequest(BaseModel):
    model: Optional[str] = None
    input: Union[str, List[str]]
    encoding_format: Optional[Literal["float", "base64"]] = None
    user: Optional[str] = None
    dimensions: Optional[int] = None


class EmbeddingData(BaseModel):
    model_config = ConfigDict(frozen=True)

    object: str = "embedding"
    embedding: List[float]
    index: int


class EmbeddingResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    object: str = "list"
    data: List[EmbeddingData]
    model: str
    usage: Optional[Usage] = None


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------


class ModelPermission(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: Optional[str] = None
    object: Optional[str] = None
    created: Optional[int] = None
    allow_create_engine: Optional[bool] = None
    allow_sampling: Optional[bool] = None
    allow_logprobs: Optional[bool] = None
    allow_search_indices: Optional[bool] = None
    allow_view: Optional[bool] = None
    allow_fine_tuning: Optional[bool] = None
    organization: Optional[str] = None
    group: Optional[str] = None
    is_blocking: Optional[bool] = None


class Model(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    object: str = "model"
    created: Optional[int] = None
    owned_by: Optional[str] = None
    permission: Optional[List[ModelPermission]] = None
    root: Optional[str] = None
    parent: Optional[str] = None


class ModelList(BaseModel):
    model_config = ConfigDict(frozen=True)

    object: str = "list"
    data: List[Model]


# ---------------------------------------------------------------------------
# API Keys
# ---------------------------------------------------------------------------


class APIKey(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    key: Optional[str] = None
    created_at: Optional[str] = None
    last_used_at: Optional[str] = None
    expires_at: Optional[str] = None
    status: Optional[str] = None
    scopes: Optional[List[str]] = None


class APIKeyCreate(BaseModel):
    name: str
    scopes: Optional[List[str]] = None
    expires_at: Optional[str] = None


class APIKeyList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[APIKey] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Teams
# ---------------------------------------------------------------------------


class TeamMember(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    email: Optional[str] = None
    name: Optional[str] = None
    role: Optional[str] = None
    joined_at: Optional[str] = None


class Team(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    description: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    members: Optional[List[TeamMember]] = None
    member_count: Optional[int] = None


class TeamCreate(BaseModel):
    name: str
    description: Optional[str] = None


class TeamMemberAdd(BaseModel):
    email: str
    role: Optional[str] = "member"


class TeamMemberUpdate(BaseModel):
    role: str


class TeamList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[Team] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------


class UsageRecord(BaseModel):
    model_config = ConfigDict(frozen=True)

    date: Optional[str] = None
    model: Optional[str] = None
    requests: Optional[int] = None
    tokens: Optional[int] = None
    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    cost: Optional[float] = None


class UsageStats(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[UsageRecord] = Field(default_factory=list)
    total_requests: Optional[int] = None
    total_tokens: Optional[int] = None
    total_cost: Optional[float] = None
    period: Optional[str] = None


class UsageLimits(BaseModel):
    model_config = ConfigDict(frozen=True)

    requests_per_minute: Optional[int] = None
    requests_per_day: Optional[int] = None
    tokens_per_minute: Optional[int] = None
    tokens_per_day: Optional[int] = None
    max_tokens_per_request: Optional[int] = None
    remaining_requests: Optional[int] = None
    remaining_tokens: Optional[int] = None
    reset_at: Optional[str] = None


# ---------------------------------------------------------------------------
# Performance
# ---------------------------------------------------------------------------


class PerformanceMetrics(BaseModel):
    model_config = ConfigDict(frozen=True)

    avg_latency_ms: Optional[float] = None
    p50_latency_ms: Optional[float] = None
    p95_latency_ms: Optional[float] = None
    p99_latency_ms: Optional[float] = None
    success_rate: Optional[float] = None
    error_rate: Optional[float] = None
    total_requests: Optional[int] = None
    tokens_per_second: Optional[float] = None
    period: Optional[str] = None
    data: Optional[List[Dict[str, Any]]] = None


# ---------------------------------------------------------------------------
# Conversations
# ---------------------------------------------------------------------------


class ConversationMessage(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: Optional[str] = None
    role: Optional[str] = None
    content: Optional[str] = None
    created_at: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class Conversation(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    title: Optional[str] = None
    model: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    message_count: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None
    messages: Optional[List[ConversationMessage]] = None


class ConversationCreate(BaseModel):
    title: Optional[str] = None
    model: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class ConversationUpdate(BaseModel):
    title: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class ConversationList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[Conversation] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Iris (Extraction)
# ---------------------------------------------------------------------------


class IrisExtractionRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    document: Optional[str] = None
    document_url: Optional[str] = None
    schema_id: Optional[str] = None
    schema_def: Optional[Dict[str, Any]] = Field(default=None, alias="schema")
    options: Optional[Dict[str, Any]] = None


class IrisJob(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    status: Optional[str] = None
    created_at: Optional[str] = None
    completed_at: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    document_url: Optional[str] = None
    schema_id: Optional[str] = None


class IrisJobList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[IrisJob] = Field(default_factory=list)


class IrisSchema(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    description: Optional[str] = None
    schema_def: Optional[Dict[str, Any]] = Field(default=None, alias="schema")
    created_at: Optional[str] = None


class IrisSchemaList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[IrisSchema] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Plugins
# ---------------------------------------------------------------------------


class Plugin(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    description: Optional[str] = None
    version: Optional[str] = None
    enabled: Optional[bool] = None
    config: Optional[Dict[str, Any]] = None


class PluginList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[Plugin] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Optimizations
# ---------------------------------------------------------------------------


class OptimizationSettings(BaseModel):
    model_config = ConfigDict(frozen=True)

    caching_enabled: Optional[bool] = None
    cache_ttl_seconds: Optional[int] = None
    prompt_compression: Optional[bool] = None
    smart_routing: Optional[bool] = None
    fallback_models: Optional[List[str]] = None
    settings: Optional[Dict[str, Any]] = None


# ---------------------------------------------------------------------------
# Models Config (admin)
# ---------------------------------------------------------------------------


class ModelConfig(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    provider: Optional[str] = None
    enabled: Optional[bool] = None
    max_tokens: Optional[int] = None
    input_cost_per_token: Optional[float] = None
    output_cost_per_token: Optional[float] = None
    config: Optional[Dict[str, Any]] = None


class ModelConfigList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[ModelConfig] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# PDF
# ---------------------------------------------------------------------------


class PDFGenerateRequest(BaseModel):
    content: Optional[str] = None
    template: Optional[str] = None
    data: Optional[Dict[str, Any]] = None
    options: Optional[Dict[str, Any]] = None


class PDFGenerateResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    url: Optional[str] = None
    id: Optional[str] = None
    status: Optional[str] = None
    size_bytes: Optional[int] = None


# ---------------------------------------------------------------------------
# Web Search
# ---------------------------------------------------------------------------


class WebSearchRequest(BaseModel):
    query: str
    num_results: Optional[int] = None
    language: Optional[str] = None
    region: Optional[str] = None


class WebSearchResult(BaseModel):
    model_config = ConfigDict(frozen=True)

    title: Optional[str] = None
    url: Optional[str] = None
    snippet: Optional[str] = None
    score: Optional[float] = None


class WebSearchResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    results: List[WebSearchResult] = Field(default_factory=list)
    query: Optional[str] = None
    total_results: Optional[int] = None


# ---------------------------------------------------------------------------
# Delete Response
# ---------------------------------------------------------------------------


class DeleteResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: Optional[str] = None
    deleted: bool = True
    object: Optional[str] = None


# ---------------------------------------------------------------------------
# Pools
# ---------------------------------------------------------------------------


class PoolBackend(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    base_url: Optional[str] = None


class Pool(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    description: Optional[str] = None
    strategy: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    backends: Optional[List[PoolBackend]] = None


class PoolCreate(BaseModel):
    name: str
    description: Optional[str] = None
    strategy: Optional[str] = None


class PoolUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    strategy: Optional[str] = None


class PoolList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[Pool] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Backends
# ---------------------------------------------------------------------------


class BackendModel(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    display_name: Optional[str] = None


class Backend(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    base_url: Optional[str] = None
    provider: Optional[str] = None
    enabled: Optional[bool] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    models: Optional[List[BackendModel]] = None


class BackendCreate(BaseModel):
    name: str
    base_url: str
    provider: Optional[str] = None
    enabled: Optional[bool] = None


class BackendUpdate(BaseModel):
    name: Optional[str] = None
    base_url: Optional[str] = None
    provider: Optional[str] = None
    enabled: Optional[bool] = None


class BackendList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[Backend] = Field(default_factory=list)


class DiscoverModelsResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    models: List[BackendModel] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------


class CortexUser(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    email: Optional[str] = None
    name: Optional[str] = None
    role: Optional[str] = None
    status: Optional[str] = None
    created_at: Optional[str] = None
    last_login_at: Optional[str] = None


class CortexUserUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None
    status: Optional[str] = None


class CortexUserList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[CortexUser] = Field(default_factory=list)


class PendingCount(BaseModel):
    model_config = ConfigDict(frozen=True)

    count: int = 0


# ---------------------------------------------------------------------------
# Usage Limits (Admin)
# ---------------------------------------------------------------------------


class UsageLimit(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: Optional[str] = None
    user_id: Optional[str] = None
    team_id: Optional[str] = None
    requests_per_minute: Optional[int] = None
    requests_per_day: Optional[int] = None
    tokens_per_minute: Optional[int] = None
    tokens_per_day: Optional[int] = None


class UsageLimitSet(BaseModel):
    requests_per_minute: Optional[int] = None
    requests_per_day: Optional[int] = None
    tokens_per_minute: Optional[int] = None
    tokens_per_day: Optional[int] = None


class UsageLimitList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[UsageLimit] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Admin API Keys
# ---------------------------------------------------------------------------


class AdminApiKey(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    name: Optional[str] = None
    key: Optional[str] = None
    created_at: Optional[str] = None
    last_used_at: Optional[str] = None
    expires_at: Optional[str] = None
    status: Optional[str] = None


class AdminApiKeyCreate(BaseModel):
    name: str
    expires_at: Optional[str] = None


class AdminApiKeyUpdate(BaseModel):
    name: Optional[str] = None
    expires_at: Optional[str] = None


class AdminApiKeyList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[AdminApiKey] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Audit Log
# ---------------------------------------------------------------------------


class AuditLogEntry(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    action: Optional[str] = None
    actor_id: Optional[str] = None
    actor_email: Optional[str] = None
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    created_at: Optional[str] = None


class AuditLogList(BaseModel):
    model_config = ConfigDict(frozen=True)

    data: List[AuditLogEntry] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------


class AuthTokenResponse(BaseModel):
    model_config = ConfigDict(frozen=True)

    token: str
    expires_at: Optional[str] = None
    user: Optional[Dict[str, Any]] = None


class AuthProfile(BaseModel):
    model_config = ConfigDict(frozen=True)

    id: str
    email: Optional[str] = None
    name: Optional[str] = None
    role: Optional[str] = None
    created_at: Optional[str] = None


class AuthProfileUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None


# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------


class AudioTranscription(BaseModel):
    model_config = ConfigDict(frozen=True)

    text: str
    language: Optional[str] = None
    duration: Optional[float] = None
    segments: Optional[List[Dict[str, Any]]] = None
