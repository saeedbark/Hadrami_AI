import 'package:hadrami_nlp/src/modules/chat/models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}
