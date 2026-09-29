enum ChatRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  Map<String, String> toApi() => {'role': role.name, 'content': content};
}
