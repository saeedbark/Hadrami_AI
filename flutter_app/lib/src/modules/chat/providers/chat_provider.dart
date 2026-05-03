import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/modules/chat/models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api;

  ChatNotifier(this._api) : super(const ChatState());

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
        .where((m) => m != userMessage)
        .map((m) => m.toApiMap())
        .toList();

    final result = await _api.sendChatMessage(
      message: text,
      history: history,
    );

    final assistantMessage = ChatMessage(
      role: ChatRole.assistant,
      content: result.reply,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
      isLoading: false,
    );
  }

  void clearHistory() {
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(apiServiceProvider));
});
