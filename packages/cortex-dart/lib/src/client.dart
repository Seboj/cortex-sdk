/// The main CortexClient class that provides access to all API resources.
library;

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'http_client.dart';
import 'resources/admin_keys.dart';
import 'resources/audio.dart';
import 'resources/audit_log.dart';
import 'resources/auth.dart';
import 'resources/backends.dart';
import 'resources/chat.dart';
import 'resources/completions.dart';
import 'resources/conversations.dart';
import 'resources/embeddings.dart';
import 'resources/iris.dart';
import 'resources/keys.dart';
import 'resources/models.dart';
import 'resources/pdf.dart';
import 'resources/performance.dart';
import 'resources/plugins.dart';
import 'resources/pools.dart';
import 'resources/teams.dart';
import 'resources/usage.dart';
import 'resources/usage_limits.dart';
import 'resources/users.dart';
import 'resources/web_search.dart';
import 'types.dart';

/// The main entry point for the Cortex SDK.
///
/// Provides access to all Cortex API resources including LLM Gateway
/// endpoints (chat, completions, embeddings, models) and Admin/Platform
/// endpoints (keys, teams, usage, conversations, etc.).
///
/// ```dart
/// final cortex = CortexClient(apiKey: 'sk-cortex-...');
///
/// // Chat completion
/// final response = await cortex.chat.completions.create(
///   model: 'default',
///   messages: [ChatMessage.user('Hello')],
/// );
///
/// // Streaming
/// await for (final chunk in cortex.chat.completions.createStream(
///   model: 'default',
///   messages: [ChatMessage.user('Hello')],
/// )) {
///   print(chunk.choices.first.delta?.content ?? '');
/// }
///
/// // Admin operations
/// final keys = await cortex.keys.list();
/// final team = await cortex.teams.create(name: 'Engineering');
///
/// // Clean up
/// cortex.close();
/// ```
class CortexClient {
  final CortexConfig _config;
  late final CortexHttpClient _httpClient;

  /// Chat completions resource.
  late final ChatResource chat;

  /// Text completions resource.
  late final CompletionsResource completions;

  /// Embeddings resource.
  late final EmbeddingsResource embeddings;

  /// Models resource.
  late final ModelsResource models;

  /// API keys management resource.
  late final KeysResource keys;

  /// Teams management resource.
  late final TeamsResource teams;

  /// Usage statistics resource.
  late final UsageResource usage;

  /// Performance metrics resource.
  late final PerformanceResource performance;

  /// Conversations resource.
  late final ConversationsResource conversations;

  /// Iris data extraction resource.
  late final IrisResource iris;

  /// Plugins resource.
  late final PluginsResource plugins;

  /// PDF generation resource.
  late final PdfResource pdf;

  /// Web search resource.
  late final WebSearchResource webSearch;

  /// Pools management resource.
  late final PoolsResource pools;

  /// Backends management resource.
  late final BackendsResource backends;

  /// Users management resource.
  late final UsersResource users;

  /// Usage limits management resource.
  late final UsageLimitsResource usageLimits;

  /// Admin API keys management resource.
  late final AdminKeysResource adminKeys;

  /// Audit log resource.
  late final AuditLogResource auditLog;

  /// Auth resource.
  late final AuthResource auth;

  /// Audio resource.
  late final AudioResource audio;

  /// Creates a [CortexClient] with the given configuration.
  ///
  /// [apiKey] is required for authentication.
  /// [gatewayBaseUrl] defaults to `https://cortexapi.nfinitmonkeys.com/v1`.
  /// [adminBaseUrl] defaults to `https://admin.nfinitmonkeys.com`.
  /// [httpClient] allows injecting a custom HTTP client for testing.
  CortexClient({
    required String apiKey,
    String gatewayBaseUrl = 'https://cortexapi.nfinitmonkeys.com/v1',
    String adminBaseUrl = 'https://admin.nfinitmonkeys.com',
    Duration timeout = const Duration(seconds: 30),
    Duration streamingTimeout = const Duration(seconds: 300),
    int maxRetries = 3,
    Duration retryBaseDelay = const Duration(milliseconds: 500),
    Duration retryMaxDelay = const Duration(seconds: 30),
    http.Client? httpClient,
    String? defaultPool,
  }) : _config = CortexConfig(
          apiKey: apiKey,
          gatewayBaseUrl: _normalizeUrl(gatewayBaseUrl),
          adminBaseUrl: _normalizeUrl(adminBaseUrl),
          timeout: timeout,
          streamingTimeout: streamingTimeout,
          maxRetries: maxRetries,
          retryBaseDelay: retryBaseDelay,
          retryMaxDelay: retryMaxDelay,
          defaultPool: defaultPool,
        ) {
    _validateApiKey(apiKey);
    _httpClient = CortexHttpClient(
      config: _config,
      httpClient: httpClient,
    );
    _initResources();
  }

  /// Creates a [CortexClient] from a [CortexConfig] object.
  CortexClient.fromConfig(
    CortexConfig config, {
    http.Client? httpClient,
  }) : _config = config {
    _validateApiKey(config.apiKey);
    _httpClient = CortexHttpClient(
      config: config,
      httpClient: httpClient,
    );
    _initResources();
  }

  void _initResources() {
    final gatewayUrl = _config.gatewayBaseUrl;
    final adminUrl = _config.adminBaseUrl;
    final defaultPool = _config.defaultPool;

    chat = ChatResource(
        client: _httpClient, baseUrl: gatewayUrl, defaultPool: defaultPool);
    completions = CompletionsResource(
        client: _httpClient, baseUrl: gatewayUrl, defaultPool: defaultPool);
    embeddings = EmbeddingsResource(
        client: _httpClient, baseUrl: gatewayUrl, defaultPool: defaultPool);
    models = ModelsResource(
      client: _httpClient,
      gatewayBaseUrl: gatewayUrl,
      adminBaseUrl: adminUrl,
    );
    keys = KeysResource(client: _httpClient, baseUrl: adminUrl);
    teams = TeamsResource(client: _httpClient, baseUrl: adminUrl);
    usage = UsageResource(client: _httpClient, baseUrl: adminUrl);
    performance = PerformanceResource(client: _httpClient, baseUrl: adminUrl);
    conversations =
        ConversationsResource(client: _httpClient, baseUrl: adminUrl);
    iris = IrisResource(client: _httpClient, baseUrl: adminUrl);
    plugins = PluginsResource(client: _httpClient, baseUrl: adminUrl);
    pdf = PdfResource(client: _httpClient, baseUrl: adminUrl);
    webSearch = WebSearchResource(client: _httpClient, baseUrl: adminUrl);
    pools = PoolsResource(client: _httpClient, baseUrl: adminUrl);
    backends = BackendsResource(client: _httpClient, baseUrl: adminUrl);
    users = UsersResource(client: _httpClient, baseUrl: adminUrl);
    usageLimits = UsageLimitsResource(client: _httpClient, baseUrl: adminUrl);
    adminKeys = AdminKeysResource(client: _httpClient, baseUrl: adminUrl);
    auditLog = AuditLogResource(client: _httpClient, baseUrl: adminUrl);
    auth = AuthResource(client: _httpClient, baseUrl: adminUrl);
    audio = AudioResource(
        client: _httpClient, baseUrl: gatewayUrl, defaultPool: defaultPool);
  }

  /// The current SDK configuration (with masked API key).
  CortexConfig get config => _config;

  /// Closes the underlying HTTP client.
  ///
  /// After calling this method, no further API calls can be made
  /// with this client instance.
  void close() {
    _httpClient.close();
  }

  static String _normalizeUrl(String url) {
    // Remove trailing slash.
    if (url.endsWith('/')) return url.substring(0, url.length - 1);
    return url;
  }

  static void _validateApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw const CortexValidationException(
        message: 'API key must not be empty.',
        parameter: 'apiKey',
      );
    }
    // Check for newlines (header injection prevention).
    if (apiKey.contains('\n') || apiKey.contains('\r')) {
      throw const CortexValidationException(
        message:
            'API key contains invalid characters (potential header injection).',
        parameter: 'apiKey',
      );
    }
  }

  @override
  String toString() => 'CortexClient(${_config.maskedApiKey})';
}
