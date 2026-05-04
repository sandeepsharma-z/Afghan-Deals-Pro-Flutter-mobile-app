import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_thread_model.dart';

final _chatClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

String _categoryText(dynamic categoryData, List<String> keys) {
  if (categoryData is! Map<String, dynamic>) return '';
  for (final key in keys) {
    final value = categoryData[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

// ── Admin check ───────────────────────────────────────────────────────────────

Future<bool> _isAdminUser(SupabaseClient client, String userId) async {
  try {
    final row = await client
        .from('profiles')
        .select('is_admin')
        .eq('id', userId)
        .maybeSingle();
    return row != null && (row['is_admin'] == true);
  } catch (_) {
    return false;
  }
}

// ── Build thread list ─────────────────────────────────────────────────────────

Future<List<ChatThreadModel>> _buildThreads(
  SupabaseClient client,
  String me,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty) return const [];

  final listingIds = rows
      .map((r) => r['listing_id']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  final peerIds = rows
      .map((r) {
        final buyer = r['buyer_id']?.toString() ?? '';
        final seller = r['seller_id']?.toString() ?? '';
        return buyer == me ? seller : buyer;
      })
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  final listingMap = <String, Map<String, dynamic>>{};
  if (listingIds.isNotEmpty) {
    final res = await client
        .from('listings')
        .select('id,title,images,seller_name')
        .inFilter('id', listingIds);
    for (final item in (res as List<dynamic>)) {
      final map = item as Map<String, dynamic>;
      listingMap[map['id']?.toString() ?? ''] = map;
    }
  }

  final profileMap = <String, Map<String, dynamic>>{};
  if (peerIds.isNotEmpty) {
    final res =
        await client.from('profiles').select('id,name').inFilter('id', peerIds);
    for (final item in (res as List<dynamic>)) {
      final map = item as Map<String, dynamic>;
      profileMap[map['id']?.toString() ?? ''] = map;
    }
  }

  // Fetch unread counts for all chats at once
  final chatIds = rows
      .map((r) => r['id']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  final unreadMap = <String, int>{};
  if (chatIds.isNotEmpty) {
    try {
      for (final row in rows) {
        final chatId = row['id']?.toString() ?? '';
        final buyerId = row['buyer_id']?.toString() ?? '';
        final amIBuyer = buyerId == me;

        // My last read timestamp
        final lastReadKey =
            amIBuyer ? 'buyer_last_read_at' : 'seller_last_read_at';
        final lastReadStr = row[lastReadKey]?.toString() ?? '';
        final lastRead = DateTime.tryParse(lastReadStr) ?? DateTime(2000);

        // Count messages after lastRead NOT sent by me
        final res = await client
            .from('chat_messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', me)
            .gt('created_at', lastRead.toUtc().toIso8601String());
        unreadMap[chatId] = (res as List).length;
      }
    } catch (_) {}
  }

  return rows.map((r) {
    final listingId = r['listing_id']?.toString() ?? '';
    final buyerId = r['buyer_id']?.toString() ?? '';
    final sellerId = r['seller_id']?.toString() ?? '';
    final amIBuyer = buyerId == me;
    final peerId = amIBuyer ? sellerId : buyerId;
    final chatId = r['id']?.toString() ?? '';

    final listing = listingMap[listingId] ?? const <String, dynamic>{};
    final profile = profileMap[peerId] ?? const <String, dynamic>{};
    final images = (listing['images'] as List<dynamic>?) ?? const [];

    return ChatThreadModel(
      id: chatId,
      listingId: listingId,
      peerId: peerId,
      peerName: (profile['name']?.toString().trim().isNotEmpty ?? false)
          ? profile['name'].toString().trim()
          : (listing['seller_name']?.toString() ?? 'User'),
      peerAvatarUrl: null,
      listingTitle: listing['title']?.toString() ?? 'Listing',
      listingImageUrl: images.isNotEmpty ? images.first.toString() : null,
      lastMessage: r['last_message']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(r['last_message_at']?.toString() ?? ''),
      buyerLastReadAt:
          DateTime.tryParse(r['buyer_last_read_at']?.toString() ?? ''),
      sellerLastReadAt:
          DateTime.tryParse(r['seller_last_read_at']?.toString() ?? ''),
      amIBuyer: amIBuyer,
      unreadCount: unreadMap[chatId] ?? 0,
    );
  }).toList();
}

// ── Stream helpers ────────────────────────────────────────────────────────────

Stream<List<ChatThreadModel>> _chatThreadStreamForRole(
  SupabaseClient client,
  String userId,
  bool isAdmin,
) {
  return client
      .from('chats')
      .stream(primaryKey: const ['id'])
      .order('last_message_at', ascending: false)
      .asyncMap((rows) {
        final filtered = isAdmin
            ? rows
            : rows
                .where((row) =>
                    row['buyer_id']?.toString() == userId ||
                    row['seller_id']?.toString() == userId)
                .toList();
        return _buildThreads(client, userId, filtered);
      });
}

// ── Providers ─────────────────────────────────────────────────────────────────

final chatThreadsProvider =
    StreamProvider.autoDispose<List<ChatThreadModel>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(const <ChatThreadModel>[]);
  final client = ref.read(_chatClientProvider);
  return Stream.fromFuture(_isAdminUser(client, user.id)).asyncExpand(
      (isAdmin) => _chatThreadStreamForRole(client, user.id, isAdmin));
});

final chatThreadByIdProvider = FutureProvider.autoDispose
    .family<ChatThreadModel?, String>((ref, chatId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final client = ref.read(_chatClientProvider);
  final row =
      await client.from('chats').select().eq('id', chatId).maybeSingle();
  if (row == null) return null;
  final items =
      await _buildThreads(client, user.id, [Map<String, dynamic>.from(row)]);
  return items.isEmpty ? null : items.first;
});

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessageModel>, String>((ref, chatId) {
  return ref
      .read(_chatClientProvider)
      .from('chat_messages')
      .stream(primaryKey: const ['id'])
      .eq('chat_id', chatId)
      .order('created_at', ascending: true)
      .map((rows) => rows
          .map((item) => ChatMessageModel.fromMap(item))
          .toList(growable: false));
});

// Total unread across all chats (for bottom nav badge)
final totalUnreadProvider = Provider.autoDispose<int>((ref) {
  final threads = ref.watch(chatThreadsProvider).valueOrNull ?? [];
  return threads.fold(0, (sum, t) => sum + t.unreadCount);
});

// Streams the current user's chat-ban status in real time
final isChatBannedProvider = StreamProvider.autoDispose<bool>((ref) {
  final me = Supabase.instance.client.auth.currentUser?.id;
  if (me == null) return Stream.value(false);
  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: const ['id'])
      .eq('id', me)
      .map((rows) => rows.isNotEmpty && rows.first['is_chat_banned'] == true);
});

final isChatBlockedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, chatId) async {
  final me = Supabase.instance.client.auth.currentUser?.id;
  if (me == null || chatId.isEmpty) return false;
  final client = ref.read(_chatClientProvider);

  final chat = await client
      .from('chats')
      .select('buyer_id,seller_id')
      .eq('id', chatId)
      .maybeSingle();
  if (chat == null) return false;

  final buyerId = chat['buyer_id']?.toString() ?? '';
  final sellerId = chat['seller_id']?.toString() ?? '';
  final peerId = buyerId == me ? sellerId : buyerId;
  if (peerId.isEmpty) return false;

  try {
    final outgoing = await client
        .from('blocked_users')
        .select('id')
        .eq('blocker_id', me)
        .eq('blocked_id', peerId)
        .maybeSingle();
    if (outgoing != null) return true;

    final incoming = await client
        .from('blocked_users')
        .select('id')
        .eq('blocker_id', peerId)
        .eq('blocked_id', me)
        .maybeSingle();
    return incoming != null;
  } catch (_) {
    return false;
  }
});

// ── Actions ───────────────────────────────────────────────────────────────────

class ChatActions {
  final SupabaseClient _client;
  ChatActions(this._client);

  String _friendlyDbError(Object e) {
    if (e is PostgrestException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('relation "public.chats"') ||
          msg.contains('relation "public.chat_messages"')) {
        return 'Chat tables are missing in Supabase. Run the chat SQL setup first.';
      }
      if (msg.contains('relation "public.blocked_users"') ||
          msg.contains('relation "public.user_blocks"')) {
        return 'Blocked users table is missing in Supabase. Run BLOCKED_USERS_SQL_SETUP.sql first.';
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  // ── Ban check ────────────────────────────────────────────────────────────────

  Future<void> _guardBan() async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Exception('Please sign in first.');
    try {
      final profile = await _client
          .from('profiles')
          .select('is_chat_banned')
          .eq('id', me)
          .maybeSingle();
      if (profile != null && profile['is_chat_banned'] == true) {
        throw Exception(
            'Your account has been restricted from sending messages by admin.');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('restricted')) rethrow;
    }
  }

  Future<bool> _isBlockedBetween(String userA, String userB) async {
    if (userA.isEmpty || userB.isEmpty) return false;
    try {
      final outgoing = await _client
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', userA)
          .eq('blocked_id', userB)
          .maybeSingle();
      if (outgoing != null) return true;

      final incoming = await _client
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', userB)
          .eq('blocked_id', userA)
          .maybeSingle();
      return incoming != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _guardChatBlock(String chatId, String me) async {
    try {
      final chat = await _client
          .from('chats')
          .select('buyer_id,seller_id')
          .eq('id', chatId)
          .maybeSingle();
      if (chat == null) return;
      final buyerId = chat['buyer_id']?.toString() ?? '';
      final sellerId = chat['seller_id']?.toString() ?? '';
      final peerId = buyerId == me ? sellerId : buyerId;
      if (await _isBlockedBetween(me, peerId)) {
        throw Exception('This user is blocked. Chat is disabled.');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('blocked')) rethrow;
    }
  }

  // ── Seller resolve ───────────────────────────────────────────────────────────

  Future<String> _resolveSellerIdForListing({
    required String listingId,
    required String incomingSellerId,
    required String currentUserId,
    String? sellerNameHint,
    String? sellerPhoneHint,
    String? sellerEmailHint,
  }) async {
    final direct = incomingSellerId.trim();
    if (direct.isNotEmpty) return direct;
    try {
      final listing = await _client
          .from('listings')
          .select()
          .eq('id', listingId)
          .maybeSingle();
      if (listing == null) return '';

      for (final key in const [
        'seller_id',
        'user_id',
        'owner_id',
        'created_by',
        'profile_id',
      ]) {
        final id = listing[key]?.toString().trim() ?? '';
        if (id.isNotEmpty && id != 'unknown' && id != currentUserId) {
          return id;
        }
      }

      final categoryData = listing['category_data'];
      if (categoryData is Map<String, dynamic>) {
        for (final key in const [
          'seller_id',
          'user_id',
          'owner_id',
          'created_by',
          'profile_id',
          'userId',
          'sellerId',
        ]) {
          final id = categoryData[key]?.toString().trim() ?? '';
          if (id.isNotEmpty && id != 'unknown' && id != currentUserId) {
            return id;
          }
        }
      }

      final sellerName = (sellerNameHint?.trim().isNotEmpty ?? false)
          ? sellerNameHint!.trim()
          : (listing['seller_name']?.toString().trim() ?? '');
      final sellerPhone = (sellerPhoneHint?.trim().isNotEmpty ?? false)
          ? sellerPhoneHint!.trim()
          : _categoryText(categoryData, const [
              'phone',
              'seller_phone',
              'contact_phone',
              'contact_number',
              'mobile',
              'whatsapp',
            ]);
      final sellerEmail = (sellerEmailHint?.trim().isNotEmpty ?? false)
          ? sellerEmailHint!.trim()
          : _categoryText(categoryData, const ['email', 'seller_email']);

      if (sellerPhone.isNotEmpty) {
        final cleaned = sellerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
        final digits = sellerPhone.replaceAll(RegExp(r'[^0-9]'), '');
        final candidates = <String>{
          sellerPhone,
          cleaned,
          digits,
          if (digits.isNotEmpty) '+$digits',
        }.where((e) => e.trim().isNotEmpty).toList();
        for (final phone in candidates) {
          final matches = await _client
              .from('profiles')
              .select('id')
              .or('phone.eq.$phone')
              .neq('id', currentUserId)
              .limit(2);
          final rows = (matches as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          if (rows.length == 1) {
            final id = rows.first['id']?.toString().trim() ?? '';
            if (id.isNotEmpty) return id;
          }
        }
      }

      if (sellerEmail.isNotEmpty) {
        final matches = await _client
            .from('profiles')
            .select('id')
            .ilike('email', sellerEmail)
            .neq('id', currentUserId)
            .limit(2);
        final rows = (matches as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        if (rows.length == 1) {
          final id = rows.first['id']?.toString().trim() ?? '';
          if (id.isNotEmpty) return id;
        }
      }

      if (sellerName.isNotEmpty) {
        final matches = await _client
            .from('profiles')
            .select('id')
            .ilike('name', '%$sellerName%')
            .neq('id', currentUserId)
            .limit(2);
        final rows = (matches as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        if (rows.length == 1) {
          final id = rows.first['id']?.toString().trim() ?? '';
          if (id.isNotEmpty) return id;
        }
      }
      final fallback = await _client
          .from('profiles')
          .select('id')
          .neq('id', currentUserId)
          .order('created_at', ascending: true)
          .limit(1);
      final fbRows = (fallback as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (fbRows.isNotEmpty) {
        final id = fbRows.first['id']?.toString().trim() ?? '';
        if (id.isNotEmpty) return id;
      }
    } catch (_) {}
    return '';
  }

  // ── Open / create chat ───────────────────────────────────────────────────────

  Future<String> openOrCreateChatForListing({
    required String listingId,
    required String sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerEmail,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Exception('Please sign in first.');
    final resolvedSellerId = await _resolveSellerIdForListing(
      listingId: listingId,
      incomingSellerId: sellerId,
      currentUserId: me,
      sellerNameHint: sellerName,
      sellerPhoneHint: sellerPhone,
      sellerEmailHint: sellerEmail,
    );
    if (resolvedSellerId.isEmpty) {
      throw Exception('Seller is unavailable for this listing.');
    }
    if (me == resolvedSellerId) {
      throw Exception('You cannot chat on your own listing.');
    }
    try {
      if (await _isBlockedBetween(me, resolvedSellerId)) {
        throw Exception('This user is blocked. Chat is disabled.');
      }
      final existing = await _client
          .from('chats')
          .select('id')
          .eq('listing_id', listingId)
          .eq('buyer_id', me)
          .eq('seller_id', resolvedSellerId)
          .maybeSingle();
      if (existing != null) {
        final id = existing['id']?.toString() ?? '';
        if (id.isNotEmpty) return id;
      }
      final now = DateTime.now().toUtc().toIso8601String();
      final inserted = await _client
          .from('chats')
          .insert({
            'listing_id': listingId,
            'buyer_id': me,
            'seller_id': resolvedSellerId,
            'last_message': '',
            'last_message_at': now,
          })
          .select('id')
          .single();
      final insertedId = inserted['id']?.toString() ?? '';
      if (insertedId.isEmpty) {
        throw Exception('Failed to open chat. Please try again.');
      }
      return insertedId;
    } catch (e) {
      throw Exception(_friendlyDbError(e));
    }
  }

  // ── Send text message ────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    await _guardBan();
    final me = _client.auth.currentUser!.id;
    await _guardChatBlock(chatId, me);
    final message = text.trim();
    if (message.isEmpty) return;
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': me,
        'text': message,
      });
      try {
        await _client.from('chats').update({
          'last_message': message,
          'last_message_at': now,
        }).eq('id', chatId);
      } on PostgrestException catch (e) {
        final dbMsg = e.message.toLowerCase();
        if (!dbMsg.contains('updated_at')) rethrow;
      }
    } catch (e) {
      throw Exception(_friendlyDbError(e));
    }
  }

  // ── Send image message ───────────────────────────────────────────────────────

  Future<void> sendImage({
    required String chatId,
    required XFile image,
  }) async {
    await _guardBan();
    final me = _client.auth.currentUser!.id;
    await _guardChatBlock(chatId, me);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last.toLowerCase();
      final path =
          'chat-images/$chatId/${DateTime.now().microsecondsSinceEpoch}.$ext';

      await _client.storage.from('chat-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: false, contentType: 'image/$ext'),
          );
      final url = _client.storage.from('chat-images').getPublicUrl(path);
      final now = DateTime.now().toUtc().toIso8601String();

      await _client.from('chat_messages').insert({
        'chat_id': chatId,
        'sender_id': me,
        'text': '',
        'image_url': url,
      });
      try {
        await _client.from('chats').update({
          'last_message': '📷 Photo',
          'last_message_at': now,
        }).eq('id', chatId);
      } on PostgrestException catch (_) {}
    } catch (e) {
      throw Exception(_friendlyDbError(e));
    }
  }

  // ── Mark chat as read ────────────────────────────────────────────────────────

  Future<void> markAsRead({
    required String chatId,
    required bool amIBuyer,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return;
    try {
      final col = amIBuyer ? 'buyer_last_read_at' : 'seller_last_read_at';
      await _client.from('chats').update({
        col: DateTime.now().toUtc().toIso8601String(),
      }).eq('id', chatId);
    } catch (_) {}
  }

  // ── Delete chat (user deletes their own) ─────────────────────────────────────

  Future<void> deleteChat(String chatId) async {
    try {
      await _client.from('chat_messages').delete().eq('chat_id', chatId);
      await _client.from('chats').delete().eq('id', chatId);
    } catch (e) {
      throw Exception(_friendlyDbError(e));
    }
  }

  Future<void> blockUser({
    required String blockedUserId,
    String? chatId,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Exception('Please sign in first.');
    if (blockedUserId.isEmpty) throw Exception('User is unavailable.');
    if (blockedUserId == me) throw Exception('You cannot block yourself.');

    try {
      await _client.from('blocked_users').upsert({
        'blocker_id': me,
        'blocked_id': blockedUserId,
      }, onConflict: 'blocker_id,blocked_id');
    } on PostgrestException catch (e) {
      if (e.code == '42P10' ||
          e.message.toLowerCase().contains('unique') ||
          e.message.toLowerCase().contains('constraint')) {
        try {
          await _client.from('blocked_users').insert({
            'blocker_id': me,
            'blocked_id': blockedUserId,
          });
          return;
        } on PostgrestException catch (insertError) {
          if (insertError.code == '23505') return;
          throw Exception(_friendlyDbError(insertError));
        }
      }
      throw Exception(_friendlyDbError(e));
    } catch (e) {
      throw Exception(_friendlyDbError(e));
    }
  }

  Future<void> unblockUser({
    required String blockedUserId,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Exception('Please sign in first.');
    if (blockedUserId.isEmpty) throw Exception('User is unavailable.');

    try {
      await _client
          .from('blocked_users')
          .delete()
          .eq('blocker_id', me)
          .eq('blocked_id', blockedUserId);
    } catch (e) {
      throw Exception(_friendlyDbError(e));
    }
  }

  // ── Save FCM token ───────────────────────────────────────────────────────────

  Future<void> saveFcmToken(String token) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return;
    try {
      final updated = await _client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', me)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        final user = _client.auth.currentUser;
        final displayName =
            (user?.userMetadata?['name']?.toString().trim().isNotEmpty ?? false)
                ? user!.userMetadata!['name'].toString().trim()
                : (user?.email?.split('@').first ?? 'User');
        await _client.from('profiles').upsert({
          'id': me,
          'name': displayName,
          'email': user?.email,
          'fcm_token': token,
        }, onConflict: 'id');
      }
    } catch (_) {}
  }
}

final chatActionsProvider = Provider<ChatActions>((ref) {
  return ChatActions(ref.read(_chatClientProvider));
});
