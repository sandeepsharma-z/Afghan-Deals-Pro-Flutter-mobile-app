import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_thread_model.dart';
import '../providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final ChatThreadModel? initialThread;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    this.initialThread,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessageModel> _optimisticMessages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markRead() {
    final thread = widget.initialThread ??
        ref.read(chatThreadByIdProvider(widget.chatId)).valueOrNull;
    if (thread == null) return;
    ref.read(chatActionsProvider).markAsRead(
          chatId: widget.chatId,
          amIBuyer: thread.amIBuyer,
        );
  }

  bool _alreadyInServer(ChatMessageModel opt, List<ChatMessageModel> server) {
    for (final m in server) {
      if (m.senderId != opt.senderId) continue;
      if (m.text.trim() != opt.text.trim()) continue;
      if (m.createdAt.difference(opt.createdAt).inSeconds.abs() <= 15) {
        return true;
      }
    }
    return false;
  }

  void _scrollToBottom({double extra = 120}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + extra,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send text ────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty || _sending) return;
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (me.isEmpty) return;

    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessageModel(
      id: tempId,
      chatId: widget.chatId,
      senderId: me,
      text: msg,
      createdAt: DateTime.now().toUtc(),
    );

    setState(() {
      _sending = true;
      _optimisticMessages.add(optimistic);
    });
    _textCtrl.clear();
    _scrollToBottom();

    try {
      await ref
          .read(chatActionsProvider)
          .sendMessage(chatId: widget.chatId, text: msg);
      if (mounted) {
        setState(() => _optimisticMessages.removeWhere((m) => m.id == tempId));
      }
      ref.invalidate(chatMessagesProvider(widget.chatId));
      ref.invalidate(chatThreadsProvider);
      _scrollToBottom(extra: 80);
      _markRead();
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticMessages.removeWhere((m) => m.id == tempId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Send image ───────────────────────────────────────────────────────────────

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1080);
    if (picked == null || !mounted) return;

    final me = Supabase.instance.client.auth.currentUser?.id ?? '';
    final tempId = 'local-img-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessageModel(
      id: tempId, chatId: widget.chatId,
      senderId: me, text: '',
      imageUrl: picked.path, // local path as placeholder
      createdAt: DateTime.now().toUtc(),
    );

    setState(() {
      _sending = true;
      _optimisticMessages.add(optimistic);
    });
    _scrollToBottom();

    try {
      await ref
          .read(chatActionsProvider)
          .sendImage(chatId: widget.chatId, image: picked);
      if (mounted) {
        setState(() => _optimisticMessages.removeWhere((m) => m.id == tempId));
      }
      ref.invalidate(chatMessagesProvider(widget.chatId));
      ref.invalidate(chatThreadsProvider);
      _scrollToBottom(extra: 80);
      _markRead();
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticMessages.removeWhere((m) => m.id == tempId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final me = Supabase.instance.client.auth.currentUser?.id ?? '';
    final metaAsync = ref.watch(chatThreadByIdProvider(widget.chatId));
    final thread = widget.initialThread ?? metaAsync.value;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    final title = thread?.peerName ?? 'Chat';
    final subtitle = thread?.listingTitle ?? 'Listing';
    final recipientLastReadAt = thread == null
        ? null
        : (thread.amIBuyer ? thread.sellerLastReadAt : thread.buyerLastReadAt);

    // Mark read whenever new messages arrive
    ref.listen(chatMessagesProvider(widget.chatId), (_, __) => _markRead());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.red)),
                ),
              ),
              data: (messages) {
                final pendingOnly = _optimisticMessages
                    .where((m) => !_alreadyInServer(m, messages))
                    .toList();
                final all = [...messages, ...pendingOnly]
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (all.isEmpty) {
                  return Center(
                    child: Text('Say hi to start chat',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black54)),
                  );
                }

                ChatMessageModel? myLastMsg;
                for (var i = all.length - 1; i >= 0; i--) {
                  if (all[i].senderId == me) {
                    myLastMsg = all[i];
                    break;
                  }
                }

                final isMyLastMessageSeen = myLastMsg != null &&
                    recipientLastReadAt != null &&
                    !recipientLastReadAt
                        .toUtc()
                        .isBefore(myLastMsg.createdAt.toUtc());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final m = all[i];
                    final mine = m.senderId == me;
                    final isLast = i == all.length - 1;
                    return _MessageBubble(
                      msg: m,
                      mine: mine,
                      showSeen: isLast &&
                          mine &&
                          myLastMsg != null &&
                          m.id == myLastMsg.id &&
                          isMyLastMessageSeen,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final isBanned = ref.watch(isChatBannedProvider).valueOrNull ?? false;

    if (isBanned) {
      return SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEEBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFC92325).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, size: 18, color: Color(0xFFC92325)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your account has been restricted from sending messages.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFFC92325)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            // Image picker button
            IconButton(
              onPressed: _sending ? null : _pickAndSendImage,
              icon: const Icon(Icons.image_outlined,
                  color: Color(0xFF2258A8), size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type message...',
                  hintStyle:
                      GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2258A8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              width: 42,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2258A8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.zero,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool mine;
  final bool showSeen;

  const _MessageBubble(
      {required this.msg, required this.mine, this.showSeen = false});

  @override
  Widget build(BuildContext context) {
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final hasText = msg.text.isNotEmpty;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74),
            decoration: BoxDecoration(
              color: mine ? const Color(0xFF2258A8) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: mine ? null : Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage) _buildImage(context),
                  if (hasText || !hasImage)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: Text(
                        hasText ? msg.text : '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.35,
                          color: mine ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Seen + time row
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(msg.createdAt),
                  style:
                      GoogleFonts.poppins(fontSize: 10, color: Colors.black38),
                ),
                if (showSeen && mine) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all,
                      size: 13, color: Color(0xFF2258A8)),
                  const SizedBox(width: 2),
                  Text('Seen',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: const Color(0xFF2258A8))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final url = msg.imageUrl!;
    final isLocal = url.startsWith('/') || url.startsWith('file://');
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.74,
        maxHeight: 220,
      ),
      child: isLocal
          ? Image.asset(url,
              fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgError())
          : Image.network(url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) => _imgError()),
    );
  }

  Widget _imgError() => Container(
        height: 120,
        color: const Color(0xFFEFF2F8),
        child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Color(0xFF98A2B3))),
      );

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
