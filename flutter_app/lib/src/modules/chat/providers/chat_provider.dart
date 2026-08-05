import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/modules/chat/models/chat_message.dart';
import 'package:hadrami_nlp/src/modules/chat/models/chat_state.dart';
import 'package:hadrami_nlp/src/modules/chat/services/chat_service.dart';

part 'chat_provider.g.dart';

@Riverpod(keepAlive: true)
class Chat extends _$Chat {
  @override
  ChatState build() => const ChatState();

  Future<void> sendMessage(String text) async {
    final userMessage = ChatMessage(
      role: ChatRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    final history = state.messages
        .where(
          (m) => m != userMessage,
        )
        .toList();

    final result = await ref
        .read(chatServiceProvider)
        .sendMessage(message: text, history: history);

    final assistantMessage = ChatMessage(
      role: ChatRole.assistant,
      content: result.reply,
      timestamp: DateTime.now(),
      note: _firstNote(result.context),
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isLoading: false,
    );
  }

  void clearHistory() {
    state = const ChatState();
  }

  String? _firstNote(List<WordEntry> context) {
    for (final entry in context) {
      if (entry.note != null && entry.note!.isNotEmpty) return entry.note;
    }
    return null;
  }
}
