import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/configs/api_endpoints.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/modules/chat/models/chat_message.dart';

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
      print(response);
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
