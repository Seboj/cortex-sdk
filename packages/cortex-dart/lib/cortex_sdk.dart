/// Cortex SDK for Dart/Flutter.
///
/// A production-grade SDK for the Cortex LLM Gateway and Admin APIs.
///
/// ```dart
/// import 'package:nfinitmonkeys_cortex_sdk/cortex_sdk.dart';
///
/// final cortex = CortexClient(apiKey: 'sk-cortex-...');
///
/// final response = await cortex.chat.completions.create(
///   model: 'default',
///   messages: [ChatMessage.user('Hello')],
/// );
/// print(response.choices.first.message.content);
///
/// cortex.close();
/// ```
library cortex_sdk;

export 'src/client.dart';
export 'src/constants.dart';
export 'src/errors.dart';
export 'src/streaming.dart';
export 'src/types.dart';

// Resource exports for advanced usage.
export 'src/resources/admin_keys.dart';
export 'src/resources/audio.dart';
export 'src/resources/audit_log.dart';
export 'src/resources/auth.dart';
export 'src/resources/backends.dart';
export 'src/resources/chat.dart';
export 'src/resources/completions.dart';
export 'src/resources/conversations.dart';
export 'src/resources/embeddings.dart';
export 'src/resources/iris.dart';
export 'src/resources/keys.dart';
export 'src/resources/models.dart';
export 'src/resources/pdf.dart';
export 'src/resources/performance.dart';
export 'src/resources/plugins.dart';
export 'src/resources/pools.dart';
export 'src/resources/teams.dart';
export 'src/resources/usage.dart';
export 'src/resources/usage_limits.dart';
export 'src/resources/users.dart';
export 'src/resources/web_search.dart';
