import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/app_auth.dart';
import '../../../listings/data/models/listing_model.dart';

final favoritesProvider = FutureProvider<List<ListingModel>>((ref) async {
  final userId = AppAuth.currentUserId;
  if (userId == null) return const <ListingModel>[];

  final response = await Supabase.instance.client
      .from('favorites')
      .select('listing_id')
      .eq('user_id', userId);

  if (response.isEmpty) return const <ListingModel>[];

  final listingIds = (response as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['listing_id'] as String)
      .toList();

  if (listingIds.isEmpty) {
    return const <ListingModel>[];
  }

  final listings = <dynamic>[];
  for (final id in listingIds) {
    try {
      final result =
          await Supabase.instance.client.from('listings').select().eq('id', id);
      if (result.isNotEmpty) {
        listings.addAll(result);
      }
    } catch (e) {
      debugPrint('Error fetching listing $id: $e');
    }
  }

  final items = <ListingModel>[];
  for (final row in listings) {
    try {
      items.add(ListingModel.fromMap(row as Map<String, dynamic>));
    } catch (e) {
      debugPrint('Error mapping favorite: $e');
    }
  }
  return items;
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  FavoritesNotifier(this.ref) : super({});

  Future<void> toggleFavorite(String listingId) async {
    final userId = AppAuth.currentUserId;
    if (userId == null) return;

    if (state.contains(listingId)) {
      try {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('listing_id', listingId);
        state = {...state}..remove(listingId);
      } catch (e, st) {
        debugPrint('Error removing favorite: $e');
        debugPrint('Stack: $st');
      }
    } else {
      try {
        await Supabase.instance.client
            .from('favorites')
            .insert({'user_id': userId, 'listing_id': listingId});
        state = {...state, listingId};
      } catch (e, st) {
        debugPrint('Error adding favorite: $e');
        debugPrint('Stack: $st');
        return;
      }
    }

    ref.invalidate(favoritesProvider);
  }

  Future<void> loadFavorites() async {
    final userId = AppAuth.currentUserId;
    if (userId == null) {
      state = {};
      return;
    }

    final response = await Supabase.instance.client
        .from('favorites')
        .select('listing_id')
        .eq('user_id', userId);

    final ids = (response as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['listing_id'] as String)
        .toSet();

    state = ids;
  }
}

final favoriteIdsProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final notifier = FavoritesNotifier(ref);
  notifier.loadFavorites();
  return notifier;
});
