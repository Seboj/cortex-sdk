// Main entry point for @cortex/sdk

export { CortexClient } from './client.js';

// Types
export type {
  CortexClientOptions,
  RequestOptions,
  // Chat
  ChatRole,
  ChatMessage,
  ToolCall,
  FunctionCall,
  ToolDefinition,
  FunctionDefinition,
  ResponseFormat,
  ChatCompletionCreateParams,
  ChatCompletionCreateParamsNonStreaming,
  ChatCompletionCreateParamsStreaming,
  ChatCompletion,
  ChatCompletionChoice,
  ChatCompletionChunk,
  ChatCompletionChunkChoice,
  ChatCompletionChunkDelta,
  // Completions
  CompletionCreateParams,
  Completion,
  CompletionChoice,
  CompletionUsage,
  // Embeddings
  EmbeddingCreateParams,
  EmbeddingResponse,
  EmbeddingData,
  // Models
  Model,
  ModelList,
  ModelPermission,
  ModelsConfig,
  ModelConfig,
  // API Keys
  ApiKey,
  ApiKeyCreateParams,
  ApiKeyListResponse,
  // Teams
  Team,
  TeamMember,
  TeamCreateParams,
  TeamListResponse,
  TeamMemberAddParams,
  TeamMemberUpdateParams,
  // Usage
  UsageStats,
  UsageBreakdown,
  UsageLimits,
  UsageGetParams,
  // Performance
  PerformanceMetrics,
  ModelPerformance,
  PerformanceGetParams,
  // Conversations
  Conversation,
  ConversationMessage,
  ConversationCreateParams,
  ConversationUpdateParams,
  ConversationListParams,
  ConversationListResponse,
  // Iris
  IrisExtractionParams,
  IrisExtractionResult,
  IrisJob,
  IrisJobsListParams,
  IrisSchema,
  // Plugins
  Plugin,
  PluginListResponse,
  // Optimizations
  OptimizationSettings,
  // PDF
  PdfGenerateParams,
  PdfGenerateResponse,
  // Web Search
  WebSearchParams,
  WebSearchResult,
  WebSearchResponse,
  // Pools
  Pool,
  PoolBackend,
  PoolCreateParams,
  PoolUpdateParams,
  PoolListResponse,
  PoolAddBackendParams,
  // Backends
  Backend,
  BackendModel,
  BackendCreateParams,
  BackendUpdateParams,
  BackendListResponse,
  BackendDiscoverResponse,
  BackendModelUpdateParams,
  // Users
  User,
  UserUpdateParams,
  UserListResponse,
  PendingCountResponse,
  UserApproveResponse,
  UserRejectResponse,
  UserResetPasswordResponse,
  // Usage Limits
  UsageLimit,
  UsageLimitSetParams,
  UsageLimitListResponse,
  // Admin API Keys
  AdminApiKey,
  AdminApiKeyCreateParams,
  AdminApiKeyUpdateParams,
  AdminApiKeyListResponse,
  AdminApiKeyRegenerateResponse,
  // Audit Log
  AuditLogEntry,
  AuditLogListParams,
  AuditLogListResponse,
  // Auth
  AuthLoginParams,
  AuthLoginResponse,
  AuthSignupParams,
  AuthSignupResponse,
  AuthUser,
  AuthUpdateProfileParams,
  AuthChangePasswordParams,
  AuthChangePasswordResponse,
  // Audio
  AudioTranscriptionParams,
  AudioTranscription,
  // Common
  DeleteResponse,
} from './types.js';

// Errors
export {
  CortexError,
  AuthenticationError,
  PermissionDeniedError,
  NotFoundError,
  RateLimitError,
  ValidationError,
  TimeoutError,
  ConnectionError,
  ServerError,
} from './errors.js';

// Streaming
export { SSEStream } from './streaming.js';

// Constants
export { DEFAULTS, VERSION } from './constants.js';
