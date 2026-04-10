import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../chat/data/models/chat_message_model.dart';
import '../../../chat/data/models/chat_thread_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

// ── Admin-only provider: fetches ALL chats (requires is_admin = true in DB) ───

final adminAllChatsProvider = StreamProvider.autoDispose<List<ChatThreadModel>>((ref) {
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id ?? '';

  return client
      .from('chats')
      .stream(primaryKey: const ['id'])
      .order('last_message_at', ascending: false)
      .asyncMap((rows) async {
    if (rows.isEmpty) return const <ChatThreadModel>[];

    final listingIds = rows
        .map((r) => r['listing_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final buyerIds = rows
        .map((r) => r['buyer_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final sellerIds = rows
        .map((r) => r['seller_id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final allUserIds = {...buyerIds, ...sellerIds}.toList();

    // Fetch listings
    final listingMap = <String, Map<String, dynamic>>{};
    if (listingIds.isNotEmpty) {
      final res = await client
          .from('listings')
          .select('id,title,images')
          .inFilter('id', listingIds);
      for (final item in (res as List<dynamic>)) {
        final m = item as Map<String, dynamic>;
        listingMap[m['id']?.toString() ?? ''] = m;
      }
    }

    // Fetch user profiles
    final profileMap = <String, Map<String, dynamic>>{};
    if (allUserIds.isNotEmpty) {
      final res = await client
          .from('profiles')
          .select('id,name')
          .inFilter('id', allUserIds);
      for (final item in (res as List<dynamic>)) {
        final m = item as Map<String, dynamic>;
        profileMap[m['id']?.toString() ?? ''] = m;
      }
    }

    return rows.map((r) {
      final listingId = r['listing_id']?.toString() ?? '';
      final buyerId  = r['buyer_id']?.toString()  ?? '';
      final sellerId = r['seller_id']?.toString()  ?? '';
      final amIBuyer = buyerId == me;
      final peerId   = amIBuyer ? sellerId : buyerId;

      final listing = listingMap[listingId] ?? const <String, dynamic>{};
      final profile = profileMap[peerId]   ?? const <String, dynamic>{};
      final images  = (listing['images'] as List<dynamic>?) ?? const [];

      return ChatThreadModel(
        id:             r['id']?.toString() ?? '',
        listingId:      listingId,
        peerId:         peerId,
        peerName:       profile['name']?.toString() ?? 'Unknown',
        peerAvatarUrl:  null,
        listingTitle:   listing['title']?.toString() ?? 'Listing',
        listingImageUrl: images.isNotEmpty ? images.first.toString() : null,
        lastMessage:    r['last_message']?.toString() ?? '',
        lastMessageAt:  DateTime.tryParse(r['last_message_at']?.toString() ?? ''),
        amIBuyer:       amIBuyer,
      );
    }).toList();
  });
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class AdminChatsScreen extends ConsumerWidget {
  const AdminChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(adminAllChatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('All Chats',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.black26),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'You need admin privileges to view all chats.\nAsk the super-admin to set is_admin = true for your account.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Text('No chats yet.',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black45)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEDEDED)),
            itemBuilder: (_, i) => _AdminChatTile(thread: chats[i]),
          );
        },
      ),
    );
  }
}

// ── Chat tile ──────────────────────────────────────────────────────────────────

class _AdminChatTile extends StatelessWidget {
  final ChatThreadModel thread;
  const _AdminChatTile({required this.thread});

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: thread.listingImageUrl != null
            ? Image.network(thread.listingImageUrl!,
                width: 52, height: 52, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumb())
            : _thumb(),
      ),
      title: Text(thread.listingTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            thread.lastMessage.isEmpty
                ? 'No messages yet'
                : thread.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      trailing: Text(_fmt(thread.lastMessageAt),
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _AdminMessageView(thread: thread),
      )),
    );
  }

  Widget _thumb() => Container(
        width: 52, height: 52,
        color: const Color(0xFFEFF2F8),
        child: const Icon(Icons.image_outlined,
            color: Color(0xFF98A2B3), size: 22),
      );
}

// ── Admin message view ─────────────────────────────────────────────────────────

class _AdminMessageView extends ConsumerWidget {
  final ChatThreadModel thread;
  const _AdminMessageView({required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(thread.id));
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(thread.listingTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            Text('Buyer: ${thread.peerName}',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.black54)),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: GoogleFonts.poppins(color: Colors.red))),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Text('No messages yet.',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.black45)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: messages.length,
            itemBuilder: (_, i) => _MsgBubble(
              msg: messages[i],
              isMine: messages[i].senderId == me,
            ),
          );
        },
      ),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMine;
  const _MsgBubble({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF2258A8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isMine ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.35,
                    color: isMine ? Colors.white : Colors.black87)),
            const SizedBox(height: 3),
            Text(
              _time(msg.createdAt),
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}
