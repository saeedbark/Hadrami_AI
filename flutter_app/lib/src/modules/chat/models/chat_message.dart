enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final String? note;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.note,
  });

  Map<String, String> toApiMap() => {
        'role': role == ChatRole.user ? 'user' : 'assistant',
        'content': content,
      };
}
