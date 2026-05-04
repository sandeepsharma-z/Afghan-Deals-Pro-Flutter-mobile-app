import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../data/models/chat_thread_model.dart';
import '../providers/chat_provider.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreListings;
  final VoidCallback? onBackToHome;
  const ChatsScreen({super.key, this.onExploreListings, this.onBackToHome});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  int _filterIndex = 0;
  static const _filters = ['All', 'Buying', 'Selling'];
  static const _blue = Color(0xFF2258A8);
  static const _grey = Color(0xFF7C7D88);

  List<ChatThreadModel> _applyFilter(List<ChatThreadModel> items) {
    if (_filterIndex == 1) return items.where((e) => e.amIBuyer).toList();
    if (_filterIndex == 2) return items.where((e) => !e.amIBuyer).toList();
    return items;
  }

  void _goBack() {
    if (widget.onBackToHome != null) {
      debugPrint('Chats embedded back tapped -> Home tab');
      widget.onBackToHome!();
      return;
    }
    debugPrint('Chats back tapped -> Home');
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteChat(ChatThreadModel thread) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Chat',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Delete conversation about "${thread.listingTitle}"? This cannot be undone.',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.montserrat(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(chatActionsProvider).deleteChat(thread.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 48,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goBack,
          child: const SizedBox(
            width: 48,
            height: kToolbarHeight,
            child: Center(
              child: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.black87),
            ),
          ),
        ),
        title: Text('Chats',
            style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        centerTitle: true,
        actions: const [SizedBox(width: 48)],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final selected = _filterIndex == i;
                return Padding(
                  padding:
                      EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: selected ? Colors.black : _grey, width: 1),
                      ),
                      child: Text(_filters[i],
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.black : _grey)),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: chatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.red)),
                ),
              ),
              data: (items) {
                final filtered = _applyFilter(items);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Your chat is empty!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                          const SizedBox(height: 12),
                          Text(
                              'Open any listing and tap Chat to start a conversation.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: Colors.black45,
                                  height: 1.5)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 180,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.onExploreListings != null) {
                                  widget.onExploreListings!();
                                  return;
                                }
                                context.go(RouteNames.home);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Explore Listings',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEDEDED)),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 24),
                      ),
                      confirmDismiss: (_) async {
                        await _deleteChat(item);
                        return false; // we handle deletion ourselves
                      },
                      child: _ChatTile(
                        item: item,
                        onTap: () {
                          debugPrint('Chat tile tapped: ${item.id}');
                          context.push('/chat/${item.id}');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatThreadModel item;
  final VoidCallback onTap;
  const _ChatTile({required this.item, required this.onTap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = item.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Listing thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.listingImageUrl != null &&
                      item.listingImageUrl!.isNotEmpty
                  ? Image.network(item.listingImageUrl!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumb())
                  : _thumb(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: Colors.black87)),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatTime(item.lastMessageAt),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: hasUnread
                                  ? const Color(0xFF2258A8)
                                  : Colors.black45,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2258A8))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.lastMessage.isEmpty
                              ? 'Tap to start conversation'
                              : item.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color:
                                  hasUnread ? Colors.black87 : Colors.black54,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400),
                        ),
                      ),
                      // Unread badge
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2258A8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.unreadCount > 99
                                ? '99+'
                                : '${item.unreadCount}',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
      width: 54,
      height: 54,
      color: const Color(0xFFEFF2F8),
      child:
          const Icon(Icons.image_outlined, color: Color(0xFF98A2B3), size: 22));
}
