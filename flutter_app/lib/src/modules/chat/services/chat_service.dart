import 'dart:async';

import 'package:hadrami_nlp/src/core/network/api_config.dart';
import 'package:hadrami_nlp/src/core/network/api_endpoints.dart';
import 'package:hadrami_nlp/src/core/network/api_service.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/modules/chat/models/chat_message.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/word_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_service.g.dart';

/// Thin chat-facing wrapper over the shared [ApiService] — keeps the `/chat`
/// call and its timeout/connection-error fallback replies scoped to this
/// module, mirroring [DictionaryService].
@riverpod
ChatService chatService(ChatServiceRef ref) =>
    ChatService(ref.read(apiServiceProvider));

class ChatService {
  ChatService(this._api);

  final ApiService _api;

  Future<ChatResult> sendMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    try {
      final response = await _api.postJson(
        ApiEndpoints.chat,
        {
          'message': message,
          'history': history.map((m) => m.toApiMap()).toList(),
        },
        timeout: ApiConfig.longTimeout,
      );
      return ChatResult.fromJson(response);
    } on TimeoutException {
      return const ChatResult(
        reply: AppStrings.apiServiceChatTimeoutReply,
      );
    } catch (_) {
      return const ChatResult(
        reply:
            '${AppStrings.apiServiceChatConnectionErrorPrefix}${ApiConfig.baseUrl}',
      );
    }
  }
}
