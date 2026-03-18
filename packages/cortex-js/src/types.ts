// ─── Client Configuration ────────────────────────────────────────────────────

export interface CortexClientOptions {
  /** API key for authentication. Required. */
  apiKey: string;
  /** Base URL for LLM Gateway endpoints (default: https://cortexapi.nfinitmonkeys.com/v1) */
  llmBaseUrl?: string;
  /** Base URL for Admin/Platform API (default: https://admin.nfinitmonkeys.com) */
  adminBaseUrl?: string;
  /** Request timeout in milliseconds (default: 30000) */
  timeout?: number;
  /** Streaming request timeout in milliseconds (default: 300000) */
  streamTimeout?: number;
  /** Maximum number of retries on retryable errors (default: 3) */
  maxRetries?: number;
  /** Custom fetch implementation (default: global fetch) */
  fetch?: typeof globalThis.fetch;
  /** Default headers to include in all requests */
  defaultHeaders?: Record<string, string>;
  /**
   * Default pool slug for routing requests.
   * Known pools: 'default', 'cortexvlm' (vision), 'cortex-stt' (speech-to-text),
   * 'cortex-stt-diarize' (STT with speaker diarization).
   * When set, all LLM requests include `x-cortex-pool` header unless overridden per-request.
   */
  defaultPool?: string;
}

export interface RequestOptions {
  signal?: AbortSignal;
  timeout?: number;
  headers?: Record<string, string>;
}

// ─── Chat Completions ────────────────────────────────────────────────────────

export type ChatRole = 'system' | 'user' | 'assistant' | 'tool' | 'function';

export interface ChatMessage {
  role: ChatRole;
  content: string | null;
  name?: string;
  tool_calls?: ToolCall[];
  tool_call_id?: string;
  function_call?: FunctionCall;
}

export interface ToolCall {
  id: string;
  type: 'function';
  function: FunctionCall;
}

export interface FunctionCall {
  name: string;
  arguments: string;
}

export interface ToolDefinition {
  type: 'function';
  function: FunctionDefinition;
}

export interface FunctionDefinition {
  name: string;
  description?: string;
  parameters?: Record<string, unknown>;
}

export interface ResponseFormat {
  type: 'text' | 'json_object';
}

export interface ChatCompletionCreateParamsBase {
  /** Model identifier. If omitted, the pool's default model is used. */
  model?: string;
  messages: ChatMessage[];
  temperature?: number;
  top_p?: number;
  n?: number;
  max_tokens?: number;
  stop?: string | string[];
  presence_penalty?: number;
  frequency_penalty?: number;
  logit_bias?: Record<string, number>;
  user?: string;
  tools?: ToolDefinition[];
  tool_choice?: 'none' | 'auto' | 'required' | { type: 'function'; function: { name: string } };
  response_format?: ResponseFormat;
  seed?: number;
}

export interface ChatCompletionCreateParamsNonStreaming extends ChatCompletionCreateParamsBase {
  stream?: false | undefined;
}

export interface ChatCompletionCreateParamsStreaming extends ChatCompletionCreateParamsBase {
  stream: true;
}

export type ChatCompletionCreateParams =
  | ChatCompletionCreateParamsNonStreaming
  | ChatCompletionCreateParamsStreaming;

export interface ChatCompletionChoice {
  index: number;
  message: ChatMessage;
  finish_reason: 'stop' | 'length' | 'tool_calls' | 'content_filter' | 'function_call' | null;
  logprobs?: unknown;
}

export interface ChatCompletion {
  id: string;
  object: 'chat.completion';
  created: number;
  model: string;
  choices: ChatCompletionChoice[];
  usage?: CompletionUsage;
  system_fingerprint?: string;
}

export interface ChatCompletionChunkDelta {
  role?: ChatRole;
  content?: string | null;
  tool_calls?: ToolCall[];
  function_call?: Partial<FunctionCall>;
}

export interface ChatCompletionChunkChoice {
  index: number;
  delta: ChatCompletionChunkDelta;
  finish_reason: 'stop' | 'length' | 'tool_calls' | 'content_filter' | 'function_call' | null;
  logprobs?: unknown;
}

export interface ChatCompletionChunk {
  id: string;
  object: 'chat.completion.chunk';
  created: number;
  model: string;
  choices: ChatCompletionChunkChoice[];
  usage?: CompletionUsage | null;
  system_fingerprint?: string;
}

// ─── Text Completions ────────────────────────────────────────────────────────

export interface CompletionCreateParams {
  /** Model identifier. If omitted, the pool's default model is used. */
  model?: string;
  prompt: string | string[];
  max_tokens?: number;
  temperature?: number;
  top_p?: number;
  n?: number;
  stream?: boolean;
  logprobs?: number;
  echo?: boolean;
  stop?: string | string[];
  presence_penalty?: number;
  frequency_penalty?: number;
  best_of?: number;
  logit_bias?: Record<string, number>;
  user?: string;
  suffix?: string;
}

export interface CompletionChoice {
  text: string;
  index: number;
  logprobs: unknown;
  finish_reason: 'stop' | 'length' | null;
}

export interface Completion {
  id: string;
  object: 'text_completion';
  created: number;
  model: string;
  choices: CompletionChoice[];
  usage?: CompletionUsage;
}

// ─── Embeddings ──────────────────────────────────────────────────────────────

export interface EmbeddingCreateParams {
  /** Model identifier. If omitted, the pool's default model is used. */
  model?: string;
  input: string | string[];
  encoding_format?: 'float' | 'base64';
  dimensions?: number;
  user?: string;
}

export interface EmbeddingData {
  object: 'embedding';
  embedding: number[];
  index: number;
}

export interface EmbeddingResponse {
  object: 'list';
  data: EmbeddingData[];
  model: string;
  usage: {
    prompt_tokens: number;
    total_tokens: number;
  };
}

// ─── Models ──────────────────────────────────────────────────────────────────

export interface Model {
  id: string;
  object: 'model';
  created: number;
  owned_by: string;
  permission?: ModelPermission[];
  root?: string;
  parent?: string | null;
}

export interface ModelPermission {
  id: string;
  object: 'model_permission';
  created: number;
  allow_create_engine: boolean;
  allow_sampling: boolean;
  allow_logprobs: boolean;
  allow_search_indices: boolean;
  allow_view: boolean;
  allow_fine_tuning: boolean;
  organization: string;
  group: string | null;
  is_blocking: boolean;
}

export interface ModelList {
  object: 'list';
  data: Model[];
}

// ─── Shared ──────────────────────────────────────────────────────────────────

export interface CompletionUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

// ─── Admin: API Keys ─────────────────────────────────────────────────────────

export interface ApiKey {
  id: string;
  name: string;
  key: string;
  createdAt: string;
  lastUsedAt?: string | null;
  expiresAt?: string | null;
  scopes?: string[];
}

export interface ApiKeyCreateParams {
  name: string;
  scopes?: string[];
  expiresAt?: string;
}

export interface ApiKeyListResponse {
  keys: ApiKey[];
}

// ─── Admin: Teams ────────────────────────────────────────────────────────────

export interface Team {
  id: string;
  name: string;
  description?: string;
  createdAt: string;
  updatedAt: string;
  members?: TeamMember[];
}

export interface TeamMember {
  id: string;
  userId: string;
  email?: string;
  role: 'owner' | 'admin' | 'member' | 'viewer';
  joinedAt: string;
}

export interface TeamCreateParams {
  name: string;
  description?: string;
}

export interface TeamListResponse {
  teams: Team[];
}

export interface TeamMemberAddParams {
  userId: string;
  email?: string;
  role: 'admin' | 'member' | 'viewer';
}

export interface TeamMemberUpdateParams {
  role: 'admin' | 'member' | 'viewer';
}

// ─── Admin: Usage ────────────────────────────────────────────────────────────

export interface UsageStats {
  totalRequests: number;
  totalTokens: number;
  promptTokens: number;
  completionTokens: number;
  period: string;
  breakdown?: UsageBreakdown[];
}

export interface UsageBreakdown {
  model: string;
  requests: number;
  tokens: number;
  cost?: number;
}

export interface UsageLimits {
  requestsPerMinute: number;
  requestsPerDay: number;
  tokensPerMinute: number;
  tokensPerDay: number;
  currentUsage: {
    requestsThisMinute: number;
    requestsToday: number;
    tokensThisMinute: number;
    tokensToday: number;
  };
}

export interface UsageGetParams {
  startDate?: string;
  endDate?: string;
  model?: string;
  granularity?: 'hourly' | 'daily' | 'weekly' | 'monthly';
}

// ─── Admin: Performance ──────────────────────────────────────────────────────

export interface PerformanceMetrics {
  avgLatencyMs: number;
  p50LatencyMs: number;
  p95LatencyMs: number;
  p99LatencyMs: number;
  successRate: number;
  errorRate: number;
  requestsPerSecond: number;
  period: string;
  byModel?: ModelPerformance[];
}

export interface ModelPerformance {
  model: string;
  avgLatencyMs: number;
  successRate: number;
  requestCount: number;
}

export interface PerformanceGetParams {
  startDate?: string;
  endDate?: string;
  model?: string;
}

// ─── Admin: Conversations ────────────────────────────────────────────────────

export interface Conversation {
  id: string;
  title?: string;
  model?: string;
  createdAt: string;
  updatedAt: string;
  messageCount?: number;
  metadata?: Record<string, unknown>;
}

export interface ConversationMessage {
  id: string;
  role: ChatRole;
  content: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface ConversationCreateParams {
  title?: string;
  model?: string;
  metadata?: Record<string, unknown>;
}

export interface ConversationUpdateParams {
  title?: string;
  metadata?: Record<string, unknown>;
}

export interface ConversationListParams {
  limit?: number;
  offset?: number;
}

export interface ConversationListResponse {
  conversations: Conversation[];
  total: number;
}

// ─── Admin: Iris ─────────────────────────────────────────────────────────────

export interface IrisExtractionParams {
  document: string;
  schema: string | Record<string, unknown>;
  options?: {
    language?: string;
    format?: string;
  };
}

export interface IrisExtractionResult {
  id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  result?: Record<string, unknown>;
  error?: string;
  createdAt: string;
  completedAt?: string;
}

export interface IrisJob {
  id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  schemaId?: string;
  createdAt: string;
  completedAt?: string;
  documentCount?: number;
}

export interface IrisJobsListParams {
  limit?: number;
}

export interface IrisSchema {
  id: string;
  name: string;
  schema: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

// ─── Admin: Plugins ──────────────────────────────────────────────────────────

export interface Plugin {
  id: string;
  name: string;
  description?: string;
  version: string;
  enabled: boolean;
  config?: Record<string, unknown>;
}

export interface PluginListResponse {
  plugins: Plugin[];
}

// ─── Admin: Optimizations ────────────────────────────────────────────────────

export interface OptimizationSettings {
  caching: boolean;
  cacheTtlSeconds?: number;
  rateLimiting: boolean;
  loadBalancing: boolean;
  retryPolicy?: {
    maxRetries: number;
    backoffMultiplier: number;
  };
}

// ─── Admin: Models Config ────────────────────────────────────────────────────

export interface ModelsConfig {
  models: ModelConfig[];
}

export interface ModelConfig {
  id: string;
  name: string;
  provider: string;
  enabled: boolean;
  maxTokens?: number;
  costPerInputToken?: number;
  costPerOutputToken?: number;
}

// ─── Admin: PDF ──────────────────────────────────────────────────────────────

export interface PdfGenerateParams {
  content: string;
  template?: string;
  options?: {
    format?: 'A4' | 'Letter';
    orientation?: 'portrait' | 'landscape';
    margins?: {
      top?: number;
      right?: number;
      bottom?: number;
      left?: number;
    };
  };
}

export interface PdfGenerateResponse {
  url?: string;
  data?: string; // base64
  contentType: string;
}

// ─── Admin: Web Search ───────────────────────────────────────────────────────

export interface WebSearchParams {
  query: string;
  limit?: number;
  offset?: number;
  language?: string;
  region?: string;
}

export interface WebSearchResult {
  title: string;
  url: string;
  snippet: string;
  publishedDate?: string;
}

export interface WebSearchResponse {
  results: WebSearchResult[];
  total: number;
  query: string;
}

// ─── Admin: Pools ────────────────────────────────────────────────────────────

export interface Pool {
  id: string;
  name: string;
  description?: string;
  backends?: PoolBackend[];
  createdAt: string;
  updatedAt: string;
}

export interface PoolBackend {
  id: string;
  backendId: string;
  priority?: number;
  weight?: number;
}

export interface PoolCreateParams {
  name: string;
  description?: string;
}

export interface PoolUpdateParams {
  name?: string;
  description?: string;
}

export interface PoolListResponse {
  pools: Pool[];
}

export interface PoolAddBackendParams {
  backendId: string;
  priority?: number;
  weight?: number;
}

// ─── Admin: Backends ─────────────────────────────────────────────────────────

export interface Backend {
  id: string;
  name: string;
  url: string;
  provider?: string;
  status?: string;
  models?: BackendModel[];
  createdAt: string;
  updatedAt: string;
}

export interface BackendModel {
  id: string;
  name: string;
  displayName?: string;
}

export interface BackendCreateParams {
  name: string;
  url: string;
  provider?: string;
}

export interface BackendUpdateParams {
  name?: string;
  url?: string;
  provider?: string;
}

export interface BackendListResponse {
  backends: Backend[];
}

export interface BackendDiscoverResponse {
  models: BackendModel[];
}

export interface BackendModelUpdateParams {
  displayName: string;
}

// ─── Admin: Users ────────────────────────────────────────────────────────────

export interface User {
  id: string;
  email: string;
  name?: string;
  role?: string;
  status?: string;
  createdAt: string;
  updatedAt: string;
}

export interface UserUpdateParams {
  name?: string;
  role?: string;
  status?: string;
}

export interface UserListResponse {
  users: User[];
}

export interface PendingCountResponse {
  count: number;
}

export interface UserApproveResponse {
  id: string;
  status: string;
}

export interface UserRejectResponse {
  id: string;
  status: string;
}

export interface UserResetPasswordResponse {
  id: string;
  temporaryPassword?: string;
}

// ─── Admin: Usage Limits ─────────────────────────────────────────────────────

export interface UsageLimit {
  id: string;
  entityType: 'user' | 'team';
  entityId: string;
  requestsPerMinute?: number;
  requestsPerDay?: number;
  tokensPerMinute?: number;
  tokensPerDay?: number;
}

export interface UsageLimitSetParams {
  requestsPerMinute?: number;
  requestsPerDay?: number;
  tokensPerMinute?: number;
  tokensPerDay?: number;
}

export interface UsageLimitListResponse {
  limits: UsageLimit[];
}

// ─── Admin: Admin API Keys ───────────────────────────────────────────────────

export interface AdminApiKey {
  id: string;
  name: string;
  key: string;
  createdAt: string;
  lastUsedAt?: string | null;
  expiresAt?: string | null;
  scopes?: string[];
}

export interface AdminApiKeyCreateParams {
  name: string;
  scopes?: string[];
  expiresAt?: string;
}

export interface AdminApiKeyUpdateParams {
  name?: string;
  scopes?: string[];
  expiresAt?: string;
}

export interface AdminApiKeyListResponse {
  keys: AdminApiKey[];
}

export interface AdminApiKeyRegenerateResponse {
  id: string;
  key: string;
}

// ─── Admin: Audit Log ────────────────────────────────────────────────────────

export interface AuditLogEntry {
  id: string;
  action: string;
  actor?: string;
  resource?: string;
  resourceId?: string;
  details?: Record<string, unknown>;
  timestamp: string;
}

export interface AuditLogListParams {
  limit?: number;
}

export interface AuditLogListResponse {
  entries: AuditLogEntry[];
}

// ─── Auth ────────────────────────────────────────────────────────────────────

export interface AuthLoginParams {
  email: string;
  password: string;
}

export interface AuthLoginResponse {
  token: string;
  user: AuthUser;
}

export interface AuthSignupParams {
  email: string;
  password: string;
  name?: string;
}

export interface AuthSignupResponse {
  token: string;
  user: AuthUser;
}

export interface AuthUser {
  id: string;
  email: string;
  name?: string;
  role?: string;
  createdAt: string;
}

export interface AuthUpdateProfileParams {
  name?: string;
  email?: string;
}

export interface AuthChangePasswordParams {
  currentPassword: string;
  newPassword: string;
}

export interface AuthChangePasswordResponse {
  success: boolean;
}

// ─── Audio ───────────────────────────────────────────────────────────────────

export interface AudioTranscriptionParams {
  file: Blob | File;
  /** Model identifier. If omitted, the pool's default model is used. */
  model?: string;
  language?: string;
  prompt?: string;
  response_format?: string;
  temperature?: number;
}

export interface AudioTranscription {
  text: string;
}

// ─── Delete Response ─────────────────────────────────────────────────────────

export interface DeleteResponse {
  id: string;
  deleted: boolean;
}
