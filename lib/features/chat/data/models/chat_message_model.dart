class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id:        map['id']?.toString() ?? '',
      chatId:    map['chat_id']?.toString() ?? '',
      senderId:  map['sender_id']?.toString() ?? '',
      text:      map['text']?.toString() ?? '',
      imageUrl:  map['image_url']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
