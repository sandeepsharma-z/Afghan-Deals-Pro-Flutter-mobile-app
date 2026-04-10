class ChatThreadModel {
  final String id;
  final String listingId;
  final String peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final String listingTitle;
  final String? listingImageUrl;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final bool amIBuyer;
  final int unreadCount;

  const ChatThreadModel({
    required this.id,
    required this.listingId,
    required this.peerId,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.listingTitle,
    required this.listingImageUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.amIBuyer,
    this.unreadCount = 0,
  });
}
