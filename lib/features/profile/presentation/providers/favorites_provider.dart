import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../listings/data/models/listing_model.dart';

final favoritesProvider = FutureProvider<List<ListingModel>>((ref) async {
  final me = Supabase.instance.client.auth.currentUser;
  if (me == null) return const <ListingModel>[];

  final response = await Supabase.instance.client
      .from('favorites')
      .select('listing_id')
      .eq('user_id', me.id);

  if (response.isEmpty) return const <ListingModel>[];

  final listingIds = (response as List<dynamic>)
      .map((e) => (e as Map<String, dynamic>)['listing_id'] as String)
      .toList();

  if (listingIds.isEmpty) {
    debugPrint('No favorite IDs found');
    return const <ListingModel>[];
  }

  debugPrint('Fetching ${listingIds.length} favorite listings');

  // Fetch listings by ID
  List<dynamic> listings = [];
  for (final id in listingIds) {
    try {
      final result =
          await Supabase.instance.client.from('listings').select().eq('id', id);
      if (result.isNotEmpty) {
        listings.addAll(result);
        debugPrint('Fetched listing: $id');
      } else {
        debugPrint('No listing found for ID: $id');
      }
    } catch (e) {
      debugPrint('Error fetching listing $id: $e');
    }
  }

  debugPrint('Total listings fetched: ${listings.length}');

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
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    debugPrint('🔄 Toggling favorite for listing: $listingId, user: ${me.id}');

    if (state.contains(listingId)) {
      debugPrint('➖ Removing favorite from DB');
      try {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', me.id)
            .eq('listing_id', listingId);
        state = {...state}..remove(listingId);
        debugPrint('✅ Favorite removed successfully');
      } catch (e, st) {
        debugPrint('❌ Error removing favorite: $e');
        debugPrint('Stack: $st');
      }
    } else {
      debugPrint('➕ Adding favorite to DB');
      try {
        final result = await Supabase.instance.client
            .from('favorites')
            .insert({'user_id': me.id, 'listing_id': listingId});
        debugPrint('✅ Insert successful: $result');
        state = {...state, listingId};
        debugPrint('✅ Favorite added successfully');
      } catch (e, st) {
        debugPrint('❌ Error adding favorite: $e');
        debugPrint('Stack: $st');
        return;
      }
    }

    debugPrint('🔄 Invalidating favoritesProvider');
    ref.invalidate(favoritesProvider);
  }

  Future<void> loadFavorites() async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) {
      state = {};
      return;
    }

    final response = await Supabase.instance.client
        .from('favorites')
        .select('listing_id')
        .eq('user_id', me.id);

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
